#!/usr/bin/env node

const { execFileSync } = require('child_process');
const fs = require('fs');

const markdownFile = process.argv[2];

if (!markdownFile) {
  console.error('Usage: node scripts/check-links-wrapper.js <markdown-file>');
  process.exit(1);
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
