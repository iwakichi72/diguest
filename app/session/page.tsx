import { Suspense } from 'react'
import SessionClient from './client'

export default function SessionPage() {
  return (
    <Suspense>
      <SessionClient />
    </Suspense>
  )
}
