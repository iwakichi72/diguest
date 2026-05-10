'use client'

import { useReducer, useCallback } from 'react'
import type { SessionState } from '@/types'

type Action =
  | { type: 'ADD_USER'; content: string }
  | { type: 'START_ASSISTANT' }
  | { type: 'APPEND_CHUNK'; chunk: string }
  | { type: 'FINALIZE' }
  | { type: 'REMOVE_LAST_ASSISTANT' }

function reducer(state: SessionState, action: Action): SessionState {
  switch (action.type) {
    case 'ADD_USER':
      return {
        ...state,
        messages: [...state.messages, { role: 'user', content: action.content }],
      }
    case 'START_ASSISTANT':
      return {
        ...state,
        isStreaming: true,
        messages: [...state.messages, { role: 'assistant', content: '' }],
      }
    case 'APPEND_CHUNK': {
      const msgs = [...state.messages]
      const last = msgs[msgs.length - 1]
      if (last?.role === 'assistant') {
        msgs[msgs.length - 1] = { ...last, content: last.content + action.chunk }
      }
      return { ...state, messages: msgs }
    }
    case 'FINALIZE':
      return { ...state, isStreaming: false }
    case 'REMOVE_LAST_ASSISTANT': {
      const msgs = [...state.messages]
      if (msgs[msgs.length - 1]?.role === 'assistant') msgs.pop()
      return { ...state, messages: msgs, isStreaming: false }
    }
  }
}

export function useSession(theme: string, model: string) {
  const [state, dispatch] = useReducer(reducer, {
    theme,
    messages: [],
    isStreaming: false,
    model,
  })

  return {
    state,
    addUser: useCallback((content: string) => dispatch({ type: 'ADD_USER', content }), []),
    startAssistant: useCallback(() => dispatch({ type: 'START_ASSISTANT' }), []),
    appendChunk: useCallback((chunk: string) => dispatch({ type: 'APPEND_CHUNK', chunk }), []),
    finalize: useCallback(() => dispatch({ type: 'FINALIZE' }), []),
    removeLastAssistant: useCallback(() => dispatch({ type: 'REMOVE_LAST_ASSISTANT' }), []),
  }
}
