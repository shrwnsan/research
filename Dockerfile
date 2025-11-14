FROM jekyll/jekyll:latest

# Install additional dependencies if needed
RUN gem update --system && \
    gem install bundler

# Set working directory
WORKDIR /srv/jekyll

# Expose ports
EXPOSE 4000 35729

# Default command
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--livereload"]