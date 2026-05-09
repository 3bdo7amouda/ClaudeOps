# skill: frontend/performance
# triggers: performance, lighthouse, bundle, lazy load, code split, web vitals, lcp, fid, cls

## Code Splitting
```typescript
// Route-level splitting
const Dashboard = lazy(() => import('./pages/Dashboard'))
const Settings = lazy(() => import('./pages/Settings'))

// Component-level (heavy libs)
const Chart = lazy(() => import('./components/Chart'))

// With suspense + error boundary
<ErrorBoundary>
  <Suspense fallback={<PageSkeleton />}>
    <Dashboard />
  </Suspense>
</ErrorBoundary>
```

## Image Optimization
```typescript
// Next.js
<Image src="/hero.jpg" alt="Hero" width={1200} height={600} priority />

// Vanilla — responsive + lazy
<img
  src="image-800w.jpg"
  srcSet="image-400w.jpg 400w, image-800w.jpg 800w, image-1200w.jpg 1200w"
  sizes="(max-width: 600px) 400px, (max-width: 1200px) 800px, 1200px"
  loading="lazy"
  decoding="async"
  alt="Description"
/>
```

## Bundle Analysis
```bash
npx vite-bundle-visualizer      # Vite
npx @next/bundle-analyzer       # Next.js
npx webpack-bundle-analyzer     # Webpack

# Check bundle size in CI
npx bundlesize --config .bundlesizerc.json
```

## Core Web Vitals Targets
| Metric | Good | Target |
|--------|------|--------|
| LCP | <2.5s | <1.5s |
| FID/INP | <100ms | <50ms |
| CLS | <0.1 | <0.05 |
| TTFB | <800ms | <200ms |

## Rules
- Preload critical fonts: `<link rel="preload" as="font" crossorigin>`
- Defer non-critical JS: `<script defer>`
- Cache static assets: `Cache-Control: max-age=31536000, immutable`
- Tree-shake: import named exports, not default objects
- Prefer `transform`/`opacity` animations (GPU composited, no layout reflow)

## From: claudedesignskills (modern-web-design)
```javascript
// Defer non-critical animations until after page load
window.addEventListener('load', () => {
  import('./animations').then(({ initAnimations }) => initAnimations())
})

// Progressive enhancement: core content without JS
<noscript>
  <style>.animated { opacity: 1 !important; transform: none !important; }</style>
</noscript>
```

## Skeleton Screen Pattern (better than spinners)
```tsx
export function UserCardSkeleton() {
  return (
    <div className="animate-pulse">
      <div className="h-12 w-12 rounded-full bg-gray-200" />
      <div className="mt-2 h-4 w-32 rounded bg-gray-200" />
      <div className="mt-1 h-3 w-24 rounded bg-gray-200" />
    </div>
  )
}
```
