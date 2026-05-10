'use client'

import { useState, useCallback } from 'react'
import type { Message } from '@/types'

export function useStreamingChat() {
  const [isStreaming, setIsStreaming] = useState(false)

  const send = useCallback(
    async (
      messages: Message[],
      onChunk: (chunk: string) => void,
      onDone: () => void,
      onError: (msg: string) => void
    ) => {
      setIsStreaming(true)
      let buffer = ''

      try {
        const res = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ messages }),
        })

        if (!res.ok) {
          const data = await res.json().catch(() => ({}))
          onError(data.error ?? 'エラーが発生しました')
          return
        }

        const reader = res.body!.getReader()
        const decoder = new TextDecoder()

        outer: while (true) {
          const { done, value } = await reader.read()
          if (done) break

          buffer += decoder.decode(value, { stream: true })
          const lines = buffer.split('\n')
          buffer = lines.pop() ?? ''

          for (const line of lines) {
            if (!line.trim()) continue
            try {
              const parsed = JSON.parse(line)
              if (parsed.message?.content) onChunk(parsed.message.content)
              if (parsed.done) break outer
            } catch {
              // skip malformed ndjson line
            }
          }
        }

        onDone()
      } catch {
        onError('接続エラーが発生しました')
      } finally {
        setIsStreaming(false)
      }
    },
    []
  )

  return { isStreaming, send }
}
