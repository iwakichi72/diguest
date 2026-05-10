import { SYSTEM_PROMPT } from '@/lib/prompts'
import { streamChat, OllamaError } from '@/lib/ollama'
import type { Message } from '@/types'

export async function POST(request: Request) {
  let messages: Message[]
  try {
    const body = await request.json()
    if (!Array.isArray(body.messages)) throw new Error()
    messages = body.messages
  } catch {
    return Response.json({ error: 'Invalid request' }, { status: 400 })
  }

  const withSystem: Message[] = [
    { role: 'system', content: SYSTEM_PROMPT },
    ...messages.filter(m => m.role !== 'system'),
  ]

  try {
    const stream = await streamChat(withSystem)
    return new Response(stream, {
      headers: { 'Content-Type': 'application/x-ndjson; charset=utf-8' },
    })
  } catch (error) {
    if (error instanceof OllamaError) {
      return Response.json({ error: 'Ollama が起動していません' }, { status: 503 })
    }
    return Response.json({ error: 'エラーが発生しました' }, { status: 500 })
  }
}
