# Diguest Agent Notes

Diguest is now a SwiftUI macOS app. Do not add Next.js, React, or browser-based implementation code unless the user explicitly asks to revive the Web version.

## Current App

- Source: `Sources/Diguest/`
- Package manifest: `Package.swift`
- App metadata: `Resources/Info.plist`
- Build script: `scripts/build-macos-app.sh`
- AI backend: local Ollama HTTP API
- Storage: local Markdown files, default `~/diguest/`
- Speech input: macOS Speech framework with on-device recognition only

## Constraints

- Keep the app local-first. Do not introduce external AI APIs or cloud storage.
- Avoid chat-app patterns: no bubbles, avatars, dashboards, streaks, or suggestion chips.
- Keep Markdown readable and durable.
- If audio recognition is not available on-device, do not fall back to network recognition.
