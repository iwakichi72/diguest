'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import DigText from '@/components/DigText'

export default function NewSession() {
  const [theme, setTheme] = useState('')
  const [digging, setDigging] = useState(false)
  const router = useRouter()

  function startDigging() {
    const t = theme.trim()
    if (!t || digging) return
    setTheme(t)
    setDigging(true)
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    startDigging()
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      startDigging()
    }
  }

  function handleDigComplete() {
    router.push(`/session?theme=${encodeURIComponent(theme.trim())}`)
  }

  useEffect(() => {
    if (theme.trim()) {
      router.prefetch(`/session?theme=${encodeURIComponent(theme.trim())}`)
    }
  }, [theme, router])

  return (
    <main className="min-h-screen bg-bg-base flex flex-col">
      <div className="max-w-content mx-auto w-full px-6 py-10">
        <Link
          href="/"
          className={`font-ui text-sm text-text-muted hover:text-text-secondary transition-colors ${digging ? 'pointer-events-none opacity-40' : ''}`}
          aria-disabled={digging}
        >
          ← 戻る
        </Link>
      </div>

      <div className="flex-1 flex items-center justify-center px-6">
        <form onSubmit={handleSubmit} className="w-full max-w-content" aria-busy={digging}>
          <p className="font-reading text-xl text-text-primary mb-8">
            今日、何を掘りますか？
          </p>

          {digging ? (
            <div
              className="w-full bg-bg-surface border border-border rounded px-5 py-4 font-reading text-lg text-text-primary leading-[1.9] min-h-[8.6rem] whitespace-pre-wrap break-words"
              role="status"
              aria-live="polite"
            >
              <DigText text={theme} active onComplete={handleDigComplete} />
            </div>
          ) : (
            <textarea
              autoFocus
              value={theme}
              onChange={e => setTheme(e.target.value)}
              onKeyDown={handleKeyDown}
              rows={3}
              placeholder="最近の違和感、問い、テーマ…"
              className="w-full bg-bg-surface border border-border rounded px-5 py-4 font-reading text-lg text-text-primary leading-[1.9] resize-none focus:border-border-focus focus:outline-none placeholder-text-muted"
            />
          )}

          <p
            className={`font-ui text-sm text-text-muted mt-3 mb-8 ${digging ? 'invisible' : ''}`}
            aria-hidden={digging}
          >
            一言でも、問いの形でも。
          </p>

          <button
            type="submit"
            disabled={!theme.trim() || digging}
            aria-busy={digging}
            className={`font-ui text-sm text-text-secondary border border-border rounded px-6 py-3 hover:text-text-primary hover:border-border-focus transition-colors disabled:opacity-30 disabled:cursor-default ${digging ? 'invisible' : ''}`}
          >
            掘り始める →
          </button>
        </form>
      </div>
    </main>
  )
}
