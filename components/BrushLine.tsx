type Props = {
  size?: 'sm' | 'md'
  loop?: boolean
  className?: string
}

export default function BrushLine({ size = 'sm', loop = false, className = '' }: Props) {
  const width = size === 'md' ? 'w-40' : 'w-12'
  const anim = loop ? 'dig-sweep' : ''
  return (
    <span
      aria-hidden="true"
      className={`block ${width} h-px ${anim} ${className}`}
      style={
        loop
          ? undefined
          : {
              background: 'var(--color-accent)',
              boxShadow: '0 0 6px rgba(196, 149, 106, 0.35)',
              opacity: 0.55,
            }
      }
    />
  )
}
