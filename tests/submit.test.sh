#!/usr/bin/env bash
# scripts/submit.sh の回帰テスト。ダミーの Git リポジトリで、止めるべきときに止まり、正常なときに通るかを確かめる。
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); S="$ROOT/scripts/submit.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
mk() { rm -rf dev submit; git init -q -b main dev; git init -q -b main submit
  git -C submit remote add origin https://github.com/Devfest-Hackathon-2026/df-2026-t167
  printf '.env\n.env.*\n!.env.example\n' > dev/.gitignore; echo r > dev/README.md; echo l > dev/LICENSE
  mkdir -p dev/web dev/scripts; echo ok > dev/web/app.ts; cp "$S" dev/scripts/submit.sh
  printf 'env:\n  - variable: API_ORIGIN\n    value: https://api-123.asia-northeast1.run.app\n  - variable: GEMINI_KEY\n    secret: geminiKey@3\n' > dev/web/apphosting.production.yaml  # submit-allow: テスト用のダミー
  echo 'API_ORIGIN=http://127.0.0.1:8081' > dev/web/.env.example
  echo old > submit/old.txt; echo r > submit/README.md; git -C submit add -A; git -C submit commit -qm init; }
commit() { git -C dev add -f -A; git -C dev commit -qm c; }
FAILS=0
expect() { local want=$1 name=$2; shift 2; bash "$S" dev submit "$@" >out.txt 2>&1; local got=$?
  if { [ "$want" = ok ] && [ $got -eq 0 ]; } || { [ "$want" = ng ] && [ $got -ne 0 ]; }; then echo "PASS $name"; else echo "FAIL $name"; cat out.txt; FAILS=$((FAILS+1)); fi; }
mk; commit; expect ok "正常系（スクリプト自身・Secret 参照・.env.example を含む）"
[ ! -e submit/old.txt ] && echo "PASS 古いファイルが消える" || { echo "FAIL 古いファイルが残る"; FAILS=$((FAILS+1)); }
mk; commit; expect ng "存在しないブランチ" nope
[ -e submit/old.txt ] && echo "PASS 失敗時に提出先に触れない" || { echo "FAIL 提出先が変わった"; FAILS=$((FAILS+1)); }
mk; commit; echo keep > submit/untracked.txt; expect ng "提出先に未追跡ファイル"
mk; commit; git -C submit remote set-url origin https://github.com/someone/other; expect ng "提出先の remote が違う"
mk; echo X=1 > dev/.env.production; commit; expect ng "追跡済みの .env.production"
mk; echo 'PASSWORD=hunter2pass' > dev/web/config.txt; commit; expect ng "引用符なしの PASSWORD=値"  # submit-allow: テスト用のダミー
mk; echo 'DB_PASSWORD=hunter2pass' > dev/web/settings.yaml; commit; expect ng "YAML の引用符なしの値"  # submit-allow: テスト用のダミー
mk; printf "const x = { password: 'hunter2pass' };\n" > dev/web/leak.ts; commit; expect ng "コード中の文字列リテラル"  # submit-allow: テスト用のダミー
mk; printf "const x = { password: DEMO_PW };\n" > dev/web/ref.ts; commit; expect ok "コード中の変数参照は通す"  # submit-allow: テスト用のダミー
mk; printf "const pw = { password: 'emulator-only' }; // submit-allow: エミュレータ専用\n" > dev/web/seed.ts; commit; expect ok "submit-allow: を付けた行は通す"
mk; printf '  - variable: DB_PASSWORD\n    value: hunter2pass\n' >> dev/web/apphosting.production.yaml; commit; expect ng "apphosting の平文値"  # submit-allow: テスト用のダミー
mk; echo '{"db":{"password":"hunter2pass"}}' > dev/config.json; commit; expect ng "config.json のパスワード"  # submit-allow: テスト用のダミー
mk; printf -- '-----BEGIN PRIVATE KEY-----\nabc\n' > dev/k.txt; commit; expect ng "秘密鍵"  # submit-allow: テスト用のダミー
mk; printf 'const t = process.env.API_TOKEN;\n' > dev/web/env.ts; commit; expect ok "環境変数の参照は通す"  # submit-allow: テスト用のダミー
[ $FAILS -eq 0 ] && echo "ALL PASS" || { echo "$FAILS FAILED"; exit 1; }
