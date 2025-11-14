#!/bin/bash

# Development Server Launcher Script
# Enhanced with TinaCMS integration options

# Interactive script - handle errors gracefully without exiting

# Check if Docker is available
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "💡 Please install Docker Desktop or Docker Engine"
    return 1
  fi

  if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running"
    echo "💡 Please start Docker Desktop or Docker daemon"
    return 1
  fi

  return 0
}

# Interactive menu function
show_menu() {
  echo "🚀 **Research Platform Development Launcher**"
  echo ""
  echo "📋 **Choose your development environment:**"
  echo ""
  echo "  1️⃣  🎨 TinaCMS + Docker (Recommended)"
  echo "      Visual content editor + Jekyll in Docker"
  echo "      Access CMS: http://localhost:4000/admin/index.html"
  echo ""
  echo "  2️⃣  💻 TinaCMS + Local Ruby (Advanced)"
  echo "      Visual editor + Local Jekyll (faster, requires Ruby 3.1.2)"
  echo "      Access CMS: http://localhost:4000/admin/index.html"
  echo ""
  echo "  3️⃣  🐳 Jekyll Only - Docker (Legacy)"
  echo "      Traditional Jekyll development via Docker"
  echo "      Site: http://localhost:4000"
  echo ""
  echo "  4️⃣  🏭 Production-like Jekyll (Testing)"
  echo "      Production configuration in Docker"
  echo "      Site: http://localhost:4001"
  echo ""
  echo "  5️⃣  ⏹️  Stop All Services"
  echo "      Stop all running containers"
  echo ""
  echo "  6️⃣  🧹 Clean Environment"
  echo "      Remove containers and volumes"
  echo ""
  echo "  7️⃣  🔨 Clean Build Docker Image"
  echo "      Clear cache + rebuild custom image from scratch"
  echo ""
  echo "  8️⃣  ❓ Help / Legacy Commands"
  echo "      Show traditional usage options"
  echo ""
  echo -n "👉 Choose an option (1-8): "
}

# Get user choice
get_choice() {
  local choice
  if [[ -t 0 ]]; then
    # Interactive mode - read from stdin
    read choice
  else
    # Non-interactive mode - read from stdin (for testing)
    read -r choice <&0
  fi

  case $choice in
    1) return 1 ;;
    2) return 2 ;;
    3) return 3 ;;
    4) return 4 ;;
    5) return 5 ;;
    6) return 6 ;;
    7) return 7 ;;
    8) return 8 ;;
    *) return 0 ;;
  esac
}

# Execute TinaCMS + Docker
run_tinacms_docker() {
  echo "🎨 Starting TinaCMS + Docker development..."
  echo "📍 CMS: http://localhost:4000/admin/index.html"
  echo "📍 Site: http://localhost:4000"
  echo "🔄 Press Ctrl+C to stop"
  echo ""
  bun run tinacms:docker
}

# Execute TinaCMS + Local Ruby
run_tinacms_local() {
  echo "💻 Starting TinaCMS + Local Ruby development..."
  echo "📍 CMS: http://localhost:4000/admin/index.html"
  echo "📍 Site: http://localhost:4000"
  echo "🔄 Press Ctrl+C to stop"
  echo ""
  bun run tinacms
}

# Execute legacy Jekyll Docker
run_jekyll_dev() {
  echo "🐳 Starting legacy Jekyll development server..."
  echo "📍 Site will be available at: http://localhost:4000"
  echo "🔄 Live reload enabled on port 35729"
  echo "🔄 Press Ctrl+C to stop"
  echo ""
  docker-compose up jekyll
}

# Execute production Jekyll
run_jekyll_prod() {
  echo "🏭 Starting production-like Jekyll server..."
  echo "📍 Site will be available at: http://localhost:4001"
  echo "🔄 Press Ctrl+C to stop"
  echo ""
  docker-compose --profile production up jekyll-prod
}

# Stop all services
stop_services() {
  if ! check_docker; then
    echo ""
    echo "❌ Cannot stop services: Docker not available"
    echo "💡 Please start Docker and try again"
    if [[ -t 0 ]]; then
      echo "  • Press Enter to continue..."
      read
    else
      echo ""
    fi
    return 1
  fi

  echo "⏹️  Stopping all containers..."
  if docker-compose down 2>/dev/null; then
    echo "✅ All services stopped!"
  else
    echo "ℹ️  No running containers found or stop completed"
  fi
  echo ""
  echo "🔄 Next steps:"
  echo "  • Run './dev-start.sh' again to restart development"
  echo "  • Choose option 6 for a complete clean reset"
  if [[ -t 0 ]]; then
    echo "  • Press Enter to continue..."
    read
  else
    echo ""
  fi
}

# Clean environment
clean_environment() {
  if ! check_docker; then
    echo ""
    echo "❌ Cannot clean environment: Docker not available"
    echo "💡 Please start Docker and try again"
    if [[ -t 0 ]]; then
      echo "  • Press Enter to continue..."
      read
    else
      echo ""
    fi
    return 1
  fi

  echo "🧹 Cleaning up containers and volumes..."

  echo "  • Stopping containers..."
  docker-compose down -v --remove-orphans 2>/dev/null || echo "    (no containers to stop)"

  echo "  • Cleaning Docker system..."
  if docker system prune -f 2>/dev/null; then
    echo "✅ Docker system cleaned!"
  else
    echo "ℹ️  Docker system prune completed (or no permission)"
  fi

  echo ""
  echo "✅ Environment cleaned!"
  echo "🔄 Next steps:"
  echo "  • Run './dev-start.sh' for fresh development start"
  echo "  • This gives you a completely clean slate"
  if [[ -t 0 ]]; then
    echo "  • Press Enter to continue..."
    read
  else
    echo ""
  fi
}

# Build Docker image
build_image() {
  if ! check_docker; then
    echo ""
    echo "❌ Cannot build Docker image: Docker not available"
    echo "💡 Please start Docker and try again"
    if [[ -t 0 ]]; then
      echo "  • Press Enter to continue..."
      read
    else
      echo ""
    fi
    return 1
  fi

  echo "🔨 Building custom Docker image with clean cache..."

  echo "🧹 Clearing Docker build cache for fresh rebuild..."
  if docker builder prune -f 2>/dev/null; then
    echo "  ✅ Build cache cleared"
  else
    echo "  ℹ️  Build cache cleared (or no permission)"
  fi

  echo ""
  echo "🏗️  Building custom Docker image from scratch..."
  if docker build --no-cache -t research-jekyll . 2>/dev/null; then
    echo ""
    echo "✅ Custom Docker image built with clean cache!"
  else
    echo ""
    echo "⚠️  Docker build completed (check output above for any warnings)"
  fi

  echo ""
  echo "🎯 **When to use clean rebuild:**"
  echo "  • Debug Docker layer caching issues"
  echo "  • Force rebuild after Dockerfile changes"
  echo "  • Test completely fresh environment"
  echo "  • Resolve dependency caching problems"
  echo ""
  echo "💡 **What this does:**"
  echo "  • Removes all build cache (docker builder prune -f)"
  echo "  • Rebuilds all layers from scratch (--no-cache)"
  echo "  • Ensures completely fresh environment"
  echo ""
  echo "🔄 Next steps:"
  echo "  • Option 1: Test with TinaCMS + Docker"
  echo "  • Option 3: Test with Jekyll only"
  if [[ -t 0 ]]; then
    echo "  • Press Enter to continue..."
    read
  else
    echo ""
  fi
}

# Show help and legacy options
show_help() {
  echo "❓ **Help & Legacy Commands**"
  echo ""
  echo "📖 **Interactive Mode (Recommended):**"
  echo "  ./dev-start.sh"
  echo ""
  echo "🔧 **Legacy Direct Commands:**"
  echo "  ./dev-start.sh dev         - Jekyll development (legacy)"
  echo "  ./dev-start.sh prod        - Production-like Jekyll"
  echo "  ./dev-start.sh stop        - Stop all containers"
  echo "  ./dev-start.sh clean       - Clean up containers and volumes"
  echo "  ./dev-start.sh build       - Build custom Docker image"
  echo "  ./dev-start.sh build-serve - Build and serve with custom image"
  echo ""
  echo "📝 **Package Scripts (TinaCMS):**"
  echo "  bun run tinacms:docker     - TinaCMS + Docker (recommended)"
  echo "  bun run tinacms            - TinaCMS + Local Ruby"
  echo "  bun run tinacms:docker-prod - TinaCMS + Production Docker"
  echo ""
}

# Legacy command line handling
handle_legacy() {
  case "${1}" in
    "dev")
      run_jekyll_dev
      ;;
    "prod")
      run_jekyll_prod
      ;;
    "stop")
      stop_services
      ;;
    "clean")
      clean_environment
      ;;
    "build")
      build_image
      ;;
    "build-serve")
      echo "🔨 Building and serving with custom image..."
      docker build -t research-jekyll .
      docker run --rm -p 4000:4000 -p 35729:35729 \
        -v "$(pwd):/srv/jekyll" \
        -v "$(pwd)/vendor/bundle:/usr/local/bundle" \
        research-jekyll
      ;;
    *)
      echo "❓ Unknown legacy option: $1"
      echo "💡 Run './dev-start.sh' for interactive menu or './dev-start.sh help' for options"
      exit 1
      ;;
  esac
}

# Main execution
main() {
  # Handle legacy direct commands
  if [ $# -gt 0 ]; then
    handle_legacy "$1"
    exit 0
  fi

  # Interactive mode
  while true; do
    show_menu
    get_choice
    choice=$?

    echo ""
    case $choice in
      1)
        run_tinacms_docker
        break
        ;;
      2)
        run_tinacms_local
        break
        ;;
      3)
        run_jekyll_dev
        break
        ;;
      4)
        run_jekyll_prod
        break
        ;;
      5)
        stop_services
        break
        ;;
      6)
        clean_environment
        break
        ;;
      7)
        build_image
        break
        ;;
      8)
        show_help
        echo ""
        ;;
      0)
        echo "❌ Invalid choice. Please select 1-8."
        echo ""
        ;;
    esac
  done
}

# Run main function
main "$@"