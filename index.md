---
layout: home
title: Research: Agentic Augmentation
---

Welcome to my research hub on agentic augmentation. This is a collection of technical research and analysis powered by AI tools.

## Recent Research

{% for post in site.posts limit:5 %}
* **[{{ post.title }}]({{ post.url }})** - {{ post.date | date: "%B %d, %Y" }}
{% endfor %}

## About

This repository contains research papers, technical analysis, and explorations conducted with the assistance of AI agents and tools. The goal is to document findings, share insights, and contribute to the growing body of knowledge about agentic augmentation in development and research workflows.