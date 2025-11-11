# Research: Agentic Augmentation

Exploring what emerges when human curiosity meets AI capability through collaborative research projects.

## About

Welcome to a living experiment in **agentic augmentation** - research projects carried out by AI tools in collaboration with human guidance. Each post represents a conversation between human intent and AI execution, where the questions we ask shape the solutions that emerge.

What happens when we treat AI not as a tool, but as a research partner?

Our findings suggest the boundaries between creator and assistant are becoming increasingly blurred - but is this truly augmentation or merely replacement? The projects here speak for themselves, yet we wonder: what becomes possible when anyone, not just developers or researchers, can harness AI capabilities directly?

While tech professionals may be the early adopters of these agentic tools, we believe the implications reach far beyond. What could a student build? An entrepreneur prototype? An artist create? When AI becomes a collaborative partner rather than just a chat interface, what new forms of expression and problem-solving emerge?

We don't have all the answers, but we're documenting what we discover. Perhaps you'll see possibilities we haven't considered yet.

## Features

- **Lanyon Theme**: Clean, minimal design with sidebar toggle and responsive layout
- **Mermaid Diagrams**: Interactive technical diagrams, flowcharts, and architectural visualizations
- **Roberto Typography**: Professional fonts optimized for readability
- **GitHub Pages Ready**: Fully optimized for deployment on GitHub Pages
- **Mobile Responsive**: Seamless experience across all devices
- **Semantic HTML**: Modern web standards with accessibility in mind
- **Fast Loading**: Optimized assets and performance-focused design

## Structure

```
research/
├── _config.yml              # Jekyll configuration
├── index.html               # Homepage with post listings
├── about.md                 # About page
├── colophon.md              # Colophon/methodology page
├── _posts/                  # Research articles
│   └── YYYY-MM-DD-title.md  # Posts follow Jekyll naming convention
├── _includes/               # Reusable components
│   ├── head.html           # HTML head section
│   └── sidebar.html        # Sidebar navigation
├── _layouts/                # Page templates
│   ├── default.html        # Base layout
│   ├── post.html           # Blog post layout
│   └── page.html           # Static page layout
├── public/                  # Static assets
│   ├── css/                # Stylesheets (Lanyon theme)
│   ├── js/                 # JavaScript files
│   └── favicon.ico         # Site favicon
├── scripts/                 # Development utilities
│   └── dev-start.sh        # Docker development launcher
├── docs/                    # Documentation
│   ├── DOCKER-README.md    # Docker setup guide
│   └── social-sharing-setup.md # Social media configuration
├── docker-compose.yml       # Docker orchestration
├── Dockerfile              # Custom Docker image
└── README.md               # This file
```

## Adding New Research

1. Create a new markdown file in `_posts/` following the format: `YYYY-MM-DD-title.md`
2. Add YAML front matter:
   ```yaml
   ---
   title: "Research Title"
   date: YYYY-MM-DD
   excerpt: "Brief description of the research findings"
   ---
   ```
3. Write your research content in Markdown with proper formatting
4. Include Mermaid diagrams using triple backticks with `mermaid` language:
   ```markdown
   ```mermaid
   graph TD
       A[Research Question] --> B[Methodology]
       B --> C[Findings]
       C --> D[Conclusions]
   ```
   ```
5. Use proper headings (##, ###) for structure and readability

## Local Development

For comprehensive development setup and documentation:

📖 **See [docs/DOCKER-README.md](docs/DOCKER-README.md) for Docker setup**
📖 **See [docs/social-sharing-setup.md](docs/social-sharing-setup.md) for social media configuration**

### Quick Start
```bash
# Docker development (recommended)
./scripts/dev-start.sh dev
# Visit http://localhost:4000

# Using Ruby Jekyll
bundle install
bundle exec jekyll serve
```

## Deployment

The site is automatically deployed via GitHub Pages when pushing to the `main` branch. Ensure all changes are committed and pushed for live updates.

## Technical Stack

- **Jekyll**: Static site generator
- **Lanyon Theme**: Clean, minimal Jekyll theme
- **Mermaid.js**: Diagram and flowchart generation
- **GitHub Pages**: Hosting and deployment
- **Markdown**: Content authoring

## 📝 Contribution Policy

This is a **personal research repository** documenting AI-human collaborative studies:

- **✅ Issues**: Open for feedback, questions, and discussions
- **❌ Pull Requests**: Not accepting external contributions

### Research Purpose

This project explores agentic augmentation - how AI tools can serve as research partners in human-driven investigations. The repository maintains consistent research methodology and documentation standards to preserve the integrity of the research findings.

### How to Engage

1. **Open an Issue**: Ask questions, share insights, or suggest research directions
2. **Fork & Adapt**: Use the research methodology for your own projects
3. **Reference**: Cite or build upon these research approaches in your work

### External Contributions

This repository does not accept external pull requests to maintain focused research documentation and consistent methodological approaches. Community engagement is welcomed through issues and discussions.

## License

This work is licensed under a Creative Commons Attribution 4.0 International License.

---