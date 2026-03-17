#!/bin/bash

# Development Server Launcher Script
# Enhanced with TinaCMS integration options

# Interactive script - handle errors gracefully without exiting

# Check if Docker is available
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "💡 Please install Docker Desktop or Docker Engine"
    echo "   Visit: https://www.docker.com/products/docker-desktop"
    return 1
  fi

  if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running"
    echo "💡 Please start Docker Desktop or Docker daemon"
    return 1
  fi

  return 0
}

# Check if Ruby/Bundler environment is available
check_ruby() {
  if ! command -v ruby &> /dev/null; then
    echo "❌ Ruby is not installed"
    echo "💡 Please install Ruby or use Docker-based options"
    echo "   Visit: https://www.ruby-lang.org/en/downloads/"
    echo "   Or consider: brew install ruby"
    return 1
  fi

  if ! command -v bundle &> /dev/null; then
    echo "❌ Bundler is not installed"
    echo "💡 Run: gem install bundler"
    echo "   Or: eval \"\$(rbenv init -)\" && gem install bundler"
    return 1
  fi

  # Check if rbenv is available and initialized
  if [[ -f ".ruby-version" ]] && command -v rbenv &> /dev/null; then
    if ! rbenv version &> /dev/null; then
      echo "⚠️  rbenv detected but not initialized"
      echo "💡 Run: eval \"\$(rbenv init -)\" and try again"
      return 1
    fi
  fi

  return 0
}

# Check if Node.js/Bun environment is available
check_bun() {
  if ! command -v bun &> /dev/null; then
    echo "❌ Bun is not installed"
    echo "💡 Please install Bun for optimal performance"
    echo "   Visit: https://bun.sh/"
    echo "   Or run: curl -fsSL https://bun.sh/install | bash"
    return 1
  fi

  return 0
}

# Check if node_modules exists and install if missing
check_node_modules() {
  if [[ ! -d "node_modules" ]]; then
    echo "⚠️  node_modules/ not found"
    echo "📦 Installing Node.js dependencies..."
    if bun install; then
      echo "✅ Dependencies installed successfully!"
      return 0
    else
      echo "❌ Failed to install dependencies"
      return 1
    fi
  fi
  return 0
}

# Check if Ruby gems are installed
check_ruby_gems() {
  if [[ -f "Gemfile" ]] && [[ ! -d "vendor/bundle" ]]; then
    echo "⚠️  Ruby gems not found in vendor/bundle/"
    echo "📦 Installing Ruby dependencies..."
    if bundle install --path vendor/bundle; then
      echo "✅ Ruby gems installed successfully!"
      return 0
    else
      echo "❌ Failed to install Ruby gems"
      return 1
    fi
  fi
  return 0
}

# Enhanced environment check for different scenarios
check_environment() {
  case "$1" in
    "docker")
      check_docker || return 1
      ;;
    "tinacms-docker")
      check_docker || return 1
      check_bun || return 1
      check_node_modules || return 1
      ;;
    "tinacms-local")
      check_ruby || return 1
      check_bun || return 1
      check_node_modules || return 1
      check_ruby_gems || return 1
      ;;
    "jekyll-docker")
      check_docker || return 1
      ;;
    "jekyll-local")
      check_ruby || return 1
      ;;
    "all")
      echo "🔍 Checking all development dependencies..."
      local all_good=true
      local tinacms_available=true

      check_docker || all_good=false
      check_ruby || all_good=false

      # Bun is optional - note if available for TinaCMS features
      if ! command -v bun &> /dev/null; then
        tinacms_available=false
        echo "  ⚠️  Bun not found (optional - needed only for TinaCMS)"
      else
        echo "  ✅ Bun available (for TinaCMS features)"
      fi

      if [[ "$all_good" == "true" ]]; then
        echo "✅ Core dependencies are available!"
        if [[ "$tinacms_available" == "true" ]]; then
          echo "🎨 TinaCMS features also available!"
        else
          echo "💡 Install Bun for TinaCMS content editing features"
        fi
        return 0
      else
        echo "❌ Some core dependencies are missing"
        return 1
      fi
      ;;
  esac
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
  echo "  8️⃣  🔍 Check Dependencies"
  echo "      Verify all tools are installed and working"
  echo ""
  echo "  9️⃣  ❓ Help / Legacy Commands"
  echo "      Show traditional usage options"
  echo ""
  echo "  🔟  🧹 Deep Clean (Full Reset)"
  echo "      Remove all local dependencies + Docker cleanup"
  echo ""
  echo -n "👉 Choose an option (1-10): "
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
    9) return 9 ;;
    10) return 10 ;;
    *) return 0 ;;
  esac
}

# Execute TinaCMS + Docker
run_tinacms_docker() {
  echo "🎨 Starting TinaCMS + Docker development..."
  echo ""

  if ! check_environment "tinacms-docker"; then
    echo ""
    echo "❌ Cannot start TinaCMS + Docker: Missing dependencies"
    echo "💡 Try option 3 for Docker-only, or option 8 to check all dependencies"
    if [[ -t 0 ]]; then
      echo "  • Press Enter to continue..."
      read
    else
      echo ""
    fi
    return 1
  fi

  echo "📍 CMS: http://localhost:4000/admin/index.html"
  echo "📍 Site: http://localhost:4000"
  echo "🔄 Press Ctrl+C to stop"
  echo ""
  bun run tinacms:docker
}

# Execute TinaCMS + Local Ruby
run_tinacms_local() {
  echo "💻 Starting TinaCMS + Local Ruby development..."
  echo ""

  if ! check_environment "tinacms-local"; then
    echo ""
    echo "❌ Cannot start TinaCMS + Local Ruby: Missing dependencies"
    echo "💡 Try option 1 for Docker-based TinaCMS, or option 8 to check all dependencies"
    if [[ -t 0 ]]; then
      echo "  • Press Enter to continue..."
      read
    else
      echo ""
    fi
    return 1
  fi

  echo "📍 CMS: http://localhost:4000/admin/index.html"
  echo "📍 Site: http://localhost:4000"
  echo "🔄 Press Ctrl+C to stop"
  echo ""
  bun run tinacms
}

# Execute legacy Jekyll Docker
run_jekyll_dev() {
  echo "🐳 Starting legacy Jekyll development server..."
  echo ""

  if ! check_environment "jekyll-docker"; then
    echo ""
    echo "❌ Cannot start Jekyll Docker: Docker not available"
    echo "💡 Try option 2 for local Ruby development, or option 8 to check all dependencies"
    if [[ -t 0 ]]; then
      echo "  • Press Enter to continue..."
      read
    else
      echo ""
    fi
    return 1
  fi

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

# Check all dependencies
check_all_dependencies() {
  echo "🔍 **Development Environment Dependency Check**"
  echo ""

  check_environment "all"
  local result=$?

  echo ""
  echo "📋 **Detailed Status:**"
  echo ""

  # Docker check with detailed info
  echo "🐳 **Docker Environment:**"
  if command -v docker &> /dev/null; then
    echo "  ✅ Docker command found"
    if docker info &> /dev/null; then
      echo "  ✅ Docker daemon running"
      echo "  📍 Version: $(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1)"
    else
      echo "  ❌ Docker daemon not running"
    fi
  else
    echo "  ❌ Docker command not found"
  fi
  echo ""

  # Ruby environment check with detailed info
  echo "💎 **Ruby Environment:**"
  if command -v ruby &> /dev/null; then
    echo "  ✅ Ruby command found"
    echo "  📍 Version: $(ruby --version 2>/dev/null | cut -d' ' -f2)"

    if command -v bundle &> /dev/null; then
      echo "  ✅ Bundler found"
      echo "  📍 Version: $(bundle --version 2>/dev/null | cut -d' ' -f3)"
    else
      echo "  ❌ Bundler not found"
    fi

    if [[ -f ".ruby-version" ]]; then
      echo "  📄 Project Ruby version: $(cat .ruby-version | tr -d '\n')"
      if command -v rbenv &> /dev/null; then
        echo "  ✅ rbenv available"
        if rbenv version &> /dev/null; then
          echo "  ✅ rbenv initialized"
          echo "  📍 Active: $(rbenv version | cut -d' ' -f1)"
        else
          echo "  ⚠️  rbenv not initialized"
        fi
      else
        echo "  ⚠️  rbenv not found (using system Ruby)"
      fi
    fi
  else
    echo "  ❌ Ruby command not found"
  fi
  echo ""

  # Bun environment check with detailed info
  echo "🥟 **Node.js/Bun Environment:**"
  if command -v bun &> /dev/null; then
    echo "  ✅ Bun command found"
    echo "  📍 Version: $(bun --version 2>/dev/null)"

    # Check if package.json exists
    if [[ -f "package.json" ]]; then
      echo "  📄 package.json found"
      echo "  📦 Dependencies: $(grep -c '"' package.json) entries"
    fi
  else
    echo "  ❌ Bun command not found"
    echo "  💡 Alternative tools:"
    if command -v node &> /dev/null; then
      echo "    ✅ Node.js available: $(node --version 2>/dev/null)"
    fi
    if command -v npm &> /dev/null; then
      echo "    ✅ npm available: $(npm --version 2>/dev/null)"
    fi
  fi
  echo ""

  echo "💡 **Recommendations:**"
  if [[ $result -eq 0 ]]; then
    if command -v bun &> /dev/null; then
      echo "  ✅ All dependencies ready! You can use any development option."
      echo "  🚀 Recommended: Option 1 (TinaCMS + Docker)"
    else
      echo "  ✅ Core dependencies ready! Jekyll development available."
      echo "  🚀 Recommended: Option 3 (Jekyll + Docker)"
      echo "  🎨 Install Bun for TinaCMS content editing: curl -fsSL https://bun.sh/install | bash"
    fi
  else
    echo "  ⚠️  Some dependencies missing. Choose compatible option:"
    echo "     • Missing Docker: Use option 2 (Local Ruby) if available"
    echo "     • Missing Ruby: Use Docker-based options (1, 3, or 4)"
    echo "     • Missing Bun: Use option 3 (Jekyll only) - Bun is optional for CMS features"
  fi
  echo ""

  if [[ -t 0 ]]; then
    echo "  • Press Enter to continue..."
    read
  else
    echo ""
  fi
}

# Deep clean - remove all local dependencies and caches
deep_clean() {
  echo "🧹 **Deep Clean - Full Environment Reset**"
  echo ""
  echo "⚠️  This will remove ALL local dependencies and caches:"
  echo ""
  echo "  📦 Node.js:"
  echo "     • node_modules/"
  echo "     • bun.lockb"
  echo ""
  echo "  💎 Ruby/Bundler:"
  echo "     • vendor/bundle/"
  echo "     • Gemfile.lock"
  echo ""
  echo "  🌐 Jekyll:"
  echo "     • _site/"
  echo "     • .jekyll-cache/"
  echo "     • .sass-cache/"
  echo ""
  echo "  🎨 TinaCMS:"
  echo "     • .tina/"
  echo ""
  echo "  🐳 Docker:"
  echo "     • All containers and volumes"
  echo "     • System prune"
  echo ""
  echo "⚠️  You will need to reinstall dependencies after this!"
  echo ""

  if [[ -t 0 ]]; then
    echo -n "❓ Are you sure? (y/N): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "❌ Deep clean cancelled"
      return 1
    fi
  fi

  echo ""
  echo "🗑️  Removing local dependencies and caches..."
  echo ""

  # Node.js cleanup
  if [[ -d "node_modules" ]]; then
    echo "  • Removing node_modules/..."
    rm -rf node_modules
  fi
  if [[ -f "bun.lockb" ]]; then
    echo "  • Removing bun.lockb..."
    rm -f bun.lockb
  fi

  # Ruby/Bundler cleanup
  if [[ -d "vendor/bundle" ]]; then
    echo "  • Removing vendor/bundle/..."
    rm -rf vendor/bundle
  fi
  if [[ -f "Gemfile.lock" ]]; then
    echo "  • Removing Gemfile.lock..."
    rm -f Gemfile.lock
  fi

  # Jekyll cleanup
  if [[ -d "_site" ]]; then
    echo "  • Removing _site/..."
    rm -rf _site
  fi
  if [[ -d ".jekyll-cache" ]]; then
    echo "  • Removing .jekyll-cache/..."
    rm -rf .jekyll-cache
  fi
  if [[ -d ".sass-cache" ]]; then
    echo "  • Removing .sass-cache/..."
    rm -rf .sass-cache
  fi

  # TinaCMS cleanup
  if [[ -d ".tina" ]]; then
    echo "  • Removing .tina/..."
    rm -rf .tina
  fi

  echo ""

  # Docker cleanup (reuse existing function logic)
  if check_docker 2>/dev/null; then
    echo "🐳 Cleaning Docker resources..."

    echo "  • Stopping containers..."
    docker-compose down -v --remove-orphans 2>/dev/null || echo "    (no containers to stop)"

    echo "  • Cleaning Docker system..."
    docker system prune -f 2>/dev/null && echo "  ✅ Docker cleaned"
  else
    echo "ℹ️  Docker not available, skipping Docker cleanup"
  fi

  echo ""
  echo "✅ Deep clean complete!"
  echo ""
  echo "🔄 **Next steps:**"
  echo "  • Run './dev-start.sh' and choose option 1 or 2"
  echo "  • Dependencies will be reinstalled automatically"
  echo "  • Or manually: bun install && bundle install --path vendor/bundle"
  echo ""

  if [[ -t 0 ]]; then
    echo "  • Press Enter to continue..."
    read
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
  echo "  ./dev-start.sh check       - Check all development dependencies"
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
    "check")
      check_all_dependencies
      ;;
    "help")
      show_help
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
        check_all_dependencies
        ;;
      9)
        show_help
        echo ""
        if [[ -t 0 ]]; then
          echo "  • Press Enter to return to menu..."
          read
        else
          exit 0
        fi
        continue
        ;;
      10)
        deep_clean
        break
        ;;
      0)
        echo "❌ Invalid choice. Please select 1-10."
        echo ""
        ;;
    esac
  done
}

# Run main function
main "$@"