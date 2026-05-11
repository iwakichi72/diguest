import { getConfig } from '@/lib/config'

export async function GET() {
  const { notesDir } = getConfig()
  return Response.json({ notesDir })
}
