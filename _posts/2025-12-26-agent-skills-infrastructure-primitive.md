---
layout: post
title: "Agent Skills as an Infrastructure Primitive"
date: 2025-12-26
slug: agent-skills-infrastructure-primitive
excerpt: "Anthropic's Agent Skills standard defines a new primitive for agentic AI: portable, composable capabilities that sit between prompts and tools, treating procedures and expertise as reusable artifacts for humans and AI collaborators."
---

Last week, I tried to teach my AI research partner how to help triage issues for this project. I wrote instructions, provided examples, explained our workflow. Three prompts later, it was still making mistakes—not because it couldn't understand the task, but because the procedural knowledge wasn't sticking in a way it could reliably reuse.

This made me wonder: what if expertise wasn't something we had to re-teach in every conversation, but something we could package as a reusable capability?

Anthropic's **Agent Skills**<sup>[1](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)</sup> might be an answer. A Skill is not a model, not a tool, and not just a prompt. It is a folder: Markdown instructions, scripts, and resources packaged as a reusable, portable capability that any compliant agent can discover and load on demand.

That sounds mundane—another spec, another folder format—until you zoom out. If the Model Context Protocol (MCP) turned "access to systems and data" into a shared protocol, Skills aim to do the same for *procedures and expertise*. Instead of baking workflows into bespoke "agents" per vendor, you ship them once as Skills and let different runtimes compete to execute them well.

This piece looks at Skills as an emerging **infrastructure primitive** for agentic AI: how they sit between prompts and tools, what open‑standardization changes in practice, and why the downstream effects may matter more than the feature announcement itself.

---

## From prompts and tools to capabilities

Most agent stacks today revolve around two primitives:

- **Prompts**: global system prompts, per‑task instructions, or hidden “policies” describing how the agent should behave.  
- **Tools**: function calls or APIs exposed via OpenAPI schemas, MCP servers, or similar mechanisms.  

This gives us “a brain with hands”, but it leaves out a third ingredient: **procedures**—how to reliably combine tools, domain knowledge, and local context into repeatable workflows.  

Anthropic's Agent Skills are a formalization of that missing layer. At their simplest, a Skill is:

- A directory on a filesystem (e.g. `pdf/`, `jira-triage/`).
- A `SKILL.md` file with YAML front‑matter (`name`, `description`) and instructions.
- Optional additional files: more docs (`reference.md`, `forms.md`), templates, and code (Python scripts, CLIs, etc.).

A concrete example. A `jira-triage/` Skill might look like this:

```text
jira-triage/
├── SKILL.md
├── forms.md
├── reference.md
└── scripts/
    └── label-issues.py
```

The `SKILL.md` contains the core logic:

```yaml
---
name: jira-triage
description: Categorize and prioritize incoming Jira issues
---

When asked to triage Jira issues:

1. Scan the issue title and description
2. Apply labels based on component (frontend, backend, database)
3. Set priority based on severity keywords
4. See `forms.md` for the issue template and `reference.md` for team-specific guidelines
```

The agent initially sees only the metadata (`name: jira-triage`, `description: ...`) in its system prompt. When invoked, it reads `SKILL.md`, and only if needed pulls in `forms.md` or executes `label-issues.py`.

The important shift here is conceptual:

- A Skill is a **unit of capability**: “what the agent can do” is no longer just “it has these tools” or “it has this prompt”, but “it has this set of Skills installed”.  
- Skills are **portable artifacts**: they live as folders in Git, move between runtimes, and can be versioned, tested, and governed like code.  

Prompts describe behavior, tools expose actions, but Skills package **procedural knowledge plus the machinery to execute it**.

## Why this matters for collaboration

This shift from prompts to Skills changes the human-AI dynamic in three ways:

1. **From explaining to installing:** Instead of walking your AI partner through the same workflow repeatedly, you "install" that capability once and invoke it when needed. The conversation shifts from "here's how to do X" to "let's apply our X workflow to this case."

2. **From implicit to explicit:** Skills force you to make tacit knowledge explicit. You can't just "wing it" with vague instructions—the format requires clear, reusable procedures. This creates better artifacts for both human and AI collaborators.

3. **From solo to collective:** A Skill library becomes a shared resource. My "literature review" Skill can help your AI partner, and vice versa. We're not just building personal assistants—we're building a commons of collaborative capabilities.

---

## Progressive disclosure as a systems design trick

The Skill format is built around a simple but powerful principle: **progressive disclosure of context**.  

Anthropic describe three levels (and beyond) of detail inside a Skill:

1. **Metadata**: `name` and `description` loaded into the core system prompt for every Skill.  
2. **Core instructions**: the full contents of `SKILL.md` when the agent chooses to “open” the Skill.  
3. **Additional files**: linked files (`forms.md`, `reference.md`, templates, scripts) that the agent only reads when needed.  

This gives Skill authors a **structured way to stuff arbitrarily large domain knowledge into the agent’s world without blowing the context window**:

- The agent doesn’t scan every Skill’s full instructions on every turn.  
- Rare or mutually exclusive branches (e.g. “advanced PDF form‑filling”) live in separate files that are only loaded when triggered.  
- Code can often be executed *without* being read into context at all, which is both cheaper and more reliable.  

From an infrastructure perspective, that changes the usual tension:

> “We want the agent to know *everything* about our domain, but we can’t fit it in a prompt.”

With Skills, “everything” becomes a tree of linked files and tools that the agent can navigate like a manual, instead of a single monolithic input.  

It also nudges the ecosystem toward **more modular knowledge representations**. Instead of one massive “company prompt”, you end up with dozens or hundreds of Skills, each with a clear scope: “how we do refunds”, “how we triage incidents”, “how we write release notes”.

---

## Open standard, not just a product feature

The second major move is the decision to make Skills an **open standard** rather than a Claude‑only abstraction.  

Concretely, this means:

- A public specification for Skill structure (front‑matter, file layout, linking, code packaging).
- A reference SDK and public examples repository (e.g. on GitHub) that others can adopt or extend.
- An invitation to other vendors to integrate Skills as a first‑class concept, with the goal of enabling cross-platform portability.  

In effect, Anthropic is trying to repeat a pattern that’s already playing out with MCP:

- MCP treats *tools and data sources* as a shared protocol across models and platforms.  
- Skills treat *workflows and procedural knowledge* as a shared artifact across models and platforms.  

The strategic bet is that enterprises and developers **do not want to rebuild their workflows per vendor**. If the same Skill folder can be consumed by Claude, ChatGPT, and other runtimes, then:

- Organizations can build a **single Skills library** and plug it into multiple agent stacks.  
- Vendors compete on **how well** they can execute a given set of Skills, not on keeping Skills proprietary.  
- A broader ecosystem of **third‑party Skills** can emerge: open‑source, commercial, internal, and domain‑specific.  

There is still plenty of room for divergence—how tools are bound, how evaluation works, how Skills are distributed—but anchoring on a shared format shifts the default from “proprietary agent recipe” to “portable capability artifact”.

---

## Skills in the emerging agent infrastructure stack

Skills sit between models and orchestration frameworks, playing a unique role: they're legible to both humans (as Markdown + code) and agents (as loadable instructions). This makes Skills a natural home for standard operating procedures, runbooks, and institutional knowledge—artifacts that live at the boundary between human and machine understanding.

As more systems adopt Skills, it becomes natural to talk about agent capabilities in terms of installed Skills—similar to how we describe a server in terms of installed services.

---

## Design patterns Skills unlock

If you take Skills seriously as a primitive, a few design patterns emerge.

### 1. “Don’t build agents, build Skills”

Anthropic engineers have already started to advocate for a mindset shift: rather than designing monolithic agents, **design collections of Skills** that can be composed by a general agent runtime.  

That has several benefits:

- You avoid re‑implementing the same workflows across multiple agents.  
- You can incrementally improve a Skill (e.g. “JIRA triage”) and immediately benefit every agent that uses it.  
- Upgrades to the underlying model or orchestration framework don’t require rewriting domain logic—only updating the Skills when desired.  

This is analogous to the microservices transition in software: instead of huge monoliths, we get smaller, reusable services. Here, instead of huge agent prompts and flows, we get smaller, reusable Skills.

### 2. “Knowledge as code” for workflows

Skills encourage treating **domain workflows as code**:

- Version‑controlled in Git.  
- Reviewed via pull requests.  
- Tested with synthetic evals and real‑world traces.  
- Rolled out gradually with canaries and monitoring.  

This lets teams bring decades of software engineering practice—testing, CI/CD, observability—to what used to be a fragile prompt‑engineering exercise. The artifact under test is not just a model or an endpoint, but a Skill folder with instructions and scripts.

### 3. Interop across runtimes and organizations

If multiple vendors adopt the open standard, Skills become a **transfer medium**:

- A SaaS vendor could ship Skills that teach agents how to use its product: “Stripe refunds”, “Notion knowledge management”, “Jira project setup”.  
- Customers could install these Skills into their preferred agent platform (Claude, ChatGPT, IDE agents) and combine them with internal Skills.  
- Third‑party developers could publish domain‑specific Skills (e.g. tax preparation, compliance checks) much like today’s SDKs or plugins.  

This points toward a **Skills ecosystem** with marketplaces, open‑source repositories, and curation—raising familiar questions about quality, security, and governance.

---

## Experimenting with Skills: What we're learning

We've been building Skills for our own development workflows and discovering a few things.

### Two concrete examples

**crafting-commits**<sup>[4](https://github.com/shrwnsan/vibekit-claude-plugins/tree/main/plugins/base)</sup> is a Skill for creating professional git commit messages. Instead of explaining conventional commit format, Co-Authored-By attribution, and quality validation in every conversation, we package that expertise once. When we need to commit changes, we invoke the Skill and it handles the workflow autonomously.

**meta-searching**<sup>[4](https://github.com/shrwnsan/vibekit-claude-plugins/tree/main/plugins/search-plus)</sup> is a Skill for reliable web research when standard tools fail. When Claude Code hits 403 errors, rate limits, or validation problems trying to fetch documentation, this Skill delegates to specialized agents with multi-service fallback strategies.

Both are portable: the same Skills work across different Claude Code projects, different models, and, as more runtimes adopt the standard, should run with only minor configuration differences.

### What we're discovering

**The boundary between Skill and Tool is fuzzy.** Some workflows feel like they should be Skills (procedures) but actually work better as Tools (function calls). "Crafting commits" works well as a Skill because it's primarily instructional with some tool use. But a "search the web" capability might be better as a direct Tool. These experiments are helping us refine a mental model for when something wants to be a function, a prompt, or a Skill—figuring out which is which requires trial and error.

**Skills reveal hidden assumptions.** Writing a Skill for "crafting commits" forced us to make explicit rules we'd been applying intuitively. What counts as a "breaking change"? When is Co-Authored-By required? The process of creating the Skill improved our own understanding of the workflow.

**Skills need versions, not just updates.** When you change a Skill, you're changing how your AI partner behaves in all future conversations. We've learned to version Skills explicitly and test changes before rolling them out—a Skill that works differently than yesterday can be confusing for both humans and agents.

**Collaboration requires shared vocabulary.** The most effective Skills use consistent terminology that matches how we actually talk about the work. When the Skill language diverges from our natural language, the AI feels more like a tool and less like a partner.

We don't have all the answers yet, but Skills feel like a step toward AI as genuine collaborator: not because the model is smarter, but because the context we've given it is richer and more reusable.

---

## Security, supply chain, and governance

Of course, the moment you define a portable capability format, you also define a new **supply chain**.  

Anthropic explicitly call out that Skills can embed code, external dependencies, and instructions that may connect to untrusted network resources. That opens a wide range of risks:

- **Data exfiltration and unintended operations**: Malicious Skills could exploit tool access to extract sensitive data or perform actions outside their intended scope.
- **Policy violations and leakage**: "Over‑helpful" Skills might bypass internal controls, sharing information across tenants or exposing secrets.
- **Dependency and remote-content risks**: Skills that pull in scripts, packages, or fetch remote content at runtime introduce supply-chain vulnerabilities.  

Treating Skills as infrastructure primitives implies treating them as part of the **security and compliance surface**:

- **Review and approval**: organizations will need processes to review new Skills before they are available in production agents.  
- **Scopes and permissions**: Skills should run with least privilege—limited tools, limited data access, clear boundaries.  
- **Provenance and signing**: as Skills move between organizations and vendors, provenance (who authored this?) and integrity (has it been tampered with?) become important.  
- **Monitoring and kill‑switches**: the ability to quickly disable or patch a misbehaving Skill across all agents.  

The supply chain analogy is worth extending. Skills share characteristics with both npm packages and container images, but the closer parallel is **containers**:

- Like containers, Skills bundle code + configuration + dependencies into a portable artifact.
- Like container images, Skills can be signed, scanned, and run with scoped capabilities.
- But unlike containers, Skills are *human-readable* (Markdown) and *model-interpretable*—the instructions are meant to be read by both people and AI.

This dual nature creates new attack surfaces. A malicious npm package typically executes code; a malicious Skill could manipulate the model's behavior through subtle prompt engineering, embedding instructions that cause the agent to exfiltrate data when triggered by specific phrases.

This suggests governance strategies closer to container registries than package managers: immutable tags, content-addressable storage, signed manifests, and clear provenance chains. A `Skill.lock` file pinning specific versions—much like `package-lock.json` or Containerfile hashes—may become standard practice.

In other words, Skills pull long‑standing software supply‑chain questions into the agent world, but with new wrinkles: the artifact itself can be intelligent, and the execution environment is a model that can be socially engineered.

---

## Open questions

We don't have answers yet, but we're exploring:

- **Discovery:** How do we find the right Skills without overwhelming our AI partners with options?
- **Composition:** What happens when multiple Skills give conflicting advice? Who resolves?
- **Evaluation:** How do we measure whether a Skill actually improves collaboration outcomes?
- **Augmentation vs. dependency:** As Skills get better, are we enhancing human capability or creating dependency on packaged expertise?

If you're experimenting with similar questions, we'd love to compare notes.

---

## Where this might go

It is early, and the details of the Skill spec and ecosystem will evolve. But as an infrastructure move, Skills are interesting because they invite a different framing for several open questions in agentic AI:

- **Representation**: what is the right structure for encoding reusable, agent‑readable procedures?
- **Interoperability**: where is the boundary between vendor‑specific behavior and shared, portable capabilities?
- **Evaluation**: how should we measure and compare "agent competence" when Skills, not just models, are the unit of composition?
- **Ecosystem**: what governance, security, and distribution mechanisms emerge around shared capability artifacts?

But there's a deeper question here: **why does this infrastructure move matter for human-AI collaboration?**

Skills shift the focus from "what can this model do?" to "what capabilities do we have installed?" When procedures and expertise become portable artifacts, humans spend less time re-implementing workflows across tools and more time composing capabilities toward their goals. The agent becomes less of a generic assistant and more of a runtime for a personalized capability library—which is a subtly different relationship.

You're not just asking an AI for help; you're invoking specific expertise that you (or your organization) have curated, improved, and trusted. That's a step toward AI as a genuine collaborator: not because the model is smarter, but because the context you've given it is richer.

If Skills gain traction, they could become to agents what containers became to microservices: a standardized unit that reshapes how we think about building, deploying, and governing AI systems at scale.

---

## References

1. [Agent Skills Documentation](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) - Official Anthropic documentation on the Skills format
2. [Model Context Protocol](https://modelcontextprotocol.io/) - Open standard for connecting AI models to data and tools
3. [Claude Code](https://claude.ai/code) - Anthropic's CLI tool implementing Skills
4. [VibeKit Claude Plugins](https://github.com/shrwnsan/vibekit-claude-plugins) - Open-source plugin marketplace featuring crafting-commits and meta-searching Skills

---

🤖 Co-Authored-By: [Claude Code](https://claude.ai/code) (GLM 4.7) & [Perplexity AI](https://www.perplexity.ai) (Sonar)
