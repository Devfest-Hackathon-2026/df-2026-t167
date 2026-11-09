/** 指標を表示用の文字列にする。null は「データなし」、推定値は出典を添える */
export function formatMetric(value: number | null | undefined, source?: "gemini" | "mock"): string {
  if (value === null || value === undefined) return "データなし";
  const pct = `${Math.round(value * 100)}%`;
  if (source === "mock") return `${pct}（デモデータ）`;
  if (source === "gemini") return `${pct}（Gemini による推定）`;
  return pct;
}
