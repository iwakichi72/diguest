export const dynamic = 'force-dynamic'

import { notFound } from 'next/navigation'
import Link from 'next/link'
import ReactMarkdown from 'react-markdown'
import { readNote } from '@/lib/markdown'
import CopyButton from '@/components/CopyButton'

type Props = {
  params: Promise<{ fileName: string }>
}

export default async function NotePage({ params }: Props) {
  const { fileName } = await params
  const note = await readNote(decodeURIComponent(fileName))

  if (!note) notFound()

  const { metadata, rawMarkdown } = note
  const body = rawMarkdown.replace(/^---[\s\S]*?---\n/, '')

  return (
    <main className="min-h-screen bg-bg-base">
      <div className="max-w-content mx-auto px-6 py-10">
        <div className="mb-10">
          <Link
            href="/"
            className="font-ui text-sm text-text-muted hover:text-text-secondary transition-colors"
          >
            ← ホーム
          </Link>
        </div>

        <p className="font-ui text-xs text-text-muted mb-8 tabular-nums">
          {metadata.date.slice(0, 10)} · {metadata.model} · {metadata.turns}ターン
        </p>

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

        <div className="border-t border-border mt-12 pt-8">
          <CopyButton markdown={rawMarkdown} />
        </div>
      </div>
    </main>
  )
}
