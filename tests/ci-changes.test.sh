#!/usr/bin/env bash
# scripts/ci-changes.sh の判定の回帰テスト
set -uo pipefail
cd "$(dirname "$0")/.."
pass=0 fail=0
expect() {
  local want="$1" name="$2"; shift 2
  local got; got=$(printf '%s\n' "$@" | GITHUB_OUTPUT= bash scripts/ci-changes.sh - | tail -1)
  if [ "$got" = "code=$want" ]; then pass=$((pass+1)); echo "PASS $name"; else fail=$((fail+1)); echo "FAIL $name（$got）"; fi
}
expect false "README だけ" README.md
expect false "docs と PR テンプレート" docs/architecture.md .github/pull_request_template.md
expect false "AGENTS.md と LICENSE" AGENTS.md LICENSE
expect true  "画面のコード" web/src/app/page.tsx
expect true  "文書とコードが混在" README.md api/src/app.ts
expect true  "ワークフロー" .github/workflows/ci.yml
expect true  "Rules" firebase/firestore.rules
expect true  "lockfile" web/package-lock.json
got=$(GITHUB_OUTPUT= bash scripts/ci-changes.sh | tail -1)
[ "$got" = "code=true" ] && { pass=$((pass+1)); echo "PASS 引数なし（main への push）は全部"; } || { fail=$((fail+1)); echo "FAIL 引数なし（$got）"; }
echo "ci-changes: ${pass} PASS / ${fail} FAIL"
[ "$fail" -eq 0 ]
