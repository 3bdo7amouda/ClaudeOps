# skill: marketing/seo
# triggers: seo, meta, sitemap, keywords, organic, search, ranking, serp

## On-Page Checklist
```html
<title>Keyword — Brand Name | Supporting Context</title>
<meta name="description" content="Under 160 chars. Primary keyword near start. Action verb.">
<link rel="canonical" href="https://example.com/page/">

<!-- Open Graph -->
<meta property="og:title" content="...">
<meta property="og:description" content="...">
<meta property="og:image" content="https://example.com/og-1200x630.jpg">
```

## Technical SEO
```xml
<!-- sitemap.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2024-01-01</lastmod>
    <priority>1.0</priority>
  </url>
</urlset>
```

```
# robots.txt
User-agent: *
Allow: /
Disallow: /admin/
Sitemap: https://example.com/sitemap.xml
```

## Schema Markup (JSON-LD)
```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "App Name",
  "description": "...",
  "offers": { "@type": "Offer", "price": "0", "priceCurrency": "USD" }
}
</script>
```

## From: marketingskills (ai-seo)
AI SEO (AEO/GEO) — optimizing for AI answer engines:
```
Key difference: Traditional SEO = rank on page 1. AI SEO = get cited in answers.

Optimization checklist:
✓ Answer questions directly — first paragraph is the answer, not the intro
✓ Use FAQ structure — question as H2, answer immediately below
✓ Statistics + citations — boosts AI citation rate by 40%+
✓ Entity consistency — use your brand name the same way everywhere
✓ Third-party mentions — brands 6.5x more likely to be cited via third parties
✓ Structured data — FAQ, HowTo, Article schema
✓ Content freshness — AI prefers recent, updated content

Test AI visibility:
- Query ChatGPT, Perplexity, Google AI Overviews for your key queries
- Track: "Are we cited?", "Who is cited instead?"
- AI Overviews appear in ~45% of Google searches
```

## Content Rules
- One primary keyword + 2-3 semantic variants per page
- H1: once, contains primary keyword
- H2/H3: support semantic variants
- Internal links: 2-5 per page to related content
- Page speed: <2.5s LCP is ranking signal
