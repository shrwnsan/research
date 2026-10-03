---
layout: post
title: "Don't Ask Jev What Your Tools Can Prove: A TypeSafe AI Field Report"
date: 2026-09-21
slug: dont-ask-jev-what-your-tools-can-prove
excerpt: "We gave TypeSafe AI's new System One model the power to approve destructive git deletions. It scored 7/7 and still said no, twice, because we left a file named NOTES-draft.md in the worktree. Here's why that's the feature."
tags: [ai, llm, benchmarking, testing, llm-evaluation]
---

The most impressive thing TypeSafe AI's new model did all week was **refuse**. Twice—at 0.96 and 0.91 confidence—it looked at a git branch whose safety our own tooling had *mathematically proven*, and said: human, check the draft file first. A model being evaluated to guard `git branch -D` failing to approve a clean branch is either a bug or the entire product. We ran the numbers, benchmarked it against two chat LLMs, and concluded it's the product.

The model is **Jev**, TypeSafe AI's first "System One model." The pitch is a direct attack on how the rest of us use LLMs: *stop generating text altogether.* Instead of a chat model coerced into emitting JSON, you send state and typed questions (choose an option, score a rubric, is this true?), and you get back typed answers with **calibrated probabilities and confidence**, sampled in parallel, at 70–500ms, with output tokens free. No prose. By construction, no hallucinated tool calls.

The claims are bold: up to 194x faster and 445x cheaper than language models on their workflow evals. Bold claims from a vendor's own benchmark deserve the same treatment as any automation decision we'd hand to a model: **a labeled harness, a real workload, and a promotion gate.**

Conveniently, we had one waiting. A desktop daemon project needed a *pre-delete guard*: before a cleanup agent removes a git branch and its worktree, something has to decide whether that's safe. It's a genuinely fuzzy judgment, and destructive enough that being wrong costs real work.

So we ran a bake-off: Jev (direct), gpt-4o-mini (via Vercel AI Gateway), and GLM-5.3-flash (direct, reasoning off) against a seven-case labeled harness spanning two decision tasks.

## System One in sixty seconds

The Kahneman framing: System 2 is slow, deliberate reasoning (what chat LLMs do, one token at a time). System 1 is fast, intuitive pattern-matching (what Jev trains for, with what TypeSafe calls *Reinforcement Learning for Calibrated Decisions*). Concretely, three primitives:

- **Choice**: pick from options, get a distribution + confidence
- **Score**: rate state against a rubric, 0–2
- **Noul**: is this statement true? 0–1

All answered in parallel against the same state. Adding questions barely moves latency, because each is evaluated independently: no context rot. The output is a typed structure your code branches on. The catch: Jev *can't* write you a poem, summarize a PDF, or refactor your code. It is a function call, not a colleague.

Our verdict after a week: **that's not a limitation, it's the product**—and most teams haven't noticed that "AI judgment" tasks split cleanly into a provable part and a fuzzy part. More on that below, because it's where we went wrong first.

## The harness

Seven labeled cases across two decision tasks:

1. **PR auto-merge gate**: three real pull requests (two docs-only, one touching Swift sources). Should this merge without human review?
2. **Pre-delete guard**: four synthetic git branches with known answers. Fully merged (safe), unique unmerged commit (unsafe), **fully cherry-picked** (safe; the trap: raw signals scream "1 commit ahead," but `git cherry` proves patch-equivalence), and a diverged edit (unsafe).

Each case is a structured state (branch counts, cherry output, file lists, untracked filenames) plus atomic questions: a Choice gate, a Noul per sub-signal, a Score for loss severity. Results persist as JSONL, so the bake-off is one command to re-run after any model or price change.

## Result one: accuracy is commoditized

**21/21.** Every leg, every case, including the cherry-pick trap. If you're choosing a model for a decision task like this on accuracy, stop: the eval can't distinguish them, and honestly, on easy labeled sets, none of them will lose points.

Everything interesting lived in the *other* columns:

| | Jev (direct) | gpt-4o-mini (gateway) | GLM-5.3-flash (direct) |
|---|---|---|---|
| Median latency | **~850ms** | ~1900ms | ~1960ms |
| Cost per 1,000 gate decisions | **~$0.03** | ~$0.13 | ~$0.07 |
| Confidence on the trap | 0.57–0.61 | 1.00 | 1.00 |
| Confidence, clean cases | 0.96–1.00 | 1.00 | 0.96–1.00 |

## Result two: calibration honesty is a design choice

Watch what the decision model does on the ambiguous cases: the merged branch with a noisy worktree, the cherry-pick trap. It hedges: **confidence 0.27–0.61**, reproducibly (0.26/0.27/0.30 on the same case across runs *and machines*). The chat LLMs? **1.0. Unconditionally. Every time.**

Which is better? For a leaderboard, the 1.0s win. For a guardrail with a threshold, the hedge is the entire value: **mid-band confidence is a routing instruction.** `conf ≥ 0.8 → act, else → ask a human`. The model that says "0.57 and here's why I'm torn" hands you a policy. The model that says "1.0" hands you a coin it has already flipped.

On our real workload, the vendor's headline multipliers (194x faster, 445x cheaper) compressed to roughly **2–3x on latency** and a **4–5x cost advantage** ($0.03 vs $0.07–0.13 per 1,000 gate decisions). Different workload, tiny labeled set, single provider region: this is a directional measurement, not a benchmark. But the *shape* of the claims held: fast, cheap, and the confidence was informative rather than decorative.

*Cost basis: measured average tokens per call (7 cases) at OpenRouter list price as of 2026-09-21: gpt-4o-mini $0.15/$0.60 per MTok in/out, glm-5.3-flash $0.075/$0.25; Jev at TypeSafe's $0.042/MTok input with output free. Your account or route pricing may differ.*

## Result three: don't ask the model what git can prove

Our first guard draft let the model weigh in on the whole question, including git topology. Its verdict on the cherry-picked branch swung with how we phrased the state: `safe_delete` at 0.61, then `keep_review` at 0.91, then `keep_review` at 0.64. Same branch, same facts, three formulations. That's not a broken model; that's a model being asked to re-derive a conclusion that `git cherry` had already *proven*.

The fix wasn't prompt engineering. It was division of labor:

| Signal | Authority |
|---|---|
| Unique commits (`git cherry`), uncommitted changes | **Deterministic hard block**: the model can never override |
| Math-proven clean, clean worktree | **Deterministic allow**: no model call at all |
| Untracked content, submodule drift | **Model judgment**, threshold-gated |
| Model unavailable | **Fail closed**: decide manually, never guess |

The model's remaining job turned out to be small and genuinely fuzzy—and it was *good* at it. Presented with a worktree containing `buildcache.tmp`, `runner-output.bin`, and `NOTES-draft.md`, it scored the junk as ignorable, flagged the draft file as probable author work (`has_unique_work: 0.85`), and escalated at 0.96 confidence. Three filenames in, "one of these looks like author work, go look" out. That's the judgment no `git` flag makes.

## The failure we didn't plan to publish

While testing the guard's selftest, an agent run executed its synthetic git operations against the **real repository**: a defaulted `cwd` argument, invisible until a divergence warning appeared on `main`. Three empty commits, two junk branches, one very confused maintainer.

The postmortem produced our favorite line of code of the month: a *containment assertion*. Every selftest git operation now verifies `rev-parse --show-toplevel` resolves to the throwaway repo before it runs, or raises. The bug class didn't get fixed by being more careful; it got fixed by making the failure loud at the boundary.

If your agent runs state-changing commands "in a temp directory," audit that assumption today. Ours was wrong, and the proof is that we had a divergence warning to clean up.

## Early-adopter notes (the stuff between the docs lines)

- **Gateways don't carry evaluation models.** The AI Gateway's chat-completions route rejects Jev by design ("evaluation model, not a language model"). System One needs the evaluation API; talk to the provider directly.
- **Custom endpoints ignore `json_schema` response formats.** The prompted-JSON + client-side validation path is the portable one.
- **Copy-pasted env values carry ANSI escapes.** A model slug with an invisible bold code produces "Unknown Model" 400s that look like provider bugs. Strip escape codes from anything a human pasted.

## Disclosure

TypeSafe provided early access at no cost during the evaluation window; Vercel AI Gateway was free during the same period. Measurements are ours, from a seven-case harness on one workload: directional, not a benchmark. The harness, guard, and results ledger ship as two Python files plus a Jekyll post; we'd rather you rerun it than trust us.

## Open questions

- Thresholds encode values: a 0.8 cutoff escalated 1 of 7 cases to a human. What's the right escalation *rate* for a guard people will learn to start ignoring?
- Calibration stability held across runs and machines in our tiny sample. Does it survive a provider-side model update? (This is why the results persist as JSONL: re-running the bake-off is one command.)
- System One models force a question most teams skip: *which* of your "AI judgment" calls are actually provable by boring code? We suspect the answer is "most of them," and that the genuinely fuzzy remainder is where calibrated models belong.

We ran this as a bake-off *before* promotion, and the harness earned its keep twice: once by ranking the models, and once by telling us the promotion criteria were wrong. Both findings cost less than one bad auto-delete.

---

🤖 Co-Authored-By: Pi.dev Agent
