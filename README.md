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
- **TinaCMS Integration**: Headless CMS for visual content editing and management
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
├── content/                 # TinaCMS managed content
│   └── posts/              # Blog posts managed by TinaCMS
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
├── tina/                    # TinaCMS configuration
│   ├── config.ts           # TinaCMS setup and schema
│   └── __generated__/      # Auto-generated GraphQL files
├── package.json             # Node.js dependencies and scripts
├── docker-compose.yml       # Docker orchestration
├── Dockerfile              # Custom Docker image
└── README.md               # This file
```

## Adding New Research

You can add research content either manually or through TinaCMS:

### Method 1: TinaCMS Visual Editor (Recommended)
1. Start the development server (see [Local Development](#local-development))
2. Visit `http://localhost:4000/admin/index.html` to access TinaCMS
3. Use the visual editor to create and edit posts
4. TinaCMS automatically manages YAML front matter and file organization

### Method 2: Manual File Creation
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

#### 🚀 Enhanced Development Launcher (Recommended)

Start with the interactive development launcher for guided setup:

```bash
# Interactive menu with all options
./scripts/dev-start.sh
```

The launcher provides a user-friendly menu with:
- 🎨 **TinaCMS + Docker** (Recommended for visual editing)
- 💻 **TinaCMS + Local Ruby** (Advanced, faster startup)
- 🐳 **Traditional Jekyll** (Legacy Docker setup)
- 🛠️ **Utility tools** (Stop, clean, build Docker images)
- 📚 **Help and documentation**

#### Direct Commands (Power Users)

```bash
# TinaCMS + Docker (recommended)
bun run tinacms:docker
# Access CMS: http://localhost:4000/admin/index.html

# TinaCMS + Local Ruby (advanced, requires Ruby 3.1.2)
bun run tinacms
# Access CMS: http://localhost:4000/admin/index.html

# TinaCMS + Production Docker (testing)
bun run tinacms:docker-prod
# Access CMS: http://localhost:4001/admin/index.html
```

#### Traditional Development (Legacy)
```bash
# Traditional Jekyll development
./scripts/dev-start.sh dev
bundle exec jekyll serve
```

### TinaCMS Information

- **Visual Editor**: Access at `/admin/index.html` on your development server
- **GraphQL Playground**: Access at `/admin/index.html#/graphql`
- **Auto-generated Files**: TinaCMS automatically generates TypeScript types and GraphQL client in `tina/__generated__/`
- **Content Management**: Edit posts through the visual interface or manually in the `content/posts/` directory

## Deployment

The site is automatically deployed via GitHub Pages when pushing to the `main` branch. All changes must pass CI validation (Jekyll build) before deployment.

## Technical Stack

- **Jekyll**: Static site generator
- **TinaCMS**: Headless CMS with visual editing capabilities
- **Lanyon Theme**: Clean, minimal Jekyll theme
- **Mermaid.js**: Diagram and flowchart generation
- **Bun**: Package manager and runtime for JavaScript/TypeScript
- **GraphQL**: API layer for content management
- **Docker & Docker Compose**: Containerized development environment
- **GitHub Pages**: Hosting and deployment
- **Markdown**: Content authoring

## 📝 Contribution Policy

This is a **personal research repository** documenting AI-human collaborative studies:

- **✅ Issues**: Open for feedback, questions, and discussions
- **❌ Pull Requests**: Not accepting external contributions (auto-closed)

### Research Purpose

This project explores agentic augmentation - how AI tools can serve as research partners in human-driven investigations. The repository maintains consistent research methodology and documentation standards to preserve the integrity of the research findings.

### Quality Gates

All changes to this repository are protected by:
- **CI validation**: Jekyll build must pass before deployment
- **Commit signing**: All commits require cryptographic signatures
- **Admin enforcement**: All protection rules apply to repository maintainers
- **Automated PR closure**: External pull requests are automatically closed

### How to Engage

1. **Open an Issue**: Ask questions, share insights, or suggest research directions
2. **Fork & Adapt**: Use the research methodology for your own projects
3. **Reference**: Cite or build upon these research approaches in your work

### External Contributions

This repository does not accept external pull requests to maintain focused research documentation and consistent methodological approaches. Community engagement is welcomed through issues and discussions.

## License

This work is licensed under a Creative Commons Attribution 4.0 International License.

---