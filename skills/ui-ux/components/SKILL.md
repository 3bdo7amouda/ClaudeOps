# skill: ui-ux/components
# triggers: ui component, button, form, modal, table, card, layout, nav, sidebar

## Layout Primitives
```tsx
// Stack — vertical spacing
<Stack gap={4}>{children}</Stack>

// Cluster — horizontal wrapping
<Cluster gap={2}>{children}</Cluster>

// Grid — responsive columns
<Grid cols={{ base: 1, md: 2, lg: 3 }}>{children}</Grid>

// Center — both axes
<Center minHeight="100vh">{children}</Center>
```

## Modal Pattern
```tsx
export function Modal({ isOpen, onClose, title, children }: ModalProps) {
  if (!isOpen) return null
  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black/50" onClick={onClose} aria-hidden />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="modal-title"
        className="relative bg-white rounded-lg shadow-xl max-w-lg w-full mx-4 p-6"
      >
        <h2 id="modal-title" className="text-lg font-semibold">{title}</h2>
        {children}
        <button onClick={onClose} className="absolute top-4 right-4" aria-label="Close">✕</button>
      </div>
    </div>,
    document.body
  )
}
```

## Form Field Pattern
```tsx
export function Field({ label, error, required, children }: FieldProps) {
  const id = useId()
  const errorId = `${id}-error`
  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={id} className="text-sm font-medium">
        {label} {required && <span aria-hidden>*</span>}
      </label>
      {cloneElement(children, {
        id,
        'aria-describedby': error ? errorId : undefined,
        'aria-invalid': !!error,
      })}
      {error && (
        <span id={errorId} role="alert" className="text-sm text-red-600">{error}</span>
      )}
    </div>
  )
}
```

## From: claudedesignskills (modern-web-design)
Micro-interaction standards:
- Button press: `scale(0.95)` on tap, spring back on release
- Hover lift: `translateY(-2px)` + shadow increase
- Toggle: spring physics (stiffness: 400, damping: 17) — never linear
- Form validation: immediate + kind feedback, green on success

```tsx
// Button with micro-interaction (Framer Motion)
<motion.button
  whileHover={{ scale: 1.05, y: -2 }}
  whileTap={{ scale: 0.95 }}
  transition={{ type: "spring", stiffness: 400, damping: 17 }}
>
  {label}
</motion.button>
```
