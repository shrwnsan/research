---
layout: post
title: "Does the AI Beat Free?: What 44 Days of LLM-vs-Sort A/B Actually Showed"
date: 2026-07-29
slug: does-the-ai-beat-free
excerpt: "We proved our AI curator beats the complex agent. Then we asked the scarier question: does it beat *no* AI at all—a free score-sort? Forty-four days of head-to-head A/B say, by our own quality metrics, barely. The case for the LLM isn't measurable selection quality. It's elsewhere."
tags: [ai, llm-evaluation, methodology, editorial, case-study, production]
---

## TL;DR

Every morning Daily Sip picks 7 stories from the Hacker News top 30 and writes them up across seven languages. In [The Simplification Paradox]({{ site.baseurl }}/the-simplification-paradox/) we replaced a multi-step agent with a single-prompt LLM and found the simpler system editorially *better*. In [Evaluating the Unevaluable]({{ site.baseurl }}/evaluating-the-unevaluable/) we built the metrics to measure that honestly.

This post asks the question those two raised but never answered: **does the LLM beat *no AI at all*?**

The baseline is the dumbest thing that could work: sort the 30-story pool by points, take the top 7. Zero intelligence, zero cost. If that's basically as good as the LLM, then the LLM is an expensive way to reproduce a sort.

Forty-four days of A/B later, the honest answer is uncomfortable. The LLM overlaps a free sort 80% of the time. And by our *own* quality metrics—the ones we used to crown the orchestrator—it beats the sort on engagement density 22 of 44 days, ties 14, loses 8. On category diversity: 8 wins, 32 ties, 4 losses. That is a coin flip.

**Key takeaway:** For selecting from a bounded pool, an LLM's measurable quality edge over a zero-cost sort is near zero. That doesn't make the LLM worthless; it relocates where its value actually lives. Test your expensive model against a free baseline early; the result tells you what your model is really for.

---

## The question we were scared to ask

[Daily Sip](https://sipr.cc) had, until recently, been a running argument *for* the LLM. We stripped out the multi-step agent and showed the single-prompt LLM was a *better* editor: less drift, sharper picks, more reliable. The LLM had earned a heroic role in the story. It was the judge.

But that whole fight had been LLM-versus-LLM. The agent and the orchestrator both had a brain. The comparison we'd quietly avoided was the embarrassing one: **brain versus no brain.** Sort the pool by score. Take the top seven. Don't ask anyone anything.

If the LLM curator is genuinely adding editorial value, it should beat a leaderboard. If it's mostly rubber-stamping popularity, it won't. We assumed it would win, clearly. We ran the comparison for forty-four consecutive days to find out.

## What overlap showed—and why it wasn't the answer

The first number looked damning. Over 44 days, the LLM's picks overlapped the free sort's picks **80.4%** of the time (median 85.7%). Four of every five stories, on average, the LLM and the sort agreed.

The tempting conclusion—*"so the LLM is just a sort with extra steps"*—is exactly the one we've learned not to draw. We [wrote a whole post]({{ site.baseurl }}/evaluating-the-unevaluable/) on why agreement is not quality. Two systems that pick badly agree enthusiastically; two brilliant editors disagree legitimately. Overlap measures *conformity*, not value. So 80% agreement tells us the LLM usually follows the leaderboard; it doesn't tell us whether the times it *doesn't* are better or worse.

Overlap isn't constant, either. It collapses on specific days. The correlation between the front page's "points gap" (how dominant the #1 story is) and the overlap is a real **−0.51**: when the page is tight (gap under 3×), overlap sits at 86%; when one story runs away with it (gap of 5× or more), overlap drops to 70%. On those dominant-#1 days the LLM reaches deeper into the pool (average rank 13, as deep as 17), pulling up stories the sort structurally cannot surface.

Two honest caveats on that pattern. First, it's a **step function at the 5× gap, not smooth scaling**: overlap is flat (~86%) right up until one story dominates, then breaks. Second, it's not airtight: **two of the ten most divergent days were tight-cluster days** where the LLM strayed from the sort for reasons we can't fully explain. The "diverges on dominant-#1 days" story holds about 80% of the time, not 100%.

So overlap says: they agree mostly, diverge selectively. Still not a quality answer. For that we had to do what our methodology post prescribed: stop measuring *agreement* and start measuring *downstream signals*, per system, independently.

## The quality answer: barely

Same 44 days, same pool, but scored on the metrics we'd built to judge editors:

| Metric (LLM vs free sort, n=44) | LLM wins | ties | losses | mean Δ |
|---|---|---|---|---|
| Engagement density | **22** | 14 | 8 | +0.024 |
| Category diversity | **8** | 32 | 4 | +0.14 |

By the very metrics we used to declare the orchestrator the winner over the agent, the LLM is a coin flip against a free sort. The engagement-density line (22 wins to 8 losses) sounds respectable until you notice the 14 ties and that the average advantage is **+0.024**, which is noise-adjacent. Diversity is a dead heat: on 32 of 44 days they pick the same number of categories.

And those deep, divergent picks on dominant-#1 days (the LLM's most distinctive behavior)? On the ten most divergent days, the LLM wins engagement **six times and loses four**. Different, yes. Measurably better, no. This is the agreement-versus-quality trap from our methodology post, biting our own data: we'd been measuring how often the LLM *disagreed* with a sort, and quietly assuming disagreement meant it was doing something valuable. It doesn't. It just means it picked something else.

This wasn't the result we expected. We'd cast the LLM as the better judge. The data says: for *selection*, it's barely a better judge than a leaderboard.

## So why is the LLM still there?

Because "barely beats a sort on selection" is not "useless," and the honest case for keeping it doesn't rest on selection quality at all.

First, **there's no case to replace it either.** A coin flip isn't a loss; the LLM is no worse than the sort, so "fire the model" isn't justified by this data any more than "the model is essential" is.

Second, **selection is free-riding on work the LLM is already doing.** The model is in the loop to write summaries and translate the briefing into seven languages. Picking the seven stories is one sub-decision it makes with context it already has. A score-sort would replace the selection step, not the model. The expensive part stays either way.

Third, **editorial range has value we can't measure but won't dismiss.** On dominant-#1 days the LLM surfaces stories the leaderboard can't reach. We couldn't prove those picks are *better* on same-day engagement. But they're *different*, and a newsletter that occasionally surprises its readers, that reaches past the obvious front page, may be doing something for long-term reader value that a 24-hour engagement metric can't see. We suspect. We don't know. We're honest about the gap.

The experiment answered its question. *Could we go deterministic on selection?* No clear case to. No clear case not to. The LLM stays, but we now know exactly how little of its value lives in the selection step.

## What we're not claiming

This matters, because "the AI barely beats free" is the kind of line that gets over-read.

We're looking at **44 days, one domain (Hacker News), one newsletter**, across a model swap mid-experiment (the pattern held on both sides of it, which is reassuring, but it's still one domain). It's a pattern, not a law.

"Barely beats" is not "useless" and not "worthless." It means the *measurable* quality delta on selection is near zero, and that the model's value is elsewhere: in the summaries, the voice, the range of what it surfaces. The selection step turned out to be the part that *looked* like intelligence and behaved like a sort.

Our metrics are proxies with known blind spots (we listed them in the methodology post). A story that's important but unpopular is undervalued by every one of them—by the sort *and* by our quality scores. And we did not test whether the divergent "rising" picks create long-term reader value (retention, click-through). That's a harder experiment we haven't run. The deep picks *might* be the LLM's real contribution; we just can't see it through a same-day engagement lens.

## The bigger lesson

For any ranking or selection task, run your expensive model against a free baseline early. We put it off because we assumed we knew the answer. The actual result—*barely different*—is one of the most useful things a team can learn, because it relocates the question. It stops you optimizing the selection step and sends you to where the model genuinely earns its keep: the parts you can't trivially replace with a sort.

This fits a shape we keep finding. *The Simplification Paradox* showed a simpler LLM beating a complex agent. This shows an LLM barely beating *no* model for selection. (We've separately found that *which* model you pick barely moves the picks either, but that's its own post.) The recurring lesson: a lot of presumed "AI value" in a pipeline hides in the steps you'd never think to question, not the ones you agonize over. The selection step *looked* like the intelligence. It was a leaderboard.

A free baseline is the cheapest experiment you'll ever run, and it has a useful property either way: it wins, and you delete a dependency and a cost—or it loses, and you finally learn what your model is actually for.

---

*This investigation was a collaboration between human curiosity and AI execution: the A/B harness, the statistical work, and especially the willingness to publish an answer that contradicted our own prior framing. The instinct to ask "does it beat *nothing*?" was the part that mattered most, and it was ours to ask.*

*The data is real: 44 days of head-to-head comparisons, logged daily, recomputed here from the raw record. The uncomfortable answer is stated, not softened. We think that's how this kind of question should be answered.*

---

🤖 Co-Authored-By: [Claude Code](https://claude.com/product/claude-code) (GLM-5.2)
