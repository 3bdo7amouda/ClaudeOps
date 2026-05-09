# skill: frontend/react
# triggers: react, component, hook, state, vite, jsx, tsx, nextjs, remix

## Component Structure
```typescript
interface ButtonProps {
  label: string
  onClick: () => void
  variant?: 'primary' | 'secondary' | 'ghost'
  disabled?: boolean
  isLoading?: boolean
}

export function Button({ label, onClick, variant = 'primary', disabled, isLoading }: ButtonProps) {
  return (
    <button
      className={buttonVariants({ variant })}
      onClick={onClick}
      disabled={disabled || isLoading}
      aria-busy={isLoading}
    >
      {isLoading ? <Spinner /> : label}
    </button>
  )
}
```

## Data Fetching (React Query)
```typescript
export function useUser(id: string) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: () => api.getUser(id),
    staleTime: 5 * 60 * 1000,
  })
}

export function useUpdateUser() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: api.updateUser,
    onSuccess: (data) => qc.setQueryData(['user', data.id], data),
  })
}
```

## Form Pattern (React Hook Form + Zod)
```typescript
const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
})

export function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(schema)
  })
  const onSubmit = (data: z.infer<typeof schema>) => { /* ... */ }
  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}
    </form>
  )
}
```

## Custom Hook Pattern
```typescript
export function useDebounce<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState(value)
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay)
    return () => clearTimeout(timer)
  }, [value, delay])
  return debounced
}
```

## Rules
- TypeScript strict mode always
- No `any` — use `unknown` + type guards
- Components <150 lines — split if larger
- Co-locate: component, test, styles in same dir
- Memoize expensive computations with `useMemo`, callbacks with `useCallback`
- Avoid prop drilling beyond 2 levels — use context or state management

## From: claudedesignskills (animated-component-libraries)
```bash
# Magic UI install pattern
npx shadcn@latest add https://magicui.design/r/<component-name>
# Manual: copy to components/ui/, install motion, add cn() utility
```
Prefer pre-built animated components (Magic UI, React Bits) over hand-crafting animations for common UI patterns (buttons, cards, modals). Only animate with Framer Motion directly when custom animation logic is needed.
