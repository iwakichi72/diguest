const ADVISORY_PATTERNS = [
  /しましょう/u,
  /すべき/u,
  /おすすめ/u,
  /お勧め/u,
  /してみてください/u,
  /試してみて/u,
  /効果的です/u,
  /良いと思います/u,
  /改善/u,
  /解決策/u,
]

export function hasAdvisoryLanguage(text: string): boolean {
  return ADVISORY_PATTERNS.some(pattern => pattern.test(text))
}

export function removeAdvisoryItems(items: string[]): string[] {
  return items.filter(item => !hasAdvisoryLanguage(item))
}
