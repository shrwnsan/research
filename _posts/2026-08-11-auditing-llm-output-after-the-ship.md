---
layout: post
title: "The Quality Gate That Killed Itself: Why We Audit Our LLM Pipeline After It Ships"
date: 2026-08-11
slug: auditing-llm-output-after-the-ship
excerpt: "Daily Sip, our multilingual Hacker News briefing, can pass every structural gate and still ship a confidently wrong summary—because the only unguarded surface is the free text itself. The obvious fix is a second LLM that checks each output before it sends. Here's why that gate was the wrong answer, what an adversarial review did to it, and the shape that actually worked: a decoupled audit that runs after delivery and can never block the send."
tags: [ai, llm-evaluation, methodology, reliability, observability, case-study]
---

## TL;DR

Daily Sip is a multilingual Hacker News briefing: every morning, an LLM picks seven stories, writes a short summary of each, translates them into six other languages, and ships the lot as text and audio. It had a validator that ran before every send. The validator was thorough about *shape*—right number of files, right date, audio under the length cap, the audio index matching the headline picks. It never once checked *truth*.

So we audited it. The output was around 95% factually accurate, which sounds great until you notice the qualifier: the errors it did make were not random. They clustered into a handful of repeatable failure modes, and the worst of them was a meaning-changing word swap on a sensitive policy story. Nothing was catching any of it.

The obvious fix was a gate: a second LLM reads each summary against its source and blocks the send on a contradiction. We designed that gate. Then an adversarial review killed it, for three reasons that all turned out to be correct. The shape that actually worked was the opposite of a gate: a check that runs *after* delivery, can never block or delay the send, and fails open.

This is the story of where the risk actually lived, why the gate was wrong, and the silent-failure coda that came right after.

## Where the risk lived

If you've followed the earlier posts, you know [Daily Sip](https://sipr.cc)'s history. We replaced a long-running AI agent with a single-prompt orchestrator and found the simpler system [editorially *better*]({{ site.baseurl }}/the-simplification-paradox/). We built a [scoreboard to measure that honestly]({{ site.baseurl }}/evaluating-the-unevaluable/). What we hadn't done was ask whether the prose itself was true.

Two parts of the output had structurally different risk profiles, and the audit made that obvious.

The **attribution** (the link under each story, the engagement counts) was correct by construction. A deterministic step overwrote those values with captured ground truth before render, every time. So attribution was never really an LLM output to audit. It was correct by design, on 100% of the editions checked.

The **summary text** was pure LLM output, grounded only on a truncated slice of the fetched article. That was the entire unguarded surface. Every factual error lived there.

This is the first generalizable lesson. When you audit an LLM pipeline, separate what's checkable by construction from what's free LLM output. The structural validator was doing real work, and its checks all passed, and none of them could have caught the defect class that actually mattered. "All gates green" told me nothing about whether the prose was true.

## The audit

For a week of editions we checked every summary against its original article at the level of individual factual atoms: each number, date, version, name, quote, and superlative claim, verdicted as supported, contradicted, or ungrounded. Around 158 atoms, roughly 95% supported, zero fabricated quotes.

The interesting part was the 5%. Every error fit one of seven patterns. A meaning-changing word swap on a sensitive story. An invented version number on a thin source. A founder's product pitch amplified past what the post actually claimed. A "most-discussed" superlative that was checkable against the pool and wrong. The model wasn't hallucinating at random. It was filling specifics the source lacked, and it was worst exactly where the source was thinnest (readmes, pitch posts) or where a comparative claim could be verified against the pool but wasn't.

A clustered, repeatable failure mode is good news. It means you can catalogue it, and in several cases catch it by construction.

## The gate that killed itself

So: a second LLM, before the send, reading each summary against its source, blocking on a contradiction. Clean idea. We ran an adversarial review across three lenses (reliability, over-engineering, correctness) and it dismantled the design.

**The judge was anti-correlated with the only days it mattered.** The judge came from the same provider as the generator—z.ai—which we'd already seen [degrade silently]({{ site.baseurl }}/when-compression-makes-your-context-bigger/) on a bad morning. On the exact outage days when degraded generation was most likely to emit garbage, the judge was either down or grading the degraded model with a sibling of itself. The safety net was absent precisely when it was needed.

**The verifier was itself unverified.** Nothing checked that the judge's cited evidence actually appeared in the article. A confident wrong *supported* would have laundered a defect straight through, failing at the one class the gate existed to catch. A different provider reduces this; it doesn't eliminate it.

**The blast radius was the whole pipeline.** Reusing the inference call in-process, between generation and the send, meant a malformed judge response could kill the edition *after* all the expensive generation was done. "Additive safety, never a dependency" was asserted in the design. It wasn't engineered.

The over-engineering lens had its own point, blunter: at this product's scale, an enterprise-grade judge with a shadow week and a frozen regression suite was apparatus out of proportion to the risk. The cost of the errors was real but small; the cost of a flaky gate blocking the daily send was larger.

## The shape that worked

The adversarial review pointed at a single redesign: **move the check after the send.** Run it in the post-delivery verify step, not before. That one change dissolved all three objections at once.

After delivery, the check can't block or delay anything, so blast radius disappears. It can fail open safely, because the edition has already shipped. It can re-fetch the *full* article rather than the truncated slice the generator saw, closing the context-window blind spot. And it can be made cross-provider later without touching the delivery path.

The severity model was the other finding worth naming. An explicit source *contradiction* is High (the embellishment class) and messages the owner. An atom the source doesn't mention is Medium, logged not alerted. And a citation that doesn't actually appear in the body is flagged but does *not* raise severity, because it's usually a citation-match artifact on an otherwise-clean atom, not a defect. Trusting the judge's verdict for severity, while distrusting its citation, was the calibration that kept false alarms near zero.

The deterministic layer came back too. The translation artifacts the audit found were root-caused to specific prompt lines (a redundant JSON-escaping workaround forcing the wrong quotation marks; a rule that conflated a written script with a spoken language), so the fixes were one-line prompt edits, now guarded by cheap deterministic detectors. The semantic judge is only asked to do what determinism can't.

## The silent-failure coda

The audit shipped, wired into the daily verify step, and then, for a day, it silently didn't run.

The reason was embarrassingly mundane. The pipeline runs its stage scripts from a deployed copy, not the repo. We'd merged the change and pulled, but the deployed copy was stale, so the new check step never executed. The delivery pipeline stayed green. Nothing errored. The check was simply absent, and the only signal was a trend log that never appeared.

This is the most generalizable failure of the whole arc, and it belongs to the same family as the rest. The pipeline didn't fail loudly. It got quiet. A check that exists in the repo but not in the running system is not a check. The fix was a checklist with one rule that should never have needed writing: for wrapper changes, merged is not the same as live. The lesson, again, was to make the failure visible by construction—a trend log whose absence is itself the alarm.

## Observations, not truths

We're not claiming a post-delivery audit is always the right shape, or that an in-pipeline gate is always wrong. The decision turned on specifics: a single-provider setup (z.ai on both sides) where judge and generator correlate, a product where the cost of a blocked send exceeds the cost of a wrong summary, and a scale where the apparatus of a real gate wasn't justified. Change any of those and the answer changes. That's why the gate wasn't deleted, it was deferred behind explicit signals (defect-rate drift, scale, a reader-reported error, a provider change) rather than a calendar.

What we are claiming: audit where the risk lives, not where the gates are. Let an adversarial review delete your first answer. And when you ship the fix, check that it's actually running.

---

🤖 Co-Authored-By: [Claude Code](https://claude.com/product/claude-code) (GLM-5.2)
