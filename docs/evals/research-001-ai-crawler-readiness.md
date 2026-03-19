# Research: AI Crawler Readiness for Jekyll Blogs

**Date:** 2026-03-18
**Status:** Complete
**Context:** Making this research blog AI/LLM crawler-ready on GitHub Pages

## Summary

This research evaluates modern best practices (past 2-3 months) for making websites discoverable and consumable by AI crawlers and agents, with specific focus on Jekyll blogs hosted on GitHub Pages.

## The Problem

- Traditional SEO (robots.txt, sitemap.xml) serves search engines, not AI agents
- AI crawlers benefit from structured markdown content, not just rendered HTML
- Blog has source markdown files but doesn't expose them for AI consumption
- GitHub Pages constraints: only whitelisted Jekyll plugins supported

## The Emerging Standard: llms.txt

### What is llms.txt?

A proposed standard at `/llms.txt` — analogous to `robots.txt` but specifically designed for AI/LLM crawlers. It provides a markdown-formatted index of content optimized for AI context windows.

### Key Resources

- **Specification:** https://llmstxt.org
- **GitHub Repository:** https://github.com/AnswerDotAI/llms-txt
- **Adopter Directory:** https://llmstxt.site

### Notable Adopters

- Anthropic (https://anthropic.com/llms.txt)
- Stripe (https://stripe.com/llms.txt)
- Cloudflare (https://cloudflare.com/llms.txt)
- Next.js
- Astro

### Format Structure

```markdown
# Site Name

> Brief summary of what the site offers (blockquote)

## Section Name (optional, H2)
- [Resource Title](/path/to/resource): Brief description
- [Another Resource](/path): Description

## Another Section
- [Item](/path): Description
```

**Key elements:**
- H1 title (site name)
- Blockquote summary
- Optional sections with H2 headers
- Markdown link lists with descriptions

### Two-File Approach

1. **`/llms.txt`** — Concise index with links (discovery layer)
2. **`/llms-full.txt`** — Full content in single markdown file (context layer)

This allows AI agents to:
- Quickly discover available content via `llms.txt`
- Fetch complete context in one request via `llms-full.txt`

## Current Blog State

### Existing Setup

- **Platform:** Jekyll on GitHub Pages
- **URL:** https://shrwnsan.github.io/research/
- **Posts:** 7 articles in `_posts/` directory (markdown source)
- **Plugins:** jekyll-feed, jekyll-sitemap, jekyll-seo-tag (whitelisted)
- **Build:** kramdown markdown, rouge highlighter

### Current Crawler Support

From `robots.txt`:
- Traditional SEO-focused rules
- Allows Googlebot, Bingbot, Twitterbot, LinkedInBot, facebookexternalhit
- Blocks AhrefsBot, MJ12bot
- References sitemap.xml

**Gap:** No AI-specific crawler accommodations

## Implementation Approaches

### Approach 1: Manual Static Files (Recommended)

Create `llms.txt` and `llms-full.txt` manually in repository root.

**Pros:**
- Zero dependencies, works on GitHub Pages immediately
- Full control over formatting and content
- No build complexity
- Aligns with emerging standard

**Cons:**
- Manual maintenance required for each new post
- Risk of getting out of sync with actual content

**Effort:** Low initial setup, minimal ongoing maintenance (~7 posts, infrequent updates)

### Approach 2: GitHub Actions Auto-Generation

CI workflow generates files during build.

**Pros:**
- Fully automated, always in sync
- Per-article markdown files available
- No manual maintenance

**Cons:**
- More complex setup
- Requires GitHub Actions configuration
- Deployment workflow modification needed

**Effort:** Medium initial setup, zero ongoing maintenance

### Approach 3: Jekyll Plugin (Local Build + Deploy)

Custom Jekyll plugin generates files during `jekyll build`.

**Pros:**
- Native Jekyll integration
- Automated generation
- Clean separation of concerns

**Cons:**
- Custom plugins don't work on standard GitHub Pages
- Requires local build or self-hosted Actions runner
- More maintenance overhead

**Effort:** Higher complexity, ongoing infrastructure maintenance

## Decision

**Chosen approach:** Manual `llms.txt` with links to GitHub raw markdown sources.

Rationale:
1. Blog has ~7 posts with infrequent updates — manual maintenance is minimal
2. Zero infrastructure changes required
3. Raw markdown files already accessible via GitHub
4. Follows the llms.txt standard being adopted by major players

**Not implemented:** `llms-full.txt` (concatenated content) — per-article links provide better granularity for AI crawlers to fetch only what's needed.

## Per-Article Markdown Files

The llms.txt standard supports linking to individual markdown files. Options considered:

1. **Link to GitHub raw files** ✅ — Chosen approach
2. Create `/content/` directory with copied markdown
3. Serve `.md` at same URL path (requires build changes)

Option 1 requires no additional infrastructure and works immediately.

## References

- llms.txt Specification: https://llmstxt.org
- GitHub Repository: https://github.com/AnswerDotAI/llms-txt
- Adopter Directory: https://llmstxt.site
- Example: https://anthropic.com/llms.txt
- Example: https://stripe.com/llms.txt
- Example: https://cloudflare.com/llms.txt

## Next Steps

1. ✅ Create `llms.txt` file at repository root
2. Commit and push to deploy
3. Verify at `https://shrwnsan.github.io/research/llms.txt`
4. Test with AI tools to verify discoverability
5. Update `llms.txt` when publishing new posts
