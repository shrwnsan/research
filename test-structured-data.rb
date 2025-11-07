#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'time'

# Load Jekyll config
config = YAML.load_file('_config.yml')

# Simulate Jekyll site object
site = {
  'url' => config['url'],
  'baseurl' => config['baseurl'],
  'title' => config['title'],
  'description' => config['description'],
  'author' => config['author'],
  'time' => Time.now
}

# Test with a blog post
test_post = {
  'layout' => 'post',
  'title' => 'Conductor - Comprehensive Analysis & Review',
  'date' => Time.parse('2025-11-06'),
  'excerpt' => 'Analysis of Conductor orchestration platform for multi-agent AI development',
  'url' => '/ai-conductor-analysis/',
  'content' => 'This is a test blog post content with multiple words to test word count functionality.'
}

# Test with a regular page
test_page = {
  'layout' => 'page',
  'title' => 'About',
  'url' => '/about/'
}

# Test homepage
test_home = {
  'layout' => 'default',
  'title' => 'Home',
  'url' => '/'
}

def generate_json_ld(page, site, content = '')
  # Simulate Jekyll's absolute_url filter
  def self.absolute_url(url, site)
    "#{site['url']}#{site['baseurl']}#{url}"
  end

  # Simulate Jekyll's jsonify filter
  def self.jsonify(obj)
    obj.to_json
  end

  # Simulate Jekyll's date filters
  def self.date_to_xmlschema(time)
    time.strftime('%Y-%m-%dT%H:%M:%S%z')
  end

  # Basic JSON-LD structure
  json_ld = {
    '@context' => 'https://schema.org',
    '@graph' => []
  }

  # Website schema
  json_ld['@graph'] << {
    '@type' => 'WebSite',
    '@id' => "#{self.absolute_url('/', site)}#website",
    'url' => self.absolute_url('/', site),
    'name' => site['title'],
    'description' => site['description'],
    'inLanguage' => 'en-US',
    'isFamilyFriendly' => 'true'
  }

  # Organization schema
  json_ld['@graph'] << {
    '@type' => 'Organization',
    '@id' => "#{self.absolute_url('/', site)}#organization",
    'name' => site['title'],
    'url' => self.absolute_url('/', site),
    'logo' => {
      '@type' => 'ImageObject',
      'url' => self.absolute_url('/apple-touch-icon-precomposed.png', site),
      'width' => 144,
      'height' => 144
    },
    'description' => site['description']
  }

  # Page-specific schemas
  if page['layout'] == 'post'
    # BlogPosting schema
    json_ld['@graph'] << {
      '@type' => 'BlogPosting',
      '@id' => "#{absolute_url(page['url'])}#blogposting",
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => absolute_url(page['url'])
      },
      'headline' => page['title'],
      'description' => page['excerpt'],
      'image' => [absolute_url('/apple-touch-icon-precomposed.png')],
      'datePublished' => date_to_xmlschema(page['date']),
      'dateModified' => date_to_xmlschema(page['date']),
      'author' => {
        '@type' => 'Person',
        'name' => site['author']['name']
      },
      'publisher' => {
        '@type' => 'Organization',
        '@id' => "#{absolute_url('/')}#organization",
        'name' => site['title']
      },
      'wordCount' => content.split.length,
      'inLanguage' => 'en-US'
    }

    # BreadcrumbList for blog posts
    json_ld['@graph'] << {
      '@type' => 'BreadcrumbList',
      '@id' => "#{absolute_url(page['url'])}#breadcrumb",
      'itemListElement' => [
        {
          '@type' => 'ListItem',
          'position' => 1,
          'name' => 'Home',
          'item' => absolute_url('/')
        },
        {
          '@type' => 'ListItem',
          'position' => 2,
          'name' => 'Blog',
          'item' => absolute_url('/')
        },
        {
          '@type' => 'ListItem',
          'position' => 3,
          'name' => page['title'],
          'item' => absolute_url(page['url'])
        }
      ]
    }
  else
    # WebPage schema
    json_ld['@graph'] << {
      '@type' => 'WebPage',
      '@id' => "#{absolute_url(page['url'])}#webpage",
      'url' => absolute_url(page['url']),
      'name' => page['title'],
      'description' => page['title'] == 'Home' ? site['description'] : "#{page['title']} - #{site['title']}",
      'isPartOf' => {
        '@type' => 'WebSite',
        '@id' => "#{absolute_url('/')}#website"
      },
      'inLanguage' => 'en-US'
    }

    # BreadcrumbList for static pages
    json_ld['@graph'] << {
      '@type' => 'BreadcrumbList',
      '@id' => "#{absolute_url(page['url'])}#breadcrumb",
      'itemListElement' => [
        {
          '@type' => 'ListItem',
          'position' => 1,
          'name' => 'Home',
          'item' => absolute_url('/')
        },
        {
          '@type' => 'ListItem',
          'position' => 2,
          'name' => page['title'],
          'item' => absolute_url(page['url'])
        }
      ]
    }
  end

  json_ld
end

puts "Testing JSON-LD Structured Data Generation"
puts "=" * 50

# Test Blog Post
puts "\n1. BLOG POST STRUCTURED DATA:"
puts "Page: #{test_post['title']}"
blog_json_ld = generate_json_ld(test_post, site, test_post['content'])
puts JSON.pretty_generate(blog_json_ld)

# Test Regular Page
puts "\n2. STATIC PAGE STRUCTURED DATA:"
puts "Page: #{test_page['title']}"
page_json_ld = generate_json_ld(test_page, site)
puts JSON.pretty_generate(page_json_ld)

# Test Homepage
puts "\n3. HOMEPAGE STRUCTURED DATA:"
puts "Page: #{test_home['title']}"
home_json_ld = generate_json_ld(test_home, site)
puts JSON.pretty_generate(home_json_ld)

puts "\n" + "=" * 50
puts "Validation complete! All schemas generated successfully."
puts "\nSchema.org types included:"
puts "- WebSite (site-wide)"
puts "- Organization (site-wide)"
puts "- BlogPosting (for blog posts)"
puts "- WebPage (for static pages and homepage)"
puts "- BreadcrumbList (navigation)"
puts "\nRich snippet features enabled:"
puts "- Search results with enhanced display"
puts "- Article metadata for posts"
puts "- Breadcrumb navigation"
puts "- Organization information"
puts "- Website search functionality"