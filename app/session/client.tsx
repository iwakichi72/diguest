'use client'

import { useSearchParams, useRouter } from 'next/navigation'
import { useState, useRef, useEffect, useCallback } from 'react'
import { useSession } from '@/hooks/useSession'
import { useStreamingChat } from '@/hooks/useStreamingChat'
import DialogueTurn from '@/components/DialogueTurn'
import MarkdownPreview from '@/components/MarkdownPreview'
import StreamingCursor from '@/components/StreamingCursor'
import DigOverlay from '@/components/DigOverlay'

export default function SessionClient() {
  const searchParams = useSearchParams()
  const router = useRouter()
  const theme = searchParams.get('theme') ?? ''

  const startedAt = useRef(new Date().toISOString())
  const [input, setInput] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isCheckingConnection, setIsCheckingConnection] = useState(false)
  const [savingPhase, setSavingPhase] = useState<null | 'generating' | 'preview' | 'saving'>(null)
  const [previewData, setPreviewData] = useState<{ markdown: string; fileName: string } | null>(null)
  const [saveDir, setSaveDir] = useState('')
  const bottomRef = useRef<HTMLDivElement>(null)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const { state, addUser, startAssistant, appendChunk, finalize, removeLastAssistant } = useSession(theme, '')
  const { isStreaming, send } = useStreamingChat()

  const isBusy = isStreaming || savingPhase !== null
  const turnCount = state.messages.filter(m => m.role === 'user').length

  useEffect(() => {
    if (!theme) router.replace('/session/new')
  }, [theme, router])

  const retryConnection = useCallback(async () => {
    setIsCheckingConnection(true)
    try {
      const response = await fetch('/api/health')
      if (response.ok) {
        setError(null)
        return
      }

      const data = await response.json().catch(() => ({}))
      setError(data.error ?? 'Ollamaが見つかりません')
    } catch {
      setError('Ollamaが見つかりません')
    } finally {
      setIsCheckingConnection(false)
    }
  }, [])

  useEffect(() => {
    fetch('/api/config').then(r => r.json()).then(data => {
      if (data.notesDir) setSaveDir(data.notesDir)
    }).catch(() => {})
  }, [])

  useEffect(() => {
    if (!theme) return

    fetch('/api/health').then(async response => {
      if (response.ok) {
        setError(null)
        return
      }

      const data = await response.json().catch(() => ({}))
      setError(data.error ?? 'Ollamaが見つかりません')
    }).catch(() => setError('Ollamaが見つかりません'))
  }, [theme])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [state.messages])

  function resizeTextarea() {
    const el = textareaRef.current
    if (!el) return
    el.style.height = 'auto'
    el.style.height = Math.min(el.scrollHeight, 144) + 'px'
  }

  function handleChange(e: React.ChangeEvent<HTMLTextAreaElement>) {
    setInput(e.target.value)
    resizeTextarea()
  }

  const handleSubmit = useCallback(async () => {
    const content = input.trim()
    if (!content || isBusy) return

    setInput('')
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto'
    }
    setError(null)

    addUser(content)
    startAssistant()

    const nextMessages = [
      ...state.messages,
      { role: 'user' as const, content },
    ]

    await send(
      nextMessages,
      appendChunk,
      finalize,
      msg => {
        removeLastAssistant()
        setError(msg)
      }
    )
  }, [input, isBusy, state.messages, addUser, startAssistant, appendChunk, finalize, removeLastAssistant, send])

  function handleKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSubmit()
    }
  }

  async function handleEnd() {
    if (state.messages.length === 0) {
      router.push('/')
      return
    }

    setSavingPhase('generating')
    setError(null)

    try {
      const genRes = await fetch('/api/generate-markdown', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          theme,
          messages: state.messages,
          startedAt: startedAt.current,
        }),
      })

      if (!genRes.ok) throw new Error('生成に失敗しました')
      const { markdown, fileName } = await genRes.json()
      setPreviewData({ markdown, fileName })
      setSavingPhase('preview')
    } catch (err) {
      setError(err instanceof Error ? err.message : '生成できませんでした')
      setSavingPhase(null)
    }
  }

  async function handleSave() {
    if (!previewData) return

    setSavingPhase('saving')
    setError(null)

    try {
      const saveRes = await fetch('/api/save-markdown', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ markdown: previewData.markdown, fileName: previewData.fileName, saveDir: saveDir || undefined }),
      })

      if (!saveRes.ok) throw new Error('保存に失敗しました')
      const { fileName: savedFileName } = await saveRes.json()
      router.push(`/notes/${encodeURIComponent(savedFileName)}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : '保存できませんでした')
      setSavingPhase('preview')
    }
  }

  if (!theme) return null

  const lastIdx = state.messages.length - 1

  return (
    <div className="min-h-screen bg-bg-base flex flex-col">
      {savingPhase === 'generating' && <DigOverlay />}
      {(savingPhase === 'preview' || savingPhase === 'saving') && previewData && (
        <MarkdownPreview
          markdown={previewData.markdown}
          isSaving={savingPhase === 'saving'}
          saveDir={saveDir}
          onSaveDirChange={setSaveDir}
          onSave={handleSave}
          onCancel={() => setSavingPhase(null)}
        />
      )}
      {/* Header */}
      <header className="sticky top-0 z-10 bg-bg-base border-b border-border">
        <div className="max-w-content mx-auto px-6 py-4 flex items-center justify-between gap-4">
          <span className="font-reading text-sm text-text-secondary truncate">{theme}</span>
          <button
            onClick={handleEnd}
            disabled={isBusy}
            aria-busy={isBusy}
            className="font-ui text-sm text-text-muted hover:text-text-secondary transition-colors shrink-0 disabled:opacity-40"
          >
            {savingPhase === 'generating' ? 'まとめています…' : 'ここで終える'}
          </button>
        </div>
      </header>

      {/* Dialogue */}
      <main className="flex-1 max-w-content mx-auto w-full px-6 pt-16 pb-6">
        {state.messages.map((msg, i) => {
          if (msg.role === 'system') return null
          const isLast = i === lastIdx
          return (
            <DialogueTurn
              key={i}
              role={msg.role}
              content={msg.content}
              isStreaming={isStreaming && isLast && msg.role === 'assistant'}
            />
          )
        })}

        {/* カーソルのみ（最初のターン待機中） */}
        {isStreaming && state.messages.length > 0 &&
          state.messages[lastIdx]?.role === 'assistant' &&
          state.messages[lastIdx].content === '' && (
            <div className="my-10 border-t border-dashed border-border pt-6">
              <StreamingCursor />
            </div>
          )}

        {error && (
          <div className="mt-4">
            <p className="font-ui text-sm text-error">{error}</p>
            {error.includes('Ollama') && (
              <button
                type="button"
                onClick={retryConnection}
                disabled={isCheckingConnection}
                className="font-ui text-xs text-text-muted mt-3 hover:text-text-secondary transition-colors disabled:opacity-40"
              >
                {isCheckingConnection ? '確認しています…' : 'もう一度試す'}
              </button>
            )}
          </div>
        )}
        <div ref={bottomRef} />
      </main>

      {/* Input */}
      <footer className="sticky bottom-0 bg-bg-base border-t border-border">
        <div className="max-w-content mx-auto px-6 py-4 group">
          <textarea
            ref={textareaRef}
            value={input}
            onChange={handleChange}
            onKeyDown={handleKeyDown}
            disabled={isBusy}
            aria-busy={isBusy}
            rows={3}
            className={`w-full bg-bg-surface border border-border rounded px-5 py-4 font-reading text-lg text-text-primary leading-[1.9] resize-none focus:border-border-focus focus:outline-none disabled:opacity-40 placeholder-text-muted ${isBusy ? 'dig-shimmer' : ''}`}
            placeholder="…"
          />
          <div className="flex justify-between items-center mt-2">
            <span className="font-ui text-xs text-text-muted opacity-0 group-focus-within:opacity-100 transition-opacity duration-200">
              Shift+Enter で改行 · Enter で送信
            </span>
            {turnCount > 0 && (
              <span className="font-ui text-xs text-text-muted">
                · {turnCount}
              </span>
            )}
          </div>
        </div>
      </footer>
    </div>
  )
}
