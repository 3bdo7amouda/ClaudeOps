# skill: ui-ux/prototyping
# triggers: prototype, wireframe, mockup, figma, rapid, lo-fi, hi-fi, user flow

## Lo-fi HTML Wireframe Template
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: sans-serif; }
    .wire { background: #e5e7eb; border: 2px dashed #9ca3af; border-radius: 4px; }
    .label { font-size: 11px; color: #6b7280; text-align: center; padding: 8px; }
    body { padding: 2rem; background: #f9fafb; }
    .flow { display: flex; gap: 1rem; flex-wrap: wrap; }
  </style>
</head>
<body>
  <div style="height:60px;margin-bottom:1rem" class="wire">
    <div class="label">NAV</div>
  </div>
  <div class="flow">
    <div style="flex:1;min-width:200px;height:400px" class="wire">
      <div class="label">MAIN CONTENT</div>
    </div>
    <div style="width:250px;height:400px" class="wire">
      <div class="label">SIDEBAR</div>
    </div>
  </div>
</body>
</html>
```

## User Flow Checklist
Before building any screen, define:
- [ ] Entry point (how does user get here?)
- [ ] Primary action (what should they do?)
- [ ] Success state (what happens after?)
- [ ] Error state (what if it fails?)
- [ ] Empty state (what if there's no data?)

## From: superpowers (writing-plans)
Before any multi-screen prototype, map file structure first:
- Which screens/pages will be created or modified?
- What's each component's single responsibility?
- What shared components need to exist?

Lock decomposition before building. Scope check: if prototype covers multiple independent flows, split into sub-prototypes — one per flow, each testable independently.

## Rapid Prototyping Stack
```bash
# React prototype (Vite)
npm create vite@latest proto -- --template react-ts
cd proto && npm install && npm run dev

# Add UI: shadcn/ui
npx shadcn@latest init
npx shadcn@latest add button card input form

# Add routing
npm install react-router-dom

# Mock data
npm install @faker-js/faker
```

## Figma → Code Handoff Checklist
- [ ] Design tokens exported (colors, spacing, typography)
- [ ] Component variants documented with props
- [ ] Responsive breakpoints specified
- [ ] Interactive states: default, hover, active, disabled, loading, error
- [ ] Motion/animation spec: duration, easing, triggers
- [ ] Accessibility notes: alt text, ARIA roles, keyboard flow
