#!/bin/bash

# Development Server Launcher Script
# Usage: ./dev-start.sh [dev|prod|stop|clean]

set -e

case "${1:-dev}" in
  "dev")
    echo "🚀 Starting Jekyll development server..."
    echo "📍 Site will be available at: http://localhost:4000"
    echo "🔄 Live reload enabled on port 35729"
    docker-compose up jekyll
    ;;
  "prod")
    echo "🏭 Starting Jekyll production server..."
    echo "📍 Site will be available at: http://localhost:4001"
    docker-compose --profile production up jekyll-prod
    ;;
  "stop")
    echo "⏹️  Stopping all containers..."
    docker-compose down
    ;;
  "clean")
    echo "🧹 Cleaning up containers and volumes..."
    docker-compose down -v --remove-orphans
    docker system prune -f
    ;;
  "build")
    echo "🔨 Building custom Docker image..."
    docker build -t research-jekyll .
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
    echo "❓ Usage: $0 [dev|prod|stop|clean|build|build-serve]"
    echo ""
    echo "Commands:"
    echo "  dev         - Start development server (default)"
    echo "  prod        - Start production-like server"
    echo "  stop        - Stop all containers"
    echo "  clean       - Clean up containers and volumes"
    echo "  build       - Build custom Docker image"
    echo "  build-serve - Build and serve with custom image"
    exit 1
    ;;
esac