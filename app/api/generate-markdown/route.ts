import { buildSummaryPrompt } from '@/lib/prompts'
import { generateText, OllamaError } from '@/lib/ollama'
import { buildMarkdown, buildFileName } from '@/lib/markdown'
import { getConfig } from '@/lib/config'
import { hasAdvisoryLanguage, removeAdvisoryItems } from '@/lib/responseGuard'
import type { Message } from '@/types'

export async function POST(request: Request) {
  let theme: string, messages: Message[], startedAt: string
  try {
    const body = await request.json()
    theme = String(body.theme || '')
    messages = body.messages
    startedAt = String(body.startedAt || new Date().toISOString())
    if (!Array.isArray(messages)) throw new Error()
  } catch {
    return Response.json({ error: 'Invalid request' }, { status: 400 })
  }

  const { ollamaModel } = getConfig()

  const log = messages
    .filter(m => m.role !== 'system')
    .map(m => `${m.role === 'user' ? 'You' : 'Diguest'}: ${m.content}`)
    .join('\n\n')

  let summary = ''
  let surfaced: string[] = []

  try {
    const raw = await generateText([
      { role: 'user', content: buildSummaryPrompt(theme, log) },
    ])
    // C-3: JSON抽出 + パース失敗時はフォールバック
    const jsonMatch = raw.match(/\{[\s\S]*\}/)
    if (jsonMatch) {
      try {
        const parsed = JSON.parse(jsonMatch[0])
        const parsedSummary = typeof parsed.summary === 'string' ? parsed.summary : ''
        summary = hasAdvisoryLanguage(parsedSummary) ? '' : parsedSummary
        surfaced = Array.isArray(parsed.surfaced)
          ? removeAdvisoryItems(
              parsed.surfaced.filter((s: unknown): s is string => typeof s === 'string')
            )
          : []
      } catch {
        // JSON parse failed — use empty values and continue
      }
    }
  } catch (error) {
    if (!(error instanceof OllamaError)) {
      return Response.json({ error: 'エラーが発生しました' }, { status: 500 })
    }
    // Ollama error — save log only (C-3 fallback)
  }

  const start = new Date(startedAt)
  const fileName = buildFileName(theme, start)
  const markdown = buildMarkdown({
    theme,
    messages: messages.filter(m => m.role !== 'system'),
    model: ollamaModel,
    startedAt: start,
    summary,
    surfaced,
  })

  return Response.json({ markdown, fileName })
}
