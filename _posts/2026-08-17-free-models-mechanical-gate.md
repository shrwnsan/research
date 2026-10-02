---
layout: post
title: "Mechanical Gates Before Human Reads: Benchmarking 8 Free LLM Endpoints for a Production Translation Job"
date: 2026-08-17
slug: free-models-mechanical-gate
excerpt: "Free model endpoints are tempting for production jobs—until you notice that most evaluations jump straight to human quality reads. Before spending a single human hour, run the cheap filters: does the model honor the JSON contract, does it drop items, what does its latency distribution look like at the p95, and what class of failure does it produce when it fails? Eight free endpoints, 336 production-shaped calls, four survivors, zero human reading hours wasted."
tags: [ai, llm-evaluation, free-models, benchmarking, methodology, reliability]
---

## TL;DR

A production pipeline we operate translates a daily briefing into six languages: six serialized LLM calls, each of which must return strict JSON with exactly seven story entries. Free model endpoints look like an obvious way to make that step cost nothing. Before letting any human (including us) judge translation quality, we ran every candidate through four mechanical gates: contract adherence, item-count drift, latency distribution, and failure-mode class. Of eight free endpoints, four were disqualified without a single human read: one for returning a top-level JSON array instead of an object, one for silently dropping 89% of the stories, one for a 24-minute serialized step, one for burning 4–6× the incumbent's tokens per call. The survivors earned the expensive thing: blind human reads.

## The job shapes the benchmark

Most model evaluations benchmark the model. It's better to benchmark the *job*. Ours has properties that don't appear in generic leaderboards:

- **A strict JSON contract.** The prompt asks for a JSON object with a `stories` array; downstream code parses it or fails. Models don't just need to translate; they need to not break the envelope.
- **An exact item count.** Seven stories in, seven stories out. Silent drops are worse than loud errors, because a dropped story means a missing briefing section in that language.
- **Serialization.** Six calls run back-to-back (the incumbent provider rate-limits to one concurrent request, and the bench inherited that shape deliberately). At six sequential calls, a model's *median* latency matters less than its p95: tails compound.
- **Unattended execution.** It runs at 08:05 in the morning. Nobody is watching. A failure mode that requires a human to notice is a failure mode that ships.

So the harness replays the *exact production prompt* (same system message, temperature, max tokens, JSON mode) against archived real inputs. Not a synthetic task: the actual payloads the incumbent has been translating for months.

## The four gates

1. **Contract adherence.** Did the call return parseable JSON in the agreed shape? A top-level array instead of an object is a contract violation even though it's "valid JSON."
2. **Item-count fidelity.** Exactly seven stories, every time. This single gate killed one model outright (11% of its successful calls contained all seven) and flagged another at 85%.
3. **Latency distribution.** Median and p95 across days. One model with an excellent median (and famous lineage) carried a p95 of 419 seconds; at six serialized calls, that's a step that can eat half an hour.
4. **Failure-mode class.** When the call failed, *how* did it fail? This is the gate nobody runs and the one that changed our architecture thinking (below).

## Results

Eight free endpoints, seven archived days, six languages each: 336 calls, roughly a third of one day's free-tier request budget:

| Endpoint | Contract OK / 7-of-7 | Median | p95 | Out-tokens | Verdict |
|---|---|---|---|---|---|
| gemma-4-26b-a4b | 100% / 98% | 41s | 187s | 1.5K | survivor |
| gemma-4-31b-it | 91% / 100% | 41s | 55s | 1.4K | survivor |
| nemotron-nano-9b | 98% / 100% | 75s | 125s | 2.9K | survivor |
| A 550B MoE | 95% / 100% | 98s | 148s | 3.2K | borderline |
| gpt-oss-20b | 98% / 95% | 242s | 419s | 4.7K | DQ: latency |
| A 120B Nemotron | 95% / 85% | 100s | 211s | 6.7K | DQ: burn + drift |
| A 30B Nemotron | 90% / 11% | 50s | — | 6.4K | DQ: drops stories |
| A 2.6B edge model | 88% / 32% | 241s | — | 4.1K | DQ: too small |

The incumbent (a budget-tier paid API at fractions of a cent per run) does the full six-language step in ~110–170 seconds with, across months of production days, effectively zero contract failures at ~19 seconds per call. Even the best free survivor is 1.5–2× slower for the step and fails 5–9% of the time. That reframed the whole question.

## What the failure-mode gate taught us

The fastest survivor (best median, tightest p95) fails 9% of the time, and its failure mode is the *empty response*: an HTTP 200 whose content is empty or null. If you've built failover chains, you know this is the failure mode that quietly defeats them: an empty response parses as "success" at the transport layer, blows up at the JSON layer, gets classified as a parse error, and your retry logic diligently re-asks the dead provider three times while your circuit breaker (which counts transport failures) never trips. We had just shipped exactly that fix for a paid provider's outage, so recognizing the same signature in a free endpoint was easy. The general lesson: **classify failures before you architect retries, and test candidates' failure modes, not just their successes.**

Two more evergreen findings:

- **Three free legs are not three legs.** Free-tier rate limits and routing are per-account, and the endpoints share an ecosystem's bad hours. Counting three free models as independent redundancy is counting one failure domain three times. One free leg (with alternatives documented for incident-time swaps) is the honest configuration.
- **Free model IDs churn fast.** The model names in articles we'd read weeks earlier 404'd by the time of this benchmark; the generation had turned over. Whatever you pin, pin it behind an alias, and re-scan the catalog on a schedule.

## Why gates before reads

Human judgment is the scarce resource in any evaluation. A blind read of four models across six languages and multiple days is hours of careful work, and it's the *only* way to judge register, nuance, and the difference between "correct" and "reads like a native speaker wrote it." Spending that on a model that drops a third of your items is waste. The gates cost nothing (these calls were free by definition) and eliminated half the field, including famous names, before a single human minute.

The surviving quartet goes to blind reads next: same source text, shuffled model labels, consistent letters across sections, the key file opened only after the verdict. The gate languages go first: in our case, the one language where vernacular authenticity is hardest to fake.

And the endpoint verdict worth stating plainly: **free endpoints lost the primary slot on mechanics, not price.** They may still win a last-resort slot in the failover chain—zero-cost insurance against the day both paid providers are down, which is a different question with different gates.

## Replication sketch

If you're evaluating free (or cheap) endpoints for a production LLM step: replay your real prompt against your real archived inputs; record latency, token counts, JSON validity, item counts, and the raw failure text; run at least a week of daily calls to catch the free tier's bad hours; and only then package the survivors for blind human reads. The whole mechanical harness was ~150 lines of Python and 336 free API calls. The expensive part of your evaluation should be the part only humans can do—and it should be the only expensive part.

---

🤖 Co-Authored-By: [Claude Code](https://claude.com/product/claude-code) (GLM-5.2)
