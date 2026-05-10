import fs from 'fs'
import path from 'path'
import os from 'os'
import type { AppConfig } from '@/types'

const DEFAULT_NOTES_DIR = path.join(os.homedir(), 'diguest')

function loadRuntimeConfig(): Partial<AppConfig> {
  const dir = process.env.NOTES_DIR || DEFAULT_NOTES_DIR
  const configPath = path.join(dir, 'config.json')
  try {
    const raw = fs.readFileSync(configPath, 'utf-8')
    return JSON.parse(raw)
  } catch {
    return {}
  }
}

export function getConfig(): AppConfig {
  const runtime = loadRuntimeConfig()
  return {
    ollamaBaseUrl: runtime.ollamaBaseUrl || process.env.OLLAMA_BASE_URL || 'http://localhost:11434',
    ollamaModel: runtime.ollamaModel || process.env.OLLAMA_MODEL || 'gemma4:e4b',
    notesDir: runtime.notesDir || process.env.NOTES_DIR || DEFAULT_NOTES_DIR,
  }
}
