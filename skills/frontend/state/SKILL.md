# skill: frontend/state
# triggers: state management, zustand, redux, context, global state, client state, store

## State Categories — Pick the Right Tool
```
Server state (async, cached):  React Query / SWR
Form state:                    React Hook Form
URL state:                     useSearchParams / nuqs
Local UI state:                useState / useReducer
Global client state:           Zustand (minimal, no boilerplate)
Complex client state:          Zustand + immer
```

## Zustand — Recommended
```typescript
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { persist, createJSONStorage } from 'zustand/middleware'

interface NotificationStore {
  notifications: Notification[]
  unreadCount: number
  add: (n: Omit<Notification, 'id' | 'read'>) => void
  markRead: (id: string) => void
  markAllRead: () => void
  clear: () => void
}

export const useNotifications = create<NotificationStore>()(
  immer((set) => ({
    notifications: [],
    unreadCount: 0,

    add: (n) => set((state) => {
      state.notifications.unshift({ ...n, id: crypto.randomUUID(), read: false })
      state.unreadCount++
    }),

    markRead: (id) => set((state) => {
      const n = state.notifications.find(n => n.id === id)
      if (n && !n.read) { n.read = true; state.unreadCount-- }
    }),

    markAllRead: (s) => set((state) => {
      state.notifications.forEach(n => { n.read = true })
      state.unreadCount = 0
    }),

    clear: () => set({ notifications: [], unreadCount: 0 }),
  }))
)

// Persisted store (survives page reload)
export const usePreferences = create<PrefsStore>()(
  persist(
    immer((set) => ({
      theme: 'system' as 'light' | 'dark' | 'system',
      sidebarCollapsed: false,
      setTheme: (theme) => set(state => { state.theme = theme }),
      toggleSidebar: () => set(state => { state.sidebarCollapsed = !state.sidebarCollapsed }),
    })),
    { name: 'user-prefs', storage: createJSONStorage(() => localStorage) }
  )
)
```

## Slice Pattern (large stores)
```typescript
// Separate files, compose into root store
// stores/slices/authSlice.ts
export interface AuthSlice {
  user: User | null
  setUser: (user: User | null) => void
  logout: () => void
}
export const createAuthSlice = (set: any): AuthSlice => ({
  user: null,
  setUser: (user) => set({ user }),
  logout: () => set({ user: null }),
})

// stores/root.ts
export const useStore = create<AuthSlice & UISlice>()(
  immer((...a) => ({
    ...createAuthSlice(...a),
    ...createUISlice(...a),
  }))
)
```

## Selector Pattern (prevent unnecessary re-renders)
```typescript
// Bad — re-renders on any store change
const { user, notifications } = useStore()

// Good — re-render only when this field changes
const user = useStore(state => state.user)
const unreadCount = useNotifications(state => state.unreadCount)

// Computed value
const isAdmin = useStore(state => state.user?.role === 'admin')
```

## URL State (shareable, bookmarkable)
```typescript
import { useQueryState } from 'nuqs'

// Replaces useState for values that should survive navigation
const [search, setSearch] = useQueryState('q', { defaultValue: '' })
const [page, setPage]     = useQueryState('page', { defaultValue: 1, parse: Number })
const [sort, setSort]     = useQueryState('sort', { defaultValue: 'newest' })
// → URL: /products?q=laptop&page=2&sort=price
```

## Rules
- Server state (API data) → React Query, never Zustand
- URL state (filters, pagination, tabs) → useSearchParams / nuqs
- Form state → React Hook Form, never global store
- Only put in Zustand what's genuinely global: auth user, notifications, UI prefs
- Use `immer` middleware for nested state mutations
- Use selectors to avoid unnecessary re-renders
