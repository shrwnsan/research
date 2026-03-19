#!/usr/bin/env node

/**
 * Generates llms.txt from _posts/*.md files
 * Run as pre-commit hook to keep llms.txt in sync with posts
 */

const fs = require('fs');
const path = require('path');

const POSTS_DIR = path.join(__dirname, '..', '_posts');
const OUTPUT_FILE = path.join(__dirname, '..', 'llms.txt');

const SITE_TITLE = 'Research: Agentic Augmentation';
const SITE_SUMMARY = 'Technical research and analysis on AI agents, foundation model selection, and agentic systems. Focused on practical implementations and lessons learned.';
const RAW_GITHUB_BASE = 'https://raw.githubusercontent.com/shrwnsan/research/main/_posts/';

function extractFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};

  const frontmatter = {};
  const lines = match[1].split('\n');

  for (const line of lines) {
    const colonIndex = line.indexOf(':');
    if (colonIndex === -1) continue;

    const key = line.slice(0, colonIndex).trim();
    let value = line.slice(colonIndex + 1).trim();

    // Remove quotes if present
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }

    // Handle arrays like tags: [a, b, c]
    if (value.startsWith('[') && value.endsWith(']')) {
      value = value.slice(1, -1).split(',').map(s => s.trim());
    }

    frontmatter[key] = value;
  }

  return frontmatter;
}

function getPosts() {
  const files = fs.readdirSync(POSTS_DIR)
    .filter(f => f.endsWith('.md'))
    .sort((a, b) => b.localeCompare(a)); // Newest first

  return files.map(filename => {
    const filepath = path.join(POSTS_DIR, filename);
    const content = fs.readFileSync(filepath, 'utf8');
    const frontmatter = extractFrontmatter(content);

    return {
      filename,
      title: frontmatter.title || filename,
      slug: frontmatter.slug || filename.replace(/^\d{4}-\d{2}-\d{2}-/, '').replace(/\.md$/, ''),
      excerpt: frontmatter.excerpt || '',
      date: frontmatter.date || ''
    };
  });
}

function generateLlmsTxt(posts) {
  const lines = [
    `# ${SITE_TITLE}`,
    '',
    `> ${SITE_SUMMARY}`,
    '',
    '## Articles',
    ''
  ];

  for (const post of posts) {
    const rawUrl = `${RAW_GITHUB_BASE}${post.filename}`;
    const description = post.excerpt ? `: ${post.excerpt}` : '';
    lines.push(`- [${post.title}](${rawUrl})${description}`);
  }

  return lines.join('\n') + '\n';
}

function main() {
  const posts = getPosts();

  if (posts.length === 0) {
    console.error('No posts found in _posts/');
    process.exit(1);
  }

  const content = generateLlmsTxt(posts);
  fs.writeFileSync(OUTPUT_FILE, content);

  console.log(`Generated llms.txt with ${posts.length} articles`);
}

main();
