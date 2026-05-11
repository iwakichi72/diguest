'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import DigText from './DigText'

type Props = {
  href: string
  label: string
  className?: string
}

export default function DigStartLink({ href, label, className }: Props) {
  const router = useRouter()
  const [digging, setDigging] = useState(false)

  useEffect(() => {
    router.prefetch(href)
  }, [router, href])

  function handleClick() {
    if (digging) return
    setDigging(true)
  }

  function handleComplete() {
    router.push(href)
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      onMouseEnter={() => router.prefetch(href)}
      disabled={digging}
      aria-busy={digging}
      className={className}
      style={digging ? { cursor: 'progress' } : undefined}
    >
      <DigText text={label} active={digging} onComplete={handleComplete} />
    </button>
  )
}
