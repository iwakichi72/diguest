'use client'

import ReactMarkdown from 'react-markdown'

type Props = {
  markdown: string
  isSaving: boolean
  onSave: () => void
  onCancel: () => void
}

export default function MarkdownPreview({ markdown, isSaving, onSave, onCancel }: Props) {
  const body = markdown.replace(/^---[\s\S]*?---\n/, '')

  return (
    <div className="fixed inset-0 z-20 bg-bg-base overflow-y-auto">
      <header className="sticky top-0 z-10 bg-bg-base border-b border-border">
        <div className="max-w-content mx-auto px-6 py-4 flex items-center justify-between gap-4">
          <span className="font-ui text-xs text-text-muted tracking-wider uppercase">
            記録
          </span>
          <div className="flex items-center gap-6">
            <button
              onClick={onCancel}
              disabled={isSaving}
              className="font-ui text-sm text-text-muted hover:text-text-secondary transition-colors disabled:opacity-40"
            >
              続きを掘る
            </button>
            <button
              onClick={onSave}
              disabled={isSaving}
              className="font-ui text-sm text-text-secondary hover:text-text-primary transition-colors disabled:opacity-40"
            >
              {isSaving ? '保存中…' : '保存する'}
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-content mx-auto px-6 py-10">
        <article>
          <ReactMarkdown
            components={{
              h1: ({ children }) => (
                <h1 className="font-reading text-2xl text-text-primary mb-8 leading-tight">
                  {children}
                </h1>
              ),
              h2: ({ children }) => (
                <h2 className="font-reading text-lg text-text-secondary mt-12 mb-4">
                  {children}
                </h2>
              ),
              p: ({ children }) => (
                <p className="font-reading text-base text-text-primary leading-[1.9] mb-4">
                  {children}
                </p>
              ),
              li: ({ children }) => (
                <li className="font-reading text-base text-text-primary leading-[1.9] mb-2">
                  {children}
                </li>
              ),
              ul: ({ children }) => (
                <ul className="list-disc list-outside pl-5 mb-6 space-y-1">{children}</ul>
              ),
              strong: ({ children }) => (
                <strong className="font-ui text-text-secondary font-medium">
                  {children}
                </strong>
              ),
              em: ({ children }) => (
                <em className="text-text-muted not-italic">{children}</em>
              ),
              hr: () => <hr className="border-t border-border my-8" />,
            }}
          >
            {body}
          </ReactMarkdown>
        </article>
      </div>
    </div>
  )
}
