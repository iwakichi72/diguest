import { saveNote } from '@/lib/markdown'

export async function POST(request: Request) {
  let markdown: string, fileName: string
  try {
    const body = await request.json()
    markdown = String(body.markdown || '')
    fileName = String(body.fileName || '')
    if (!markdown || !fileName) throw new Error()
  } catch {
    return Response.json({ error: 'Invalid request' }, { status: 400 })
  }

  try {
    const { filePath, fileName: savedFileName } = await saveNote(markdown, fileName)
    return Response.json({ saved: true, fileName: savedFileName, filePath })
  } catch (error) {
    const msg = error instanceof Error ? error.message : ''
    if (msg === 'Invalid file path' || msg === 'Invalid file name') {
      return Response.json({ error: 'Invalid file name' }, { status: 400 })
    }
    return Response.json({ error: '保存できませんでした' }, { status: 500 })
  }
}
