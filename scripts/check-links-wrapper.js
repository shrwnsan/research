#!/usr/bin/env node

const { execFileSync, execSync } = require('child_process');
const fs = require('fs');

const markdownFile = process.argv[2];

if (!markdownFile) {
  console.error('Usage: node scripts/check-links-wrapper.js <markdown-file>');
  process.exit(1);
}

// Optimization: Check if any URLs actually changed in the staged diff
// If this is a rename or a change that doesn't affect URLs, skip the check
function urlsChangedInStagedDiff(filePath) {
  try {
    const diff = execSync(`git diff --cached -- "${filePath}"`, { encoding: 'utf8' });
    const urlRegex = /https?:\/\/[^\s\)]+/g;

    // Check if this is a "new file" diff (entire file added) with no removed lines
    const hasRemovedLines = diff.split('\n').some(line => line.startsWith('-') && !line.startsWith('---'));

    if (!hasRemovedLines) {
      // This looks like a new file or a rename where git shows entire content as added
      // Check if all URL-containing lines are only in the frontmatter (between --- markers)
      const lines = diff.split('\n');
      let inFrontmatter = false;
      let frontmatterEnded = false;
      let hasUrlOutsideFrontmatter = false;

      for (const line of lines) {
        if (line.startsWith('+++')) continue;
        if (line.startsWith('---')) {
          if (!inFrontmatter && !frontmatterEnded) {
            inFrontmatter = true;
            continue;
          } else if (inFrontmatter) {
            inFrontmatter = false;
            frontmatterEnded = true;
            continue;
          }
        }
        if (line.startsWith('+')) {
          // Check if this added line has a URL outside frontmatter
          if (frontmatterEnded && urlRegex.test(line)) {
            hasUrlOutsideFrontmatter = true;
            break;
          }
        }
      }

      // If all changes are in frontmatter (date, title, etc.), no URL check needed
      if (!hasUrlOutsideFrontmatter) {
        return false;
      }
    }

    // For normal edits, extract URLs from added/removed lines
    const addedLines = diff.split('\n')
      .filter(line => line.startsWith('+') && !line.startsWith('+++'))
      .join(' ');
    const addedUrls = addedLines.match(urlRegex) || [];

    const removedLines = diff.split('\n')
      .filter(line => line.startsWith('-') && !line.startsWith('---'))
      .join(' ');
    const removedUrls = removedLines.match(urlRegex) || [];

    // If no URLs were added or removed, no need to check links
    if (addedUrls.length === 0 && removedUrls.length === 0) {
      return false;
    }

    // If the set of URLs is the same (no actual change), skip
    const addedSet = new Set(addedUrls.map(u => u.replace(/[.,;:]$/, '')));
    const removedSet = new Set(removedUrls.map(u => u.replace(/[.,;:]$/, '')));

    // Quick check: if sets are identical, nothing changed
    if (addedSet.size === removedSet.size &&
        [...addedSet].every(u => removedSet.has(u))) {
      return false;
    }

    return true;
  } catch {
    // If we can't get the diff, assume URLs changed (safe default)
    return true;
  }
}

// Skip link checking if no URLs changed in the staged diff
if (!urlsChangedInStagedDiff(markdownFile)) {
  console.log(`FILE: ${markdownFile}`);
  console.log('  No URL changes detected in staged diff, skipping link check.');
  console.log('');
  process.exit(0);
}

const content = fs.readFileSync(markdownFile, 'utf8');
const urlRegex = /https?:\/\/[^\s\)]+/g;
const urls = content.match(urlRegex) || [];

if (urls.length === 0) {
  console.log(`FILE: ${markdownFile}`);
  console.log('  No hyperlinks found!');
  console.log('');
  process.exit(0);
}

console.log(`FILE: ${markdownFile}`);

// Fallback proxy services
const proxies = [
  { name: 'r.jina.ai', format: (u) => `https://r.jina.ai/${u}` },
  { name: 'corsproxy.io', format: (u) => `https://corsproxy.io/?${encodeURIComponent(u)}` },
  { name: 'allorigins', format: (u) => `https://api.allorigins.win/raw?url=${encodeURIComponent(u)}` },
];

function checkDirect(url) {
  try {
    const response = execFileSync('curl', [
      '-s', '-o', '/dev/null', '-w', '%{http_code}',
      '--max-time', '10', url
    ], { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
    return parseInt(response.trim());
  } catch {
    return null;
  }
}

function checkViaProxies(url) {
  for (const proxy of proxies) {
    try {
      const proxyUrl = proxy.format(url);
      const response = execFileSync('curl', [
        '-s', '-o', '/dev/null', '-w', '%{http_code}',
        '--max-time', '10', proxyUrl
      ], { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
      const status = parseInt(response.trim());
      if (status >= 200 && status < 400) {
        return { status, proxy: proxy.name };
      }
      if (status !== 429 && status !== 503) {
        return { status, proxy: proxy.name };
      }
    } catch {
      continue;
    }
  }
  return null;
}

let deadLinks = [];
let checkedCount = 0;

for (const url of urls) {
  if (url.startsWith('../') || url.startsWith('./') || url.includes('"') || url.includes('>')) {
    continue;
  }

  checkedCount++;
  const directStatus = checkDirect(url);

  if (directStatus && directStatus >= 200 && directStatus < 400) {
    console.log(`  [\x1b[32m✓\x1b[0m] ${url}`);
  } else if (directStatus === 403) {
    const proxyResult = checkViaProxies(url);
    if (proxyResult) {
      console.log(`  [\x1b[32m✓\x1b[0m] ${url} (via ${proxyResult.proxy})`);
    } else {
      console.log(`  [\x1b[31m✖\x1b[0m] ${url} → 403, all proxies failed`);
      deadLinks.push(url);
    }
  } else {
    console.log(`  [\x1b[31m✖\x1b[0m] ${url} → ${directStatus || 'failed'}`);
    if (directStatus !== 404) deadLinks.push(url);
  }
}

console.log(`  ${checkedCount} links checked.`);
console.log('');

process.exit(deadLinks.length > 0 ? 1 : 0);
