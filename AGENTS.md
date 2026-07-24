# Writing & Editorial Conventions

This file provides instructions for AI agents contributing content to this research blog.

## Approach

This blog documents **agentic augmentation** — what happens when AI moves from tool to collaborative partner in research. Every post is a dialogue between human curiosity and AI execution.

When writing, follow the research process:
1. **Start from a real question**, not a predetermined conclusion
2. **Follow the evidence** even if it undermines the premise
3. **State limitations honestly** — methodology failures and unexpected outcomes are content, not embarrassments
4. **Present findings as observations**, not absolute truths. Leave room for interpretation

## Voice & Style

- **Smart Casual Socratic**: authoritative yet approachable, curiosity-led
- Ask interesting questions, then follow the evidence wherever it leads
- Findings are observations, not absolute truths. Document failures alongside successes
- AI contributions are acknowledged, not hidden

## Punctuation

- **Em-dashes are unspaced**: `word—word`, never `word — word`
- **Reserve em-dashes for emphasis**: dramatic pivots, emphasized appositives, and pull
  quotes. For everything else, prefer:
  - **Colons** for term-definition and explanation (`X: definition`)
  - **Commas** for gentle asides and continuations
  - **Parentheses** for true parentheticals
  - **Semicolons** for related independent clauses
  - **Periods** to separate distinct thoughts
- When in doubt, use a lighter mark. An article with 15 well-placed em-dashes
  outperforms one with 40.

## Post Structure

Every post lives in `_posts/` as `YYYY-MM-DD-slug.md` with this front matter:

```yaml
---
layout: post
title: "Post Title Here"
date: YYYY-MM-DD
slug: post-slug
excerpt: "A 1-2 sentence summary that works standalone."
tags: [tag1, tag2, tag3]
---
```

## Attribution

End every post with the co-authorship line:

```markdown
🤖 Co-Authored-By: [Claude Code](https://claude.com/product/claude-code) (Model-Name)
```

Replace `Model-Name` with the actual model used (e.g., GLM-5-Turbo, Claude Sonnet 5).
