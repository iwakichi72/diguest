import { getConfig } from './config'
import type { Message } from '@/types'

export class OllamaError extends Error {}

export async function streamChat(messages: Message[]): Promise<ReadableStream<Uint8Array>> {
  const { ollamaBaseUrl, ollamaModel } = getConfig()

  let response: Response
  try {
    response = await fetch(`${ollamaBaseUrl}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: ollamaModel, messages, stream: true }),
    })
  } catch {
    throw new OllamaError('Ollamaに接続できません')
  }

  if (!response.ok || !response.body) {
    throw new OllamaError('Ollamaに接続できません')
  }

  return response.body
}

export async function generateText(messages: Message[]): Promise<string> {
  const { ollamaBaseUrl, ollamaModel } = getConfig()

  let response: Response
  try {
    response = await fetch(`${ollamaBaseUrl}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: ollamaModel, messages, stream: false }),
    })
  } catch {
    throw new OllamaError('Ollamaに接続できません')
  }

  if (!response.ok) {
    throw new OllamaError('Ollamaに接続できません')
  }

  const data = await response.json()
  return data.message?.content ?? ''
}

export async function checkConnection(): Promise<boolean> {
  const { ollamaBaseUrl } = getConfig()
  try {
    const res = await fetch(`${ollamaBaseUrl}/api/tags`, {
      signal: AbortSignal.timeout(3000),
    })
    return res.ok
  } catch {
    return false
  }
}
