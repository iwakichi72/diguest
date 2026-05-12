import Link from 'next/link'
import { listNotes } from '@/lib/markdown'

export const dynamic = 'force-dynamic'

type Note = Awaited<ReturnType<typeof listNotes>>[number]

function noteDate(note: Note): Date | null {
  const date = new Date(note.date)
  return Number.isNaN(date.getTime()) ? null : date
}

function monthLabel(note: Note, currentYear: number): string {
  const date = noteDate(note)
  if (!date) return '日付なし'

  const year = date.getFullYear()
  const month = date.getMonth() + 1
  return year === currentYear ? `${month}月` : `${year}年 ${month}月`
}

function dayLabel(note: Note): string {
  const date = noteDate(note)
  if (!date) return '--'
  return String(date.getDate()).padStart(2, '0')
}

function groupByMonth(notes: Note[]): Array<{ label: string; notes: Note[] }> {
  const currentYear = new Date().getFullYear()
  const groups = new Map<string, Note[]>()

  for (const note of notes) {
    const label = monthLabel(note, currentYear)
    const group = groups.get(label) ?? []
    group.push(note)
    groups.set(label, group)
  }

  return Array.from(groups, ([label, groupedNotes]) => ({
    label,
    notes: groupedNotes,
  }))
}

export default async function NotesPage() {
  const notes = await listNotes()
  const groups = groupByMonth(notes)

  return (
    <main className="min-h-screen bg-bg-base">
      <div className="max-w-content mx-auto px-6 py-10">
        <header className="flex items-center justify-between gap-4 mb-14">
          <Link
            href="/"
            className="font-ui text-sm text-text-muted hover:text-text-secondary transition-colors"
          >
            ← ホーム
          </Link>
          <Link
            href="/session/new"
            className="font-ui text-sm text-text-secondary border border-border rounded px-4 py-2 hover:text-text-primary hover:border-border-focus transition-colors"
          >
            + 新しいセッション
          </Link>
        </header>

        <h1 className="font-ui text-xs text-text-muted mb-10 tracking-wider uppercase">
          過去のノート
        </h1>

        {notes.length === 0 ? (
          <p className="font-reading text-base text-text-muted leading-[1.9]">
            最初の問いを立ててみよう
          </p>
        ) : (
          <div className="space-y-12">
            {groups.map(group => (
              <section key={group.label}>
                <h2 className="font-ui text-xs text-text-muted mb-4 tracking-wider">
                  {group.label}
                </h2>
                <ul>
                  {group.notes.map(note => (
                    <li key={note.fileName}>
                      <Link
                        href={`/notes/${encodeURIComponent(note.fileName)}`}
                        className="flex items-baseline gap-5 py-3 px-2 -mx-2 rounded hover:bg-bg-subtle transition-colors"
                      >
                        <span className="font-ui text-xs text-text-muted tabular-nums w-8 shrink-0">
                          {dayLabel(note)}
                        </span>
                        <span className="font-reading text-base text-text-primary truncate">
                          {note.theme || note.fileName.replace(/\.md$/, '')}
                        </span>
                      </Link>
                    </li>
                  ))}
                </ul>
              </section>
            ))}
          </div>
        )}
      </div>
    </main>
  )
}
