# Social Sharing Setup Guide

This Jekyll site is now configured with comprehensive Open Graph and Twitter Card support for optimal social media sharing.

## Configuration

### Site-Wide Settings (in `_config.yml`)

```yaml
# Social media settings
twitter_username:            "your_username"  # Your Twitter username without @
social_image:                "/apple-touch-icon-precomposed.png"  # Default social sharing image
facebook_app_id:             ""  # Facebook App ID for insights
social_logo:                 "/apple-touch-icon-precomposed.png"  # Logo for structured data
```

### Per-Page Settings (Front Matter)

You can override the default social sharing settings on individual pages/posts using front matter:

```yaml
---
title: "Your Page Title"
description: "A compelling description for social sharing"

# Social media specific overrides
social_image: "/path/to/your/social-image.jpg"
social_image_alt: "Alt text describing the image"
twitter_card: "summary_large_image"  # or "summary"
author_twitter: "@author_twitter_handle"

# For blog posts
layout: "post"
author: "Author Name"
date: 2024-01-01
tags: ["tag1", "tag2"]
category: "Research"
---
```

## Image Requirements

### Optimal Image Sizes

- **Open Graph (Facebook/LinkedIn)**: 1200x630 pixels (1.91:1 ratio)
- **Twitter Card (summary_large_image)**: 1200x630 pixels
- **Twitter Card (summary)**: 1200x600 pixels
- **File Size**: Under 8MB for most platforms
- **Format**: PNG, JPG, or WEBP

### Fallback System

The site uses a smart fallback system for social sharing images:

1. **Page-specific image**: `social_image` in front matter
2. **General page image**: `image` in front matter
3. **Site default image**: `social_image` in `_config.yml`
4. **Final fallback**: Apple touch icon

## Supported Platforms

### Open Graph (Facebook, LinkedIn, Pinterest)
- Title, description, URL, image
- Image dimensions and alt text
- Site name and locale
- Article-specific metadata for blog posts

### Twitter Cards
- Support for both `summary` and `summary_large_image`
- Twitter site and creator handles
- Mobile-optimized display

### Structured Data (Schema.org)
- JSON-LD format for search engines
- Different schemas for posts vs pages
- Breadcrumb navigation support
- Organization and website schemas

## Testing Your Implementation

### Facebook Debugger
https://developers.facebook.com/tools/debug/

### Twitter Card Validator
https://cards-dev.twitter.com/validator

### LinkedIn Post Inspector
https://www.linkedin.com/post-inspector/

### Rich Results Test (Google)
https://search.google.com/test/rich-results

## Best Practices

1. **Always include a compelling description** (150-160 characters for OG, 200 for Twitter)
2. **Use high-quality, relevant images** that represent your content
3. **Test your URLs** on each platform before publishing
4. **Update Twitter username** in config for proper attribution
5. **Consider creating custom social images** for important posts
6. **Use descriptive alt text** for accessibility and context

## Example Usage

### Blog Post with Custom Social Image
```yaml
---
title: "Advanced AI Integration Patterns"
description: "Exploring cutting-edge patterns for integrating AI systems into existing workflows"
layout: "post"
social_image: "/images/ai-integration-social.jpg"
social_image_alt: "Diagram showing AI integration patterns"
twitter_card: "summary_large_image"
author_twitter: "@researchteam"
date: 2024-01-15
tags: ["AI", "Integration", "Patterns"]
category: "Technical Analysis"
---
```

### Simple Page with Defaults
```yaml
---
title: "About Our Research"
description: "Learn about our AI-powered research methodology"
---
```

This will use all the site defaults while still providing proper social sharing functionality.