# skill: mobile/expo
# triggers: expo, react native, mobile, ios, android, eas, native, app store

## From: expo/building-native-ui + expo/expo-deployment (official Expo skills)

## Project Setup
```bash
npx create-expo-app@latest MyApp --template
cd MyApp
npx expo install expo-router expo-constants expo-linking

# Install NativeWind (Tailwind for React Native)
npx expo install nativewind tailwindcss
```

## Expo Router Structure
```
app/
├── _layout.tsx          ← root layout (auth guard here)
├── (auth)/
│   ├── login.tsx
│   └── register.tsx
├── (app)/
│   ├── _layout.tsx      ← tab navigator
│   ├── index.tsx        ← home tab
│   ├── profile.tsx
│   └── settings.tsx
└── +not-found.tsx
```

## Root Layout with Auth Guard
```tsx
// app/_layout.tsx
import { Stack, router } from 'expo-router'
import { useEffect } from 'react'
import { useAuth } from '@/hooks/useAuth'

export default function RootLayout() {
  const { user, loading } = useAuth()

  useEffect(() => {
    if (!loading) {
      if (user) router.replace('/(app)')
      else router.replace('/(auth)/login')
    }
  }, [user, loading])

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(auth)" />
      <Stack.Screen name="(app)" />
    </Stack>
  )
}
```

## Data Fetching (expo-compatible)
```typescript
// hooks/useQuery.ts — React Query works in Expo
import { QueryClient, QueryClientProvider, useQuery, useMutation } from '@tanstack/react-query'

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 60_000, retry: 2 } }
})

// Wrap app: <QueryClientProvider client={queryClient}>

export function useUser(id: string) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: () => api.getUser(id),
  })
}
```

## Secure Storage (tokens)
```typescript
import * as SecureStore from 'expo-secure-store'

export const tokenStorage = {
  get: (key: string) => SecureStore.getItemAsync(key),
  set: (key: string, value: string) => SecureStore.setItemAsync(key, value, {
    keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
  }),
  del: (key: string) => SecureStore.deleteItemAsync(key),
}

// Store auth token
await tokenStorage.set('access_token', token)
await tokenStorage.set('refresh_token', refreshToken)
```

## Push Notifications
```typescript
import * as Notifications from 'expo-notifications'
import * as Device from 'expo-device'

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true, shouldPlaySound: true, shouldSetBadge: true,
  }),
})

export async function registerForPushNotifications(): Promise<string | null> {
  if (!Device.isDevice) return null
  const { status } = await Notifications.requestPermissionsAsync()
  if (status !== 'granted') return null
  const token = (await Notifications.getExpoPushTokenAsync({
    projectId: process.env.EXPO_PROJECT_ID!,
  })).data
  return token
}
```

## EAS Build + Deploy
```bash
# Install EAS CLI
npm install -g eas-cli && eas login

# Initialize
eas build:configure

# Development build (install on device, faster iteration)
eas build --profile development --platform ios

# Production build
eas build --profile production --platform all

# Submit to stores
eas submit --platform ios
eas submit --platform android
```

## eas.json
```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal",
      "android": { "buildType": "apk" }
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {
      "ios": { "appleId": "you@example.com", "ascAppId": "1234567890" },
      "android": { "serviceAccountKeyPath": "./google-play-key.json" }
    }
  }
}
```

## OTA Updates (no app store review)
```bash
eas update --branch production --message "Fix login bug"
# Users get update on next app launch
```

## Rules
- Use `expo-secure-store` for tokens — never AsyncStorage for sensitive data
- Test on real device before EAS build — simulator misses native APIs
- `expo-router` > React Navigation for new projects (file-based routing)
- OTA updates for JS-only changes; EAS build for native changes
- Use `expo-constants` for env vars (`Constants.expoConfig?.extra`)
