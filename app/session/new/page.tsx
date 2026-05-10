'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'

export default function NewSession() {
  const [theme, setTheme] = useState('')
  const router = useRouter()

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const t = theme.trim()
    if (!t) return
    router.push(`/session?theme=${encodeURIComponent(t)}`)
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      const t = theme.trim()
      if (!t) return
      router.push(`/session?theme=${encodeURIComponent(t)}`)
    }
  }

  return (
    <main className="min-h-screen bg-bg-base flex flex-col">
      <div className="max-w-content mx-auto w-full px-6 py-10">
        <Link
          href="/"
          className="font-ui text-sm text-text-muted hover:text-text-secondary transition-colors"
        >
          ← 戻る
        </Link>
      </div>

      <div className="flex-1 flex items-center justify-center px-6">
        <form onSubmit={handleSubmit} className="w-full max-w-content">
          <p className="font-reading text-xl text-text-primary mb-8">
            今日、何を掘りますか？
          </p>

          <textarea
            autoFocus
            value={theme}
            onChange={e => setTheme(e.target.value)}
            onKeyDown={handleKeyDown}
            rows={3}
            placeholder="最近の違和感、問い、テーマ…"
            className="w-full bg-bg-surface border border-border rounded px-5 py-4 font-reading text-lg text-text-primary leading-[1.9] resize-none focus:border-border-focus focus:outline-none placeholder-text-muted"
          />

          <p className="font-ui text-sm text-text-muted mt-3 mb-8">
            一言でも、問いの形でも。
          </p>

          <button
            type="submit"
            disabled={!theme.trim()}
            className="font-ui text-sm text-text-secondary border border-border rounded px-6 py-3 hover:text-text-primary hover:border-border-focus transition-colors disabled:opacity-30 disabled:cursor-default"
          >
            掘り始める →
          </button>
        </form>
      </div>
    </main>
  )
}
