---
layout: post
title: "Evaluating the Unevaluable: A Method for Scoring Subjective AI Output"
date: 2026-07-23
slug: evaluating-the-unevaluable
excerpt: "When an AI system's job is editorial judgment—picking stories, ranking results, curating content—there's no ground truth to check against. No unit test can tell you whether today's newsletter was better than yesterday's. We ran into this problem hard while comparing two AI systems head-to-head, and the methodology we built to solve it turned out to be the interesting part."
tags: [ai, llm-evaluation, methodology, proxy-metrics, editorial, case-study]
---

## TL;DR

Evaluating AI output is easy when there's a right answer. Most real AI tasks don't have one. A code review has no canonical verdict. A news curation has no rubric. A summary is "good" in ways that resist binary judgment.

We built a methodology to score subjective AI output anyway: not by pretending objectivity exists, but by designing proxy metrics that are *independent of agreement between systems*. The key insight: **you don't need to know which answer is correct. You need to know which answer is *better*, along dimensions that don't require the systems to agree.**

We developed this to compare two AI newsletter editors over 14 days, but the approach generalizes. Here's the framework, the case study, and the honest limits of what proxy metrics can tell you.

**Key takeaway:** When there's no ground truth, the question isn't "how do I measure quality?"—it's "how do I design metrics that measure quality *without* requiring a reference answer?" The distinction is the whole ballgame.

---

## The problem no one talks about

Most AI evaluation discourse assumes a clean shape. A classifier has precision and recall. A translator has BLEU and METEOR. A code generator has pass rates on benchmark suites. These work because there's a *known answer*—a labeled dataset, a reference translation, a test suite that either passes or fails.

But a growing class of AI tasks sits in a murkier space. Call them *judgment tasks*:

- **Content curation**: pick the 7 most interesting stories from a feed
- **Code review**: identify risks in a pull request
- **Ranking**: order search results by relevance
- **Summarization with editorial voice**: distill a topic, not just compress it
- **Creative generation**: write copy, headlines, marketing hooks

In all of these, there's no ground truth. The "correct" set of seven stories doesn't exist. The "right" code review opinion is a matter of professional judgment. Two excellent systems can produce *entirely different outputs* and both be good at their jobs.

This isn't a theoretical problem. It's the problem we hit in the middle of a production decision.

## Where we hit the wall

In [our previous article]({{ site.baseurl }}/the-simplification-paradox/), we described comparing two AI systems that produce a daily newsletter, a multi-step agent and a single-prompt orchestrator. Both read from the same Hacker News pool and picked seven stories. We needed to know: *which one picks better?*

The obvious first attempt: **measure agreement.** Count how many of the same stories both systems picked. High overlap = they agree = they're probably both doing something right.

We almost went with that. Then we stopped, because it's wrong in a subtle way that matters.

## The agreement-vs-quality trap

Here's the trap. Agreement measures *overlap*, not *quality*. Two systems that both pick badly will agree enthusiastically. Two excellent systems that make *different* legitimate choices from the same material will disagree, and that disagreement is *editorial judgment doing its job*.

Think of two newspaper editors given the same wire feed. They'll both put the obvious front-page story—the big acquisition, the major outage—in slot one. That's consensus, and it carries almost no information. The interesting decisions are slots three through seven, and that's exactly where good editors diverge. One sees a regulatory shift; the other spots a quiet open-source release that presages a trend. Both picks might be brilliant. They won't overlap.

If you optimize for agreement, you're not measuring quality. You're measuring *conformity*. A system that reliably mimics the incumbent (including its blind spots) would score perfectly on agreement and mediocre on everything that matters.

This insight, that agreement and quality are orthogonal, is the foundation of everything that follows.

## The pivot: proxy metrics independent of agreement

If we can't measure quality by asking "did they agree?", what can we do?

The answer is: **measure downstream signals that correlate with quality, where each signal is computed *per system* and doesn't require the systems to agree on anything.**

You're not asking "did System A pick the same story as System B?" You're asking "did the stories System A picked *age well*?", independently of what System B did. If System A's picks consistently gain more traction over the course of a day, that's a signal about System A's judgment, regardless of whether System B agreed with any of its picks.

This is the core design principle: **each metric evaluates one system in isolation, and the comparison emerges from the *scores*, not from the *choices*.**

With this principle in hand, we built four metrics for the newsletter comparison. Each is a case study in proxy-metric design.

### Metric 1: Long-run story traction (the strongest signal)

**What it measures:** Did the editor pick stories that the community continued to engage with after publication?

**How it works:** When a story is picked at 08:00, it has some number of points on Hacker News. By evening, that story has either faded or surged. We fetch the updated scores and compute the delta: the change from pick-time to end-of-day.

**Why it's independent of agreement:** System A could pick seven stories that System B didn't touch, and if all seven of System A's picks gained 300 points while System B's picks were flat, the metric cleanly shows System A having better foresight. No overlap required.

**What it's really a proxy for:** Editorial foresight. The ability to spot stories with staying power, stories the crowd hasn't fully noticed yet but will. This is arguably the core skill of an editor, and the metric captures it without any reference answer.

**Limitations:** It assumes the Hacker News crowd is a reasonable proxy for "a story worth reading." A story that's *important* but *unpopular*—a niche regulatory filing, a quiet infrastructure change—would be undervalued. The metric rewards popularity dynamics, not importance per se. That's an honest trade-off, not a flaw.

### Metric 2: Engagement density (comments per point)

**What it measures:** Did the editor pick stories that generate *conversation*, not just upvotes?

**How it works:** At pick time, we compute the comments-to-points ratio for each story. A story with 300 points and 400 comments is generating real argument; one with 400 points and 30 comments is a crowd-pleaser nobody talks about. We average this ratio across the seven picks.

**Why it's independent of agreement:** Again, computed per system. One editor might pick discussion-heavy stories while the other picks link-bait. The metric scores them differently, no overlap needed.

**What it's really a proxy for:** Discussion-worthiness. For a newsletter meant to start conversations, we'd rather pick the story that generates argument than the one that accumulates silent clicks. The comments-per-point ratio is a rough but directionally correct signal for that.

**Limitations:** Comments aren't uniformly valuable. A flamewar inflates the ratio without adding insight. A deeply technical discussion with 15 comments from domain experts is worth more than 200 comments of hot takes. The metric doesn't distinguish. It counts. That's crude.

### Metric 3: Category diversity (topic spread)

**What it measures:** How many *distinct types* of stories appear in the seven picks?

**How it works:** Keyword classification sorts each story into a category: AI, tools, infrastructure, hard news, or other. We count how many unique categories appear. An editor who runs five AI stories scores lower than one who spreads across four categories.

**Why it's independent of agreement:** Two editors could pick completely different stories but both achieve high diversity. Or they could pick the same stories and both have poor diversity. The metric evaluates the *composition* of the set, not its *contents*.

**What it's really a proxy for:** Editorial breadth. A briefing that covers AI, infrastructure, regulation, and an open-source release gives readers a wider view of the landscape than one that runs five AI stories because that's what's trending. Diversity is a crude measure of "serving the whole reader, not just the trend."

**Limitations:** Keyword classification is lossy. A story about "AI infrastructure" could be classified as either AI or infrastructure depending on which keywords hit first. The categories themselves are somewhat arbitrary: why separate "tools" from "infrastructure" but not "AI regulation" from "regulation"? These are judgment calls embedded in the metric.

### Metric 4: Freshness (the sanity check that taught us something)

**What it measures:** What fraction of today's picks weren't in yesterday's edition?

**How it works:** Compare today's titles against yesterday's. Compute the percentage of new selections.

**Why it's independent of agreement:** Obviously, freshness is computed per system, and both systems share the same pool, so the freshness floor is set by the pool, not by agreement.

**What actually happened:** Both systems hit 100% freshness on all 14 days. The Hacker News front page turns over fast enough that rotation happens naturally. The metric produced *no signal whatsoever*.

**Why that's still valuable:** This is the part that surprised us. A metric that carries no discriminative signal can still be useful, as a *sanity check*. If either system had suddenly dropped to 40% freshness, that would have been a red flag: something is broken, even if the metric can't distinguish good from bad under normal conditions. The always-passing test isn't noise; it's a baseline. When it stays at 100%, you know the system is operating within normal parameters. When it drops, you know something changed before you even look at the picks.

This is a general principle worth stating plainly:

> **A metric that always passes is not useless. It's a sentinel. Its job is to fail, not to differentiate—and the day it fails, you're glad it was there.**

## The design framework

Stepping back from the specifics of the newsletter, what are the design principles that make these metrics work?

### 1. Independence from agreement

Each metric is computed per system, from external signals, with no reference to what the other system chose. This is the foundational principle. If a metric requires the systems to agree (or even to choose from the same options), it's measuring overlap, not quality.

### 2. Grounding in downstream outcomes

The metrics don't ask "is this pick good?" They ask "what happened to the pick *after* it was made?" Traction measured the community's subsequent validation. Engagement density measured the conversation that developed. These are *post-hoc* signals: the world responded to the choice, and we measured the response.

This is why the approach can work without ground truth: it substitutes *the world's response* for *the correct answer*. Neither is perfect, but the world's response has the advantage of being *real*, even when it's noisy.

### 3. Multiplicity of lenses

No single metric captures quality. Traction misses importance. Engagement density misses depth. Diversity misses focus. But taken together, a pattern emerges that no single metric could reveal. The orchestrator won on engagement density 10 out of 14 days and on diversity 8 out of 14, a consistent pattern across two independent lenses that both point the same direction. That consistency is more convincing than any single result.

This isn't a novel insight, it's the same logic behind using multiple evaluators in any assessment. But it's worth naming explicitly, because the temptation in metric design is to find *one perfect measure* rather than *several adequate ones*. Several adequate ones, converging, is more trustworthy.

### 4. Honest limitations, stated upfront

Every proxy metric has a failure mode. Traction rewards popularity. Engagement counts comments without judging quality. Diversity uses crude keyword classification. Freshness was a sentinel, not a differentiator. We stated these limitations because they matter, not as hedging, but as part of the methodology. A metric whose failure modes are understood is more useful than one whose failure modes are unknown.

## When This Generalizes (and When It Doesn't)

The framework, multiple proxy metrics, each independent of agreement, grounded in downstream outcomes, applies to a surprisingly wide class of problems. But not all of them.

**Where it works well:**

- **Ranking and selection tasks.** Any system that chooses from a bounded pool: content curation, search ranking, recommendation systems. The pool provides the options; downstream signals (clicks, engagement, retention) provide the ground-truth proxy.

- **Any task with observable downstream outcomes.** If you can measure what happened *after* the AI made its decision, you can build a proxy metric from that signal. Code review: did the reviewed code have fewer bugs in production? Summarization: did readers who saw the summary engage with the full article more often? These are tractable.

- **Comparative evaluation of two systems.** This is where the framework shines brightest. You don't need to know which system is "good"; you need to know which one is *better*, and multiple independent proxies pointing the same direction is a strong signal.

**Where it struggles:**

- **Tasks with no observable downstream signal.** Creative writing, brainstorming, exploratory analysis. If there's nothing to measure after the output is produced, the framework has no leverage. You're back to human evaluation, which is valid but not what this methodology addresses.

- **Tasks with very long feedback loops.** If the downstream signal takes months to materialize: hiring decisions, strategic planning—the framework becomes impractical for rapid iteration.

- **Tasks where the downstream signal is itself noisy or biased.** Social media engagement is a downstream signal, but it's also heavily influenced by algorithmic amplification, timing, and audience composition. The signal is real but contaminated.

- **Tasks where "better" is itself contested.** Two medical AI systems might recommend different treatment plans. "Downstream outcome" is patient recovery, real, but confounded by dozens of variables unrelated to the AI's judgment. Attributing recovery to the AI's recommendation specifically requires controlled trials, not post-hoc observation.

## The honest limits

We should be explicit about what this methodology is *not*.

It's not a replacement for human judgment. Proxy metrics are, by definition, *proxies*. They correlate with quality; they don't constitute quality. A system that optimizes for our engagement-density metric would learn to pick controversial stories, not important ones. Gaming the metric is always possible, and the better your metrics, the more subtly they can be gamed.

It's not universal. The framework requires a downstream signal, and not all tasks have one. Where there's no observable outcome, you need a different approach: human evaluators, paired comparisons, or acceptance criteria that are task-specific.

It's not statistically bulletproof with a 14-day sample. We noticed a pattern and took it seriously. We didn't prove a law. Extending this to a production-grade evaluation would require a larger sample, ideally stratified across different news cycles and seasons.

It's not objective. We chose the metrics. We chose the categories. We chose to weight traction highest and freshness lowest. A different evaluator, with different priorities, might design different metrics and reach a different conclusion. That's not a flaw; it's the nature of subjective evaluation. The best we can do is make our priors explicit and our methods transparent.

## What we learned that's bigger than the newsletter

The specific question, "is the orchestrator better than the agent?", resolved into a practical answer. The methodological question, "how do you evaluate judgment when there's no rubric?", is what's worth carrying forward.

Three ideas, stated as plainly as we can:

**First:** Agreement is not quality. The most seductive mistake in AI evaluation is confusing "both systems did the same thing" with "both systems did the right thing." Design your metrics so they never make this error.

**Second:** Downstream outcomes are the closest thing to ground truth that subjective tasks have. If you can observe what happened *after* the AI acted, you can build evaluation around that observation. It's noisy, biased, and incomplete, but it's real, and that's more than you'd have without it.

**Third:** Multiple weak proxies, converging, beat one strong proxy. No single metric captures editorial quality. But when four metrics—traction, engagement, diversity, freshness—all point the same direction, the signal is stronger than any individual metric could produce. This is the ensemble idea from machine learning, applied to evaluation design.

The scoreboard we built was a first pass. The framework is a start. The hard problem—how to rigorously evaluate AI systems whose output is judgment, not computation—remains open. But we've at least demonstrated that it's not intractable. You don't need a ground truth. You need good proxies, honestly bounded, independently computed.

That's enough to start making better decisions about which AI systems to trust. And in a world where more and more systems are making subjective calls—what to show you, how to summarize your email, which code review findings matter—knowing how to evaluate those calls without pretending they have a right answer is going to matter a lot.

---

*The scoreboard, the four metrics, and the 14-day comparison were built collaboratively between human editorial instinct and AI execution. The methodological framing, the distinction between agreement and quality, the design principles for proxy metrics, emerged from the work of doing it badly first, then noticing why.*

*The data (14 days of head-to-head comparisons) is real, not synthetic. The limitations are stated, not hidden. We think that's how methodology should work.*

---

🤖 Co-Authored-By: [Claude Code](https://claude.com/product/claude-code) (GLM-5-Turbo)
