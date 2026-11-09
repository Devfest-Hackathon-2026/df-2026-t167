import { describe, expect, it } from "vitest";
import { formatMetric } from "./format";

describe("formatMetric", () => {
  it("null はデータなし", () => expect(formatMetric(null)).toBe("データなし"));
  it("推定値には出典を付ける", () => {
    expect(formatMetric(0.5, "gemini")).toBe("50%（Gemini による推定）");
    expect(formatMetric(0.25, "mock")).toBe("25%（デモデータ）");
  });
});
