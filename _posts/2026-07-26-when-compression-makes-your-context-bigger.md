---
layout: post
title: "When Compression Makes Your Context Bigger: How an Agent Pipeline Fails Silently"
date: 2026-07-26
slug: when-compression-makes-your-context-bigger
excerpt: "On a bad provider day our daily AI newsletter didn't crash — it got quiet. Three independent failure modes cascaded from one degraded API: a context compressor that made the context *larger* on every pass, a provider that disguised truncation as a successful tool call, and a healthcheck that silently never ran because the agent wrapping it truncated first. The pipeline declared victory while delivering nothing. Here's what silent failure looks like — and why the fix was to make the failure impossible by construction."
tags: [ai, agentic-systems, llm, incident, observability, case-study, production]
---

## TL;DR

Daily Sip is a daily multilingual tech newsletter: every morning it reads the top 30 Hacker News stories, picks 7, summarizes them, and ships the result across seven languages as text and audio. Real readers, real inboxes, real consequences the morning it breaks.

One morning in late July 2026, it broke. And here's the unsettling part: **nothing threw an error.** Under provider degradation, three failure modes we'd never seen in isolation arrived together, and each one was invisible. The signature wasn't an exception. It was small outputs and confident-sounding status reports.

1. **A compressor that grew the context.** The agent's automatic context-compression — the safety net meant to *shrink* a too-large conversation — instead made it *larger* on every pass (~65K → ~73K tokens) without dropping a single message. It looped until the call budget ran out.
2. **Truncation disguised as success.** The provider rewrote `finish_reason='length'` (output truncated) as `'tool_calls'` (a normal tool call) — so our truncation handler, keyed on `'length'`, never fired.
3. **A healthcheck that never ran.** The Delivery Verification stage — a deterministic Python script — silently no-op'd because the *agent wrapper's own* LLM call truncated first. The pipeline reported green. The check had been skipped.

**Key takeaway:** Agent loops don't fail the way we instrument for them to fail. They fail by getting *small* — tiny outputs, chatty "looks fine" reports, a compressor that runs forever and calls it success. If you wait for an error, you'll miss the whole incident. The robust fix turned out not to be better error handling. It was removing the failure surface entirely: bounded single-turn calls that can't accumulate the context that breaks the compressor, and deterministic scripts that aren't gated behind an LLM.

---

## Some context, then the night it broke

In [our previous article]({{ site.baseurl }}/the-simplification-paradox/) we replaced [Daily Sip](https://sipr.cc)'s multi-step AI agent with a single-prompt orchestrator and found — to our surprise — that the simpler system was editorially *better*. In [the follow-up]({{ site.baseurl }}/evaluating-the-unevaluable/) we built the methodology to measure that honestly, because "editorial quality" has no ground truth.

One thread ran through both: a growing distrust of the long-running agent loop as a production dependency. It's stateful, opaque, and holds together beautifully until the morning it doesn't. This is the story of that morning.

## The night nothing failed loudly

The schedule is tight and coupled — generate the briefing, shorten the URLs, tag encores, deliver, then a verification pass — each stage a cron job that kicks off the next. On a healthy day it's boring on purpose.

That morning, the provider behind Stage 1 — z.ai — degraded. Connections stalled silently; some calls returned empty content. What followed:

| Elapsed | What happened |
|---------|---------------|
| Start | Stage 1 truncates. Retries cascade. |
| ~1 hour in | Stage 4 finds partial content but **fails URL validation on 49 raw, unshortened URLs** — shortening was skipped — and ships nothing. |
| ~2 hours in | A Stage 1 re-run enters a **degenerate compression loop**, producing tiny outputs on every API call. Its cleanup helper **wipes the day's output directory** to "start over." |
| same window | Delivery Verification runs and **fails with `Response truncated due to output length limit`** — the same truncation class. |
| same window | A *prior* session writes a handoff declaring the recovery **"complete."** It wasn't: the output dir was empty, nothing had been sent. The runaway session is still burning budget. |
| ~2½ hours in | The discrepancy is discovered. The only way to kill the runaway session is a **full container restart**. |

Manual recovery followed — regenerate via the standalone orchestrator on a healthy independent provider, re-shorten, deliver. 7/7 languages shipped, about three hours late.

Notice what's absent from that timeline: a crash, a stack trace, an alert. The system was *busy*. It was producing outputs. A prior run had even declared victory. Everything looked like work happening. It was work happening — just not the work that delivers a newsletter.

## Failure mode 1: the compressor that ran away

This is the one that still fascinates us — and the one we later understood better.

The agent's conversation context sat near the 64K threshold that triggers automatic compression. Compression is supposed to summarize the conversation down so the agent can keep going. Instead it looped: each pass, the token count climbed (~65K → ~73K), the message count didn't drop (`15 → 15`, `23 → 23`), and the system compressed again — until the 60-call budget ran out.

Our first read was that the summarizer was adding tokens. The deeper cause was more interesting, and more general: **the endpoint returned no real streaming token usage** (`awaiting_real_usage=true`), so the framework was steering its compressor off a climbing `rough_tokens` *estimate*, not a measurement. Each pass the estimate crept upward; the compressor kept firing on a number it had no way to verify. Some real growth may have contributed, but the dominant driver was estimate drift, not summarizer bloat. We've since moved the agent path to the provider's other endpoint, which returns real usage.

The hidden assumption here is almost universal, and it has two halves. Frameworks that auto-compress on a threshold assume compression is monotonic — that each pass reduces size — *and* they assume the size signal they compress against is accurate. A bad summarizer breaks the first half; a blind gauge breaks the second. Either way the feedback loop has no escape valve but the iteration budget. There's no "compression failed, give up" branch, because from the system's point of view compression didn't fail — it returned a context, dutifully, and steered off a number that was climbing for the wrong reason.

## Failure mode 2: truncation disguised as a tool call

The provider's API proxy did something we didn't know was possible: it rewrote `finish_reason='length'` — the standard signal that an output was truncated by the token limit — into `'tool_calls'`, the signal for a normal, completed tool call.

Our truncation handler keyed off `finish_reason='length'`. It had retries. It was the thing we trusted to catch exactly this scenario. It never fired, because from the handler's perspective nothing was wrong: the model made a tool call. The call just happened to contain a tiny, truncated, useless payload.

A secondary handler eventually noticed — via malformed JSON in the tool arguments — but historically hard-failed on that path. We'd added retries (a recent patch), and retries were necessary, but they weren't sufficient, because retrying against a degraded provider just produces more truncated outputs.

The general lesson is uncomfortable: **don't trust a single response field to classify failure.** Providers rewrite response shapes. Sometimes for good reasons (normalizing across models), sometimes not. A handler that branches on one field can be silently defeated the day the field's semantics shift under it.

## Failure mode 3: the deterministic stage that never ran

This is the one that should make anyone running an agent pipeline uncomfortable.

Daily Sip's Delivery Verification stage is a deterministic Python healthcheck. It reads files, checks markers, exits zero or non-zero. It needs no intelligence. But because it was wrapped in an agent-driven cron job — "run this script and report the output" — it depended on an LLM round-trip just to *start*.

> Delivery Verification failed with `Response truncated due to output length limit` — a deterministic healthcheck stage didn't run because the *agent's* call truncated.

The check we built to catch a broken pipeline was itself broken by the same degradation breaking the pipeline. And it failed quietly: a truncated response, a turn that ended early, no alert. Separately, the delivery stage "stopped after a 406-char response instead of completing — the agent produced a tiny response and ended the turn."

The principle, stated as plainly as we can:

> **Never gate a deterministic component behind a probabilistic one.** If the gate fails, the deterministic work silently doesn't happen — and the failure looks like success, because the gate returned *something*.

These stages didn't need an LLM. The agent loop could only hurt, never help, their reliability. Worse, the failures cascaded: the agent truncated → URL shortening was skipped → Stage 4 then failed validation on 49 raw URLs → nothing delivered. One silent failure became four.

## Why all three were invisible

Step back and the pattern is clear. The failure signature of a degrading agent loop is not an error. It is:

- **Tiny outputs** on each API call (a few hundred chars where there should be thousands).
- **A compressor that "succeeds"** — it returns a context, exactly as asked. The context is just bigger.
- **A chatty, ok-shaped report** — "I ran the check" — from a stage that did no such thing.
- **A prior session declaring victory** based on a partial, wrong reading of state.

Our alerting waited for non-zero exit codes and unhandled exceptions. We got neither. The system was loud with activity and silent on everything that mattered. The lesson we took: **instrument for output size and shape, not just for errors.** A 406-character "delivery report" is a red flag regardless of what it says. A compression pass that doesn't reduce message count is a red flag regardless of whether it returned. We'd built alarms that only fire when the system admits it's broken — and a degraded agent never admits it.

## The fix: make the failure impossible

We could have written better handlers. Another retry policy. A size-based sanity check on compressor output. All worth doing. But the move that actually worked was structural: **remove the failure surface entirely.**

Stage 1 now runs a standalone orchestrator that uses **bounded 8K-token single-turn JSON calls with no conversation accumulation.** Each call is small, stateless, and returns structured output that Python validates. There is no 65K-token conversation to compress, so there is no compression loop to go degenerate. A single bounded call can't mask truncation the way a sixty-message loop can, because there's no loop. The orchestrator literally cannot hit either of the first two failure modes — not because we handle them, but because the architecture that produces them is gone.

And the deterministic stages — shortening, encore tagging, delivery, verification — no longer pass through an LLM at all. They run their scripts directly; the exit code drives alerting. No probabilistic gate in front of deterministic work. If the healthcheck's script fails, the exit code is non-zero, and the alert fires. The failure mode where "the check silently didn't run" can't arise, because there's no agent call to truncate.

This is the move we keep arriving at, and it's worth naming: **prefer architectures where the failure cannot arise over better handlers for when it does.** Error handling is for failures you can't prevent. Compression loops and silent no-ops, it turns out, you can prevent — by not building the shape that produces them.

## What we're not claiming

This matters, because incident writeups have a way of overreaching.

This isn't a verdict on z.ai. It's one of our most-used providers; the post-mortem is about a single degraded day, and about one endpoint's telemetry making a bad day worse. We're also not claiming agents are bad. We *are* claiming that for this pipeline — bounded inputs, deterministic post-processing, a job that has to ship every morning — the agent loop's signature strengths (deciding what to inspect, recovering from surprise) were exactly the surface area that failed.

We are **not** claiming the orchestrator is free. It trades adaptivity for reliability. For tasks that genuinely require exploration — debugging an unfamiliar system, open-ended research — the agent loop is the right tool, and the failures above are the price of its power. Daily Sip is not that task. Its context is bounded and known; its downstream stages are deterministic. It's a job for a decisive judge with blinders on, not an explorer with a notebook. ([We've made this argument before]({{ site.baseurl }}/the-simplification-paradox/); this is what it looks like when the agent's fragility, not just its quality, finally bites.)

And we are **not** claiming we "solved" silent failure. We removed *this* failure surface for *this* pipeline. The broader problem — that LLM systems degrade by getting small and confident rather than by throwing errors — is unsolved in general. We just made our one corner of it impossible to reach.

## The bigger lesson

This isn't the first time silent failure was the real story. In [a different project's tiered model-selection pipeline]({{ site.baseurl }}/tiered-model-selection-in-practice/), a CI race condition and a `paths-ignore` contradiction taught us that the best model doesn't help if the workflow that invokes it never runs. This incident is the same lesson, louder: the failure wasn't in the model, it was in the loop around it.

If you run an agent loop in production, the questions that matter aren't the ones we asked first ("what does it do when the API errors?"). They're the ones this incident forced: *What does it do when the API returns tiny, well-formed garbage? What does the compressor do when it can't compress — and does anything notice? Which of my deterministic checks are secretly gated behind an LLM call?*

Detect output size, not just errors. Put hard bounds on every loop. Never let an LLM gate a deterministic check. And when you find a failure mode that no handler can truly catch, don't write the handler — delete the shape that makes it possible.

The morning our newsletter didn't crash, it didn't deliver. That's the failure mode to design against.

---

*This incident and its migration were worked through collaboratively between human diagnosis and AI execution — the timeline reconstruction, the root-cause isolation of the three failure modes, and the architectural fix. The instinct to make the failure impossible rather than merely handled was the part that mattered most, and it was ours to insist on.*

*The incident is real, documented in full in the project's postmortem, and the migration has run cleanly every night since. We think that's how incident writeups should work: failures named, not hidden.*

---

🤖 Co-Authored-By: [Claude Code](https://claude.com/product/claude-code) (GLM-5.2)
