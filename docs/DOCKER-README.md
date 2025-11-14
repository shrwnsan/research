# Docker Development Setup

This project includes Docker configuration for easy local development and testing.

## Quick Start

### Development Server
```bash
# Start development server with live reload
./dev-start.sh dev
# or
docker-compose up jekyll
```
📍 **Access:** http://localhost:4000
🔄 **Live reload:** Enabled (port 35729)

### Quick Development
```bash
# Start development server for visual testing
./scripts/dev-start.sh dev
# Visit http://localhost:4000 to see changes
```

## Commands

### Using the convenience script:
```bash
./scripts/dev-start.sh dev         # Development server
./scripts/dev-start.sh prod        # Production-like server
./scripts/dev-start.sh stop        # Stop all containers
./scripts/dev-start.sh clean       # Clean up containers and volumes
./scripts/dev-start.sh build       # Build custom image
./scripts/dev-start.sh build-serve # Build and serve custom image
```

### Using Docker Compose directly:
```bash
# Development
docker-compose up jekyll

# Production (with profile)
docker-compose --profile production up jekyll-prod

# Stop
docker-compose down
```

## Features

### Development Container
- **Live reload** for rapid development
- **Incremental builds** for faster startup
- **Force polling** for file change detection
- **Development environment** settings

### Production Container
- **Full site build** before serving
- **Production-like environment**
- **Future and unpublished posts** enabled for testing
- **Separate port** (4001) for simultaneous testing

## File Structure

```
├── docker-compose.yml    # Container orchestration
├── Dockerfile            # Custom image definition
├── .dockerignore         # Files to exclude from Docker context
├── scripts/
│   └── dev-start.sh      # Convenience launcher script
└── DOCKER-README.md      # This file
```

## Development Workflow

1. **Make changes** to CSS or HTML files
2. **Start server**: `./scripts/dev-start.sh dev`
3. **View changes**: http://localhost:4000
4. **Iterate** with live reload

## Cleanup

```bash
# Stop containers
./scripts/dev-start.sh stop

# Full cleanup
./scripts/dev-start.sh clean

# Manual cleanup
docker-compose down -v --remove-orphans
docker system prune -f
```

## Troubleshooting

### Port conflicts
- Development server uses port 4000
- Production server uses port 4001
- Live reload uses port 35729

### Slow first startup
- First run downloads all gems (can take 2-3 minutes)
- Subsequent starts are much faster
- Use `./scripts/dev-start.sh build` for custom image optimization

### File permission issues
- Ensure scripts are executable: `chmod +x scripts/*.sh`
- Docker volumes handle permissions automatically