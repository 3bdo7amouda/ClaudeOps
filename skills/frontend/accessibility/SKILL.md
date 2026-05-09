# skill: frontend/accessibility
# triggers: a11y, accessibility, aria, wcag, screen reader, keyboard, focus

## ARIA Patterns
```html
<!-- Button with loading state -->
<button aria-busy="true" aria-disabled="true">
  <span aria-hidden="true">⟳</span> Loading...
</button>

<!-- Live region for dynamic updates -->
<div role="status" aria-live="polite" aria-atomic="true">
  {statusMessage}
</div>

<!-- Dialog -->
<div role="dialog" aria-modal="true" aria-labelledby="title" aria-describedby="desc">
  <h2 id="title">Confirm Action</h2>
  <p id="desc">This cannot be undone.</p>
</div>
```

## Focus Management
```typescript
// Trap focus in modal
useEffect(() => {
  const modal = ref.current
  const focusable = modal.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  )
  const first = focusable[0] as HTMLElement
  const last = focusable[focusable.length - 1] as HTMLElement

  first?.focus()

  const handler = (e: KeyboardEvent) => {
    if (e.key === 'Escape') { onClose(); return }
    if (e.key !== 'Tab') return
    if (e.shiftKey ? document.activeElement === first : document.activeElement === last) {
      e.preventDefault()
      ;(e.shiftKey ? last : first).focus()
    }
  }
  modal.addEventListener('keydown', handler)
  return () => modal.removeEventListener('keydown', handler)
}, [])
```

## Checklist
- [ ] All images have meaningful alt text (or `alt=""` if decorative)
- [ ] Color contrast ≥ 4.5:1 for text (3:1 for large text)
- [ ] All interactive elements keyboard reachable
- [ ] Focus indicator visible (never `outline: none` without replacement)
- [ ] Form inputs have labels (not just placeholders)
- [ ] Error messages linked to fields with `aria-describedby`
- [ ] Page has exactly one `<h1>`
- [ ] Skip-to-content link as first focusable element
- [ ] No content relies on color alone to convey meaning

## Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Skip Nav
```html
<a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-white p-2 z-50">
  Skip to main content
</a>
<main id="main-content" tabindex="-1">...</main>
```

## Screen Reader Only (Tailwind)
```css
.sr-only {
  position: absolute; width: 1px; height: 1px;
  padding: 0; margin: -1px; overflow: hidden;
  clip: rect(0,0,0,0); white-space: nowrap; border: 0;
}
```
