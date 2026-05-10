'use client'

import { useState } from 'react'

export default function CopyButton({ markdown }: { markdown: string }) {
  const [copied, setCopied] = useState(false)

  async function handleCopy() {
    await navigator.clipboard.writeText(markdown)
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  return (
    <button
      onClick={handleCopy}
      className="font-ui text-sm text-text-muted hover:text-text-secondary transition-colors"
    >
      {copied ? 'コピーしました' : 'Markdownをコピー'}
    </button>
  )
}
