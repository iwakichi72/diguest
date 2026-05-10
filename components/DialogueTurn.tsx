import StreamingCursor from './StreamingCursor'

type Props = {
  role: 'user' | 'assistant'
  content: string
  isStreaming?: boolean
}

export default function DialogueTurn({ role, content, isStreaming = false }: Props) {
  if (role === 'user') {
    return (
      <div className="my-10">
        <p className="font-reading text-lg leading-[1.9] text-text-primary whitespace-pre-wrap">
          {content}
        </p>
      </div>
    )
  }

  return (
    <div className="my-10 border-t border-dashed border-border pt-6">
      <p className="font-reading text-xl leading-[2.6] text-text-primary italic whitespace-pre-wrap">
        {content}
        {isStreaming && <StreamingCursor />}
      </p>
    </div>
  )
}
