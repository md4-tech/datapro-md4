'use client'

import { createContext, useContext, useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

type Theme = 'light' | 'dark' | 'system'

const FORCED_THEME: Theme | null = null

interface ThemeContextType {
  theme: Theme
  setTheme: (theme: Theme) => void
  isLoading: boolean
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined)
const SYSTEM_MEDIA_QUERY = '(prefers-color-scheme: dark)'

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<Theme>('light')
  const [isLoading, setIsLoading] = useState(true)
  const supabase = createClient()

  // Load theme on mount
  useEffect(() => {
    const loadTheme = async () => {
      try {
        if (FORCED_THEME) {
          setThemeState(FORCED_THEME)
          applyTheme(FORCED_THEME)
          return
        }
        const localTheme = localStorage.getItem('theme') as Theme | null
        if (localTheme === 'light' || localTheme === 'dark' || localTheme === 'system') {
          setThemeState(localTheme)
          applyTheme(localTheme)
          return
        }
        // Check if user is logged in
        const { data: { user } } = await supabase.auth.getUser()

        if (user) {
          // Load from database
          const { data: profile } = await supabase
            .from('user_profiles')
            .select('theme_preference')
            .eq('id', user.id)
            .single()

          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          if ((profile as any)?.theme_preference === 'light' || (profile as any)?.theme_preference === 'dark') {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            const savedTheme = (profile as any).theme_preference as Theme
            setThemeState(savedTheme)
            applyTheme(savedTheme)
          } else {
            // Use system preference if no saved preference
            setThemeState('system')
            applyTheme('system')
          }
        } else {
          // Not logged in - use localStorage or system preference
          setThemeState('system')
          applyTheme('system')
        }
      } catch (error) {
        console.error('Error loading theme:', error)
        // Fallback to system preference
        setThemeState('system')
        applyTheme('system')
      } finally {
        setIsLoading(false)
      }
    }

    loadTheme()
  }, [supabase])

  const applyTheme = (newTheme: Theme) => {
    const root = document.documentElement
    const resolvedTheme = newTheme === 'system'
      ? (window.matchMedia(SYSTEM_MEDIA_QUERY).matches ? 'dark' : 'light')
      : newTheme

    if (resolvedTheme === 'dark') {
      root.classList.add('dark')
    } else {
      root.classList.remove('dark')
    }
  }

  useEffect(() => {
    if (theme !== 'system') return
    const media = window.matchMedia(SYSTEM_MEDIA_QUERY)
    const handleChange = () => applyTheme('system')

    if (media.addEventListener) {
      media.addEventListener('change', handleChange)
      return () => media.removeEventListener('change', handleChange)
    }

    media.addListener(handleChange)
    return () => media.removeListener(handleChange)
  }, [theme])

  const setTheme = async (newTheme: Theme) => {
    if (FORCED_THEME) {
      setThemeState(FORCED_THEME)
      applyTheme(FORCED_THEME)
      return
    }
    setThemeState(newTheme)
    applyTheme(newTheme)
    localStorage.setItem('theme', newTheme)

    // Save to database if user is logged in
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (user && (newTheme === 'light' || newTheme === 'dark')) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const supabaseClient = supabase as any
        await supabaseClient
          .from('user_profiles')
          .update({ theme_preference: newTheme })
          .eq('id', user.id)
      }
    } catch (error) {
      console.error('Error saving theme preference:', error)
    }
  }

  return (
    <ThemeContext.Provider value={{ theme, setTheme, isLoading }}>
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme() {
  const context = useContext(ThemeContext)
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider')
  }
  return context
}
