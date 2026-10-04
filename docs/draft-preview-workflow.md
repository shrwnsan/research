# Draft Preview & Staging

Unpublished posts take a private staging pass before they are published on GitHub Pages.

```
draft files (private workspace) → rendered static preview (private host) → review → _posts/ via PR → live site
```

The preview host is external to this repository and is not documented here; operational details live in a separate private ops repository.

## Pipeline conventions

- Drafts live in a private, git-ignored workspace as complete post files (same front-matter format as `_posts/`)
- Preview pages are static handcrafted HTML — no site build required
- Preview pages hot-link this site's production CSS/JS so they render 1:1 with what will ship
- Every preview page is visibly marked as a draft and sets `noindex, nofollow`
- The preview index lists pending drafts only; when empty, it shows no posts
- On a private static host, per-article links point at concrete files rather than directory permalinks

## Preview host publishing model

Manifest-based static hosting keeps preview updates predictable:

1. Publish a manifest describing the **complete** file set for the next version
2. Upload the new/changed files to storage URLs issued for that version
3. Finalize the version — it goes live atomically; the previous version stays live until then

Omitting a file from the manifest removes it. After posts are promoted, the preview is re-published showing only the remaining drafts.

## Promotion to live

1. Posts enter `_posts/` only via PR from a `post/<slug>` branch — never committed to `main` directly (a main deploy *is* the publish event)
2. Keep the queue serial: files regenerated per PR (full-text index, feed) conflict across parallel branches
3. After merge, verify the live URL and cross-links once the Pages build completes
4. Retire the preview twins for the promoted post and re-publish the preview accordingly
5. Preview sources are backed up in the private ops repository, not here
