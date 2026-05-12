import Link from 'next/link'
import { listNotes } from '@/lib/markdown'
import DigStartLink from '@/components/DigStartLink'

export const dynamic = 'force-dynamic'

export default async function Home() {
  const notes = await listNotes()
  const recent = notes.slice(0, 5)

  return (
    <main className="min-h-screen bg-bg-base">
      <div className="max-w-content mx-auto px-6 py-16">
        <header className="flex items-center justify-between mb-16">
          <span className="font-ui text-text-secondary text-sm tracking-widest uppercase">
            Diguest
          </span>
        </header>

        <section className="mb-16">
          <p className="font-reading text-xl text-text-primary mb-8">
            今日、何を掘りますか？
          </p>
          <DigStartLink
            href="/session/new"
            label="掘り始める"
            className="inline-block font-ui text-sm text-text-secondary border border-border rounded px-6 py-3 hover:text-text-primary hover:border-border-focus transition-colors disabled:cursor-progress"
          />
        </section>

        {recent.length > 0 && (
          <section>
            <div className="border-t border-border mb-8" />
            <div className="flex items-center justify-between gap-4 mb-6">
              <p className="font-ui text-xs text-text-muted tracking-wider uppercase">
                過去のノート
              </p>
              <Link
                href="/notes"
                className="font-ui text-xs text-text-muted hover:text-text-secondary transition-colors"
              >
                すべて見る
              </Link>
            </div>
            <ul>
              {recent.map(note => (
                <li key={note.fileName}>
                  <Link
                    href={`/notes/${encodeURIComponent(note.fileName)}`}
                    className="flex items-baseline gap-5 py-3 px-2 -mx-2 rounded hover:bg-bg-subtle transition-colors"
                  >
                    <span className="font-ui text-xs text-text-muted tabular-nums w-24 shrink-0">
                      {note.date.slice(0, 10)}
                    </span>
                    <span className="font-reading text-base text-text-primary truncate">
                      {note.theme}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        )}

        {notes.length === 0 && (
          <p className="font-ui text-sm text-text-muted mt-4">
            最初のセッションを終えると、ここにノートが残ります。
          </p>
        )}
      </div>
    </main>
  )
}
