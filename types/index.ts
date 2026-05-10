export type Role = 'user' | 'assistant' | 'system'

export type Message = {
  role: Role
  content: string
}

export type SessionState = {
  theme: string
  messages: Message[]
  isStreaming: boolean
  model: string
}

export type NoteMetadata = {
  fileName: string
  theme: string
  date: string
  model: string
  turns: number
}

export type NoteContent = {
  metadata: NoteMetadata
  rawMarkdown: string
}

export type AppConfig = {
  ollamaBaseUrl: string
  ollamaModel: string
  notesDir: string
}
