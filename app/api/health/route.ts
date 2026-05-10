import { checkConnection } from '@/lib/ollama'

export async function GET() {
  const ok = await checkConnection()
  if (!ok) {
    return Response.json({ error: 'Ollama が起動していません' }, { status: 503 })
  }
  return Response.json({ ok: true })
}
