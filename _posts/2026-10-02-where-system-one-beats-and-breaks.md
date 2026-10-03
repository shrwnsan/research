---
layout: post
title: "Where System One Beats and Breaks: Benchmarking a Decision Model Against LLM Scorers on Real Ground Truth"
date: 2026-10-02
slug: where-system-one-beats-and-breaks
excerpt: "System One models can't write text at all—they answer structured questions with choices, scores, and calibrated probabilities. We benchmarked one against the LLM scorer in a production research pipeline: 41% verdict agreement against a 58–69% floor the LLM columns hold among themselves, and a refusal on every row where the evidence was missing. The most interesting result of the benchmark is a refusal."
tags: [ai, llm-evaluation, benchmarking, methodology, reliability, case-study]
---

## TL;DR

There's a category of model that can't write text at all. "System One" models take structured input plus typed questions and return choices, scores, and calibrated probabilities (no prose, no reasoning trace, sub-second latency, near-zero cost). The pitch is that a large class of "AI features" are actually decisions, and decisions don't need a paragraph. They need an answer.

That pitch deserved a real test, and we had the ground truth to give it one. One of our production pipelines scores companies for a jobs product: a deep-research stage fetches everything public about a company, then an LLM rates the text across five dimensions (funding, growth, traction, market position, health) and rolls the scores into a verdict. It works. It also inherits every LLM vice: about fifteen seconds per company, run-to-run score variance, and one documented failure mode we'll come back to. When the research fetch comes back empty, the LLM happily scores the company anyway, from training-data memory.

So we pointed a System One model at the same job. Same 17 companies, same research text, same five-dimension rubric and composite weights, four scoring columns, two prompt modes.

The headline number is 41% verdict agreement between the decision model and the incumbent LLM. Read alone, that looks like failure. The context makes it interesting: the incumbent only agrees with the free-tier column it replaced 58% of the time, and with its own thinking-disabled variant 69% of the time. LLM scores on this task have real spread. And on the four companies where the research fetch returned zero bytes, every LLM column produced confident scores from memory—while the decision model returned near-zero scores and an evidence probability of 0.02–0.09. It declined to play.

**Key takeaway:** the decision model is not a drop-in replacement for the LLM scorer—and it shouldn't be. The same property that cost it the scoring job (it won't synthesize world knowledge) is exactly what makes it the right tool wherever the answer has to come from the provided evidence: gates, coverage checks, routing. Calibrated uncertainty is a feature you can build on.

## The question

A System One model is not a small LLM with a short system prompt. It doesn't generate text at all. You hand it structured state plus typed questions; it returns a choice or a score for each question, each with a probability attached. The vendor's framing is that a lot of what we call AI features are decision problems wearing a chatbot costume, and the model class is purpose-built for the decision underneath.

Our company-scoring pipeline is the counter-example that keeps the claim honest. The pipeline's value proposition is world knowledge: rate this company from everything public about it. The LLM column does that, and it does it well enough that the product ships. But it also exhibits the vices: 15 seconds per company, scores that wobble run to run, and—worst—the empty-fetch failure. A company whose research fetch returns nothing still gets a verdict, because the model answers from memory and has no mechanism to say *"I wasn't given anything."*

So the question wasn't really "is the decision model better?" It was: on a job whose product is world knowledge, what does a model that refuses to supply world knowledge actually do—and is the refusal useful anywhere?

## The setup

The population: 17 real companies that had landed in the pipeline's manual-review band: a mix of public giants, mid-stage startups, and thin-footprint companies. For each, the full research text the pipeline actually collects: careers pages, about pages, blog posts, data-vendor fragments, 0–9KB per company. Real inputs, not synthetic ones.

Four columns scored all 17 companies on the same rubric with the same composite weights:

- **The decision model, run twice.** One call per company: the research text as structured state, six questions in parallel—five score questions (one per dimension, five concrete levels each) and one calibration question: *"does this text contain sufficient concrete evidence to judge these dimensions at all?"* Once instructed to judge only the text, once allowed to add its own knowledge of the company.
- **The incumbent LLM scorer** (a flash-tier reasoning model with thinking on, in production today).
- **Its thinking-disabled twin** (same model, thinking off).
- **The free-tier model** the pipeline used before that.

## Results

| Column pair | Verdict agreement |
|---|---|
| Incumbent LLM vs the free-tier model it replaced | 58% |
| Incumbent LLM vs its thinking-disabled twin | 69% |
| Decision model (text-only) vs incumbent LLM | 41% |

Context for the 41%: the soft floor is soft. The incumbent disagrees with the free-tier column it replaced almost half the time, and with its own thinking-disabled variant nearly a third of the time. On the 13 companies with adequate research text, the decision model's dimension scores correlate only moderately with the LLM's (rank correlation 0.39). This is a genuinely different signal, not the same signal on a shifted scale.

We've argued before that [agreement measures conformity, not quality]({{ site.baseurl }}/does-the-ai-beat-free/)—and that cuts both ways here. Low agreement with the incumbent doesn't make the decision model wrong. But it also doesn't make it right. What makes the result interesting is where the disagreement concentrates, and that's the next section.

## The refusal

Four of the 17 companies were bot-blocked: the research fetch returned zero bytes. What did each column do with a company it had been given no evidence about?

| Scorer | Behavior on 0-byte evidence | Scores returned |
|---|---|---|
| Incumbent LLM | Scored from training-data memory, confidently | 65–75 / 100 |
| Free-tier LLM | Also scored; different numbers | 50–80 / 100 |
| Decision model | Declined to infer; near-zero scores, evidence probability ≤ 0.09 | 11–34 / 100 |

The LLM behavior isn't hypothetical. It produced real STRONG verdicts for companies about which the pipeline knew literally nothing from its own research. We found this failure the hard way and gated it with a crude rule: if the fetched text is under 400 characters, don't score.

The decision model's evidence question does the same job, graded instead of binary. Every starved row came back flagged (evidence probability 0.02–0.09), while rows with real signal sat at 0.20–0.47, tracking evidence density rather than byte count. A thin 482-character site scored all zeros with maximal confidence that there was no signal to find. That is the correct answer, and it's the [gates-before-reads instinct]({{ site.baseurl }}/free-models-mechanical-gate/) taken one step further: the cheap check doesn't just run first, it comes back with a probability you can threshold anywhere.

The most interesting result of the benchmark is a refusal. The System One model won't synthesize world knowledge—and the same property stops it from faking evidence. One constraint, two consequences: it can't replace the LLM where knowledge is the product, and it can't lie where evidence is missing. It's also the second time a System One model's refusal stole the show: in [our Jev field report]({{ site.baseurl }}/dont-ask-jev-what-your-tools-can-prove/), the model twice declined a provably safe branch over a stray draft file, and that refusal was the product.

## The split, in one row

Where did the 41% come apart? Our favorite row: a public, post-IPO company whose scraped text (careers page, product marketing, blog) never mentions funding. The LLM rated its funding signal 55/100, from world knowledge. The decision model, told to judge the text, rated it 4/100 at high confidence: no funding evidence present.

Both are being honest. They're answering different questions. That's the philosophical split of the whole benchmark in one row: the pipeline's value proposition is world knowledge, and the decision model won't supply it. Swap the job to one where the answer must come from the provided state (does this resume demonstrate this requirement, is this claim supported by this source) and the same refusal becomes the feature.

## Economics

| | Calls (17 companies) | Input tokens | Output tokens | Latency / call |
|---|---:|---:|---:|---:|
| Incumbent LLM (thinking) | 17 | ~8.4K | ~874/call | ~15s |
| Decision model | 17 | 39.4K | 0 (output free) | <1s |

The full decision-model run (all 17 companies, six questions each) consumed about 39K input tokens. At the list rate of $0.042 per million input tokens, that's $0.002 per complete run, roughly a tenth of a cent per company, with calibrated confidence attached to every answer. The LLM run costs pennies too at flash tier; token cost doesn't decide this. What changes the engineering picture is the shape: sub-second responses make scoring a synchronous, inline part of a request instead of a batch job, and parallel questions mean one round trip prices six judgments.

## Where it fits

The benchmark's practical yield is a boundary, not a verdict. The decision model earns its keep when the answer lives in the provided state:

- **Coverage matrices.** Requirement-by-requirement judgments ("does this resume demonstrate this job requirement?"), one calibrated probability each. Match-transparency UX generated natively, at a cost per pair measured in hundredths of a cent.
- **Gap-gated generation.** Let the decision model flag which items need writing, then spend LLM tokens only there. Generation stays System 2; triage becomes System 1.
- **Anti-fabrication gates.** "Is this new claim supported by the source text?" as a mechanical pre-check—the trust layer for any human-in-the-loop AI workflow.
- **Routing and selection.** Pick-from-N with confidence, benchmarkable against existing eval baselines on day one.
- **Evidence gates.** The graded replacement for brittle thresholds like "is the text long enough to score."

And it loses—by design—wherever the judgment needs knowledge the state doesn't contain: company quality, market strength, anything where the model would have to bring the world with it.

## Observations, not truths

This is one benchmark, one task family, 17 companies, and our ground truth. The LLM columns are strong flash-tier models, not frontier scorers; a frontier column might agree with its siblings more and raise the soft floor. And agreement was never correctness—we've made that argument about overlap elsewhere, and it applies with equal force to verdict agreement. The 41% is a starting conversation, not a finding.

What transfers more confidently than the agreement number is the refusal result. Given starved evidence, a model that answers only from provided state has nowhere to hallucinate from. That's structural, not tuned, and it showed up on every starved row we had. If your pipeline has a place where a confident wrong answer costs more than an admitted "insufficient evidence," that's the slot to try first.

## Replication sketch

Freeze the ground truth: same companies, same research text, same rubric, same composite weights across every column. The comparison is between scorers, not between pipelines.

Give the decision model an explicit evidence question alongside the score questions, and read its probability before you read the scores. It reorders the whole interpretation.

Include a starved-evidence stratum on purpose: bot-blocked rows are free if your fetcher has them. The interesting behavior lives there, not in the well-fed middle.

Compare the new column to the agreement floor among your existing LLM columns before comparing it to any single incumbent. A number below the floor means something different than a number above it.

Pin model versions. The entire run is 39K tokens, so repeating it after any bump costs a fraction of a cent; there's no excuse for stale results.

---

*This investigation was a collaboration between human curiosity and AI execution—the pipeline, the ground truth, and the skepticism were ours; the column runs, the agreement matrix, and the drafting were the machine's. The finding that survived review lost the job we benchmarked it for, and it's the most useful result the exercise has produced.*

*Method notes: single full-text run per company per mode · five-level score rubric with concrete level descriptions · composite weights held constant across columns · decision-model pricing at published list rate · all figures from the run logs of September 20, 2026.*

---

🤖 Co-Authored-By: [Claude Code](https://claude.com/product/claude-code) (GLM-5-Turbo)
