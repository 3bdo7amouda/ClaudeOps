# skill: frontend/design-system
# triggers: design system, tokens, theme, typography, tailwind, colors, spacing

## Token Structure (CSS Variables)
```css
:root {
  /* Colors */
  --color-primary-50: #eff6ff;
  --color-primary-500: #3b82f6;
  --color-primary-900: #1e3a8a;

  /* Spacing (4px base) */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-4: 1rem;
  --space-8: 2rem;

  /* Typography */
  --font-sans: 'Inter', system-ui, sans-serif;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;

  /* Radius */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
}
```

## Tailwind Config Extension
```javascript
export default {
  theme: {
    extend: {
      colors: {
        brand: { 50: '#eff6ff', 500: '#3b82f6', 900: '#1e3a8a' }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      }
    }
  }
}
```

## Component Variants (cva pattern)
```typescript
import { cva } from 'class-variance-authority'

const button = cva('inline-flex items-center font-medium rounded-md transition-colors', {
  variants: {
    variant: {
      primary: 'bg-brand-500 text-white hover:bg-brand-600',
      secondary: 'bg-white border border-gray-300 hover:bg-gray-50',
      ghost: 'text-gray-700 hover:bg-gray-100',
    },
    size: {
      sm: 'text-sm px-3 py-1.5',
      md: 'text-base px-4 py-2',
      lg: 'text-lg px-6 py-3',
    }
  },
  defaultVariants: { variant: 'primary', size: 'md' }
})
```

## Fluid Typography (modern-web-design pattern)
```css
/* Fluid typography using clamp() — scales between viewport sizes */
--font-size-sm:   clamp(0.875rem, 0.8rem + 0.375vw, 1rem);
--font-size-base: clamp(1rem, 0.9rem + 0.5vw, 1.25rem);
--font-size-lg:   clamp(1.25rem, 1.1rem + 0.75vw, 1.75rem);
--font-size-xl:   clamp(1.75rem, 1.5rem + 1.25vw, 2.5rem);
--font-size-2xl:  clamp(2.5rem, 2rem + 2.5vw, 4rem);
--font-size-3xl:  clamp(3.5rem, 2.5rem + 5vw, 6rem);
```

## Color System (WCAG AAA)
```css
/* Use oklch for perceptually uniform colors */
--color-primary: oklch(50% 0.2 250);   /* Blue */
--color-accent:  oklch(65% 0.25 30);   /* Coral */
--color-neutral-50:  oklch(98% 0 0);
--color-neutral-900: oklch(20% 0 0);
/* Minimum 7:1 contrast ratio for body text (WCAG AAA) */
/* Minimum 4.5:1 for large text (WCAG AA) */
```

## Rules
- 4px base unit (0.25rem increments)
- Never hardcode hex in components — always use tokens
- Dark mode: use CSS variables with `[data-theme="dark"]` override
- Export tokens as JSON for cross-platform use (Figma → code)
