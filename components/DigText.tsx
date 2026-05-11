'use client'

import { useEffect } from 'react'

type Props = {
  text: string
  active: boolean
  className?: string
  onComplete?: () => void
}

const TARGET_TOTAL_MS = 900
const REVEAL_MAX = 500
const REVEAL_MIN = 280
const MIN_STAGGER = 12
const MAX_STAGGER = 40

function computeTimings(n: number) {
  if (n <= 1) return { stagger: MAX_STAGGER, reveal: REVEAL_MAX, total: REVEAL_MAX }
  const span = n - 1
  let stagger = MAX_STAGGER
  let reveal = REVEAL_MAX
  if (span * stagger + reveal > TARGET_TOTAL_MS) {
    stagger = (TARGET_TOTAL_MS - reveal) / span
    if (stagger < MIN_STAGGER) {
      stagger = MIN_STAGGER
      reveal = Math.max(REVEAL_MIN, TARGET_TOTAL_MS - span * MIN_STAGGER)
    }
  }
  return { stagger, reveal, total: span * stagger + reveal }
}

export default function DigText({ text, active, className = '', onComplete }: Props) {
  const chars = Array.from(text)
  const { stagger, reveal, total } = computeTimings(chars.length)

  useEffect(() => {
    if (!active || !onComplete) return
    const id = setTimeout(onComplete, active ? total : 0)
    return () => clearTimeout(id)
  }, [active, total, onComplete])

  if (!active) {
    return <span className={className}>{text}</span>
  }

  return (
    <span
      className={`relative inline-block ${className}`}
      style={
        {
          ['--dig-stagger' as string]: `${stagger}ms`,
          ['--dig-reveal' as string]: `${reveal}ms`,
          ['--dig-total' as string]: `${total}ms`,
        } as React.CSSProperties
      }
    >
      <span className="sr-only">{text}</span>
      <span aria-hidden="true">
        {chars.map((ch, i) => (
          <span
            key={i}
            className="dig-char"
            style={{ ['--dig-i' as string]: i } as React.CSSProperties}
          >
            {ch === ' ' ? ' ' : ch}
          </span>
        ))}
      </span>
      <span aria-hidden="true" className="dig-brush" />
    </span>
  )
}
