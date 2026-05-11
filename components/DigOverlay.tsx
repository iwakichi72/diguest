'use client'

import { useEffect, useState, useSyncExternalStore } from 'react'
import BrushLine from './BrushLine'

const PHASES = ['層を払う', '並べる', '光をあてる']
const PHASE_INTERVAL = 2800

function subscribeReducedMotion(callback: () => void) {
  if (typeof window === 'undefined') return () => {}
  const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
  mq.addEventListener('change', callback)
  return () => mq.removeEventListener('change', callback)
}

function getReducedMotion() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

function getReducedMotionServer() {
  return false
}

export default function DigOverlay() {
  const reduced = useSyncExternalStore(
    subscribeReducedMotion,
    getReducedMotion,
    getReducedMotionServer,
  )
  const [idx, setIdx] = useState(0)

  useEffect(() => {
    if (reduced) return
    const id = setInterval(() => {
      setIdx(i => (i + 1) % PHASES.length)
    }, PHASE_INTERVAL)
    return () => clearInterval(id)
  }, [reduced])

  const phaseLabel = reduced ? '掘り起こしています' : PHASES[idx]

  return (
    <div
      role="status"
      aria-live="polite"
      aria-busy="true"
      className="dig-overlay fixed inset-0 z-30 flex items-center justify-center bg-bg-base/95 backdrop-blur-sm"
    >
      <div className="dig-overlay-inner flex flex-col items-center gap-6 px-6">
        <span className="font-ui text-xs text-text-muted tracking-[0.3em] uppercase">
          掘り起こしています
        </span>
        <p
          key={phaseLabel}
          className="font-reading text-xl text-text-primary leading-relaxed"
          style={{ animation: 'dig-fade 600ms ease-out forwards' }}
        >
          — {phaseLabel} —
        </p>
        <BrushLine size="md" loop={!reduced} />
      </div>
      <span className="sr-only">
        Markdown を生成しています。{phaseLabel}。
      </span>
    </div>
  )
}
