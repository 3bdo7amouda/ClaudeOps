# skill: ui-ux/motion
# triggers: animation, motion, transition, framer motion, css animation, enter, exit

## Framer Motion — Common Patterns
```tsx
// Fade in on mount
const fadeIn = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: 8 },
  transition: { duration: 0.2 }
}
<motion.div {...fadeIn}>{content}</motion.div>

// Staggered list
const container = { animate: { transition: { staggerChildren: 0.05 } } }
const item = { initial: { opacity: 0, x: -10 }, animate: { opacity: 1, x: 0 } }
<motion.ul variants={container} animate="animate">
  {items.map(i => <motion.li variants={item}>{i.label}</motion.li>)}
</motion.ul>

// Layout animation (auto-animates size changes)
<motion.div layout>{expanded ? <Content /> : null}</motion.div>

// Shared element transition
<motion.div layoutId="card-thumbnail" />  // same layoutId = shared transition
```

## From: claudedesignskills (motion-framer)
```tsx
// Gesture-based interactions
<motion.div
  whileHover={{ scale: 1.05, y: -2 }}
  whileTap={{ scale: 0.95 }}
  drag="x"
  dragConstraints={{ left: -100, right: 100 }}
  transition={{ type: "spring", stiffness: 300, damping: 20 }}
/>

// Spring vs duration — prefer spring for physical feel
// Spring: { type: "spring", stiffness: 300, damping: 20 }
// Duration: { duration: 0.2, ease: "easeInOut" }

// AnimatePresence for exit animations (required for unmount animations)
<AnimatePresence>
  {isVisible && (
    <motion.div
      key="content"
      initial={{ opacity: 0, height: 0 }}
      animate={{ opacity: 1, height: "auto" }}
      exit={{ opacity: 0, height: 0 }}
    />
  )}
</AnimatePresence>

// Scroll-linked animation
const { scrollYProgress } = useScroll()
const opacity = useTransform(scrollYProgress, [0, 0.3], [0, 1])
<motion.div style={{ opacity }} />
```

## CSS Transitions — Utility Classes
```css
.transition-base { transition: all 150ms ease; }
.transition-slow  { transition: all 300ms ease; }

/* GPU composited — use these, not height/top */
.hover-lift:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
```

## Rules
- Prefer `opacity` + `transform` (GPU) over `height`/`top` (layout reflow)
- Keep enter/exit animations under 300ms
- Respect `prefers-reduced-motion` (always)
- Use spring physics for interactive elements, duration for decorative

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Animation Decision Tree
```
Needs to animate on user interaction? → Spring physics
Needs to animate on scroll? → useScroll + useTransform
Needs enter/exit? → AnimatePresence
List reordering? → layout prop + AnimatePresence
Decorative/ambient? → duration-based, 200-300ms max
```
