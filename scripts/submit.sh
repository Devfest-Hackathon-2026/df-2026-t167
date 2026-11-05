#!/usr/bin/env bash
# 開発用リポジトリの指定コミットを、履歴なしで提出用リポジトリの作業ツリーに反映する。
# 使い方: scripts/submit.sh <開発用リポジトリ> <提出用リポジトリ> [コミットまたはブランチ（既定 main）]
# すべての検証が終わるまで提出先には一切触れない。commit と push は人が確認してから行う。
set -euo pipefail
DEV="${1:?開発用リポジトリのパスを指定してください}"
SUBMIT="${2:?提出用リポジトリのパスを指定してください}"
REF="${3:-main}"
EXPECTED_REMOTE="${SUBMIT_REMOTE:-github.com/Devfest-Hackathon-2026/df-2026-t167}"
fail() { echo "NG: $*" >&2; exit 1; }

# ---- 1. 入力の検証（ここまでは何も変更しない） ----
DEV_TOP=$(git -C "$DEV" rev-parse --show-toplevel 2>/dev/null) || fail "$DEV は Git リポジトリではありません"
SUB_TOP=$(git -C "$SUBMIT" rev-parse --show-toplevel 2>/dev/null) || fail "$SUBMIT は Git リポジトリではありません"
[ "$(cd "$DEV" && pwd -P)" = "$DEV_TOP" ] || fail "$DEV はリポジトリの最上位ではありません"
[ "$(cd "$SUBMIT" && pwd -P)" = "$SUB_TOP" ] || fail "$SUBMIT はリポジトリの最上位ではありません"
[ "$DEV_TOP" != "$SUB_TOP" ] || fail "開発用と提出用に同じリポジトリが指定されています"
REMOTE=$(git -C "$SUBMIT" remote get-url origin 2>/dev/null || true)
case "$REMOTE" in *"$EXPECTED_REMOTE"*) ;; *) fail "提出用リポジトリの origin が $EXPECTED_REMOTE ではありません（$REMOTE）";; esac
COMMIT=$(git -C "$DEV" rev-parse --verify --quiet "${REF}^{commit}") || fail "コミット $REF が開発用リポジトリにありません"
[ -z "$(git -C "$SUBMIT" status --porcelain --untracked-files=all)" ] \
  || fail "提出用リポジトリに未コミットまたは未追跡のファイルがあります。退避してから実行してください"

# ---- 2. 一時ディレクトリに書き出して検査する ----
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
git -C "$DEV" archive "$COMMIT" | tar -x -C "$WORK"

[ -f "$WORK/README.md" ] || fail "README.md がありません"
[ -f "$WORK/LICENSE" ] || fail "LICENSE がありません"

BAD_FILES=$(cd "$WORK" && find . -type f \( -name '.env' -o -name '.env.*' -o -name '.dev.vars' \
  -o -name '*.pem' -o -name '*.p12' -o -name '*.key' -o -iname '*service*account*.json' \
  -o -iname '*credential*.json' -o -iname '*-key.json' \) ! -name '.env.example' | sort)
[ -z "$BAD_FILES" ] || fail "秘密情報になりやすいファイルが含まれています（git rm --cached で外してください）:
$BAD_FILES"

# 検出パターンは断片をつないで作る。こうするとこのスクリプト自身は検出に引っかからない。
PK="PRIV""ATE KEY"; PKJ='"private''_key"'
KEYWORDS='(password|passwd|pwd|secret|token|api[_-]?key|client[_-]?secret|private[_-]?key)'
# 鍵そのものの形式。すべてのファイル（lockfile も含む）を検査する
PATTERNS=(
  "-----BEGIN [A-Z ]*${PK}-----"
  "${PKJ}"
  'AKIA[0-9A-Z]{16}'
  'gh[pousr]_[A-Za-z0-9]{36}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  'sk-[A-Za-z0-9_-]{20,}'
)
HITS=""
for P in "${PATTERNS[@]}"; do
  H=$(grep -rniE --binary-files=without-match -- "$P" "$WORK" || true)
  [ -n "$H" ] && HITS+="$H"$'\n'
done
# 名前に password・token などを含む項目への、引用符で囲んだ値の代入。lockfile はパッケージ名（jsonwebtoken など）に反応するので除く
QUOTED="${KEYWORDS}[A-Za-z0-9_]*[\"']?[[:space:]]*[:=][[:space:]]*[\"'][^\"'[:space:]]{6,}"
H=$(grep -rniE --binary-files=without-match --exclude='package-lock.json' -- "$QUOTED" "$WORK" || true)
[ -n "$H" ] && HITS+="$H"$'\n'
# 引用符なしの代入（PASSWORD=値 など）は、コード以外のファイルで検出する。コードでは変数の参照と区別できないため
UNQUOTED="${KEYWORDS}[A-Za-z0-9_]*[[:space:]]*[:=][[:space:]]*[^\"'[:space:]\$\{<(]{6,}"
H=$(grep -rniE --binary-files=without-match \
      --exclude='*.ts' --exclude='*.tsx' --exclude='*.js' --exclude='*.mjs' --exclude='*.cjs' --exclude='package-lock.json' \
      --exclude='*.md' --exclude='*.json' -- "$UNQUOTED" "$WORK" || true)
[ -n "$H" ] && HITS+="$H"$'\n'
# 人が確認したテスト用の値（エミュレータ専用のダミーなど）は、その行に submit-allow: と書くと通す
ALLOWED=$(printf '%s' "$HITS" | grep -c 'submit-allow:' || true)
HITS=$(printf '%s' "$HITS" | grep -v 'submit-allow:' || true)
# 例外として通すのは、App Hosting の YAML にある Secret Manager の参照行だけ
SREF="secr""et"
HITS=$(printf '%s' "$HITS" | grep -vE "/apphosting(\.[a-z]+)?\.yaml:[0-9]+:[[:space:]]*-?[[:space:]]*${SREF}:[[:space:]]*[A-Za-z0-9_-]+(@[0-9]+)?[[:space:]]*\$" | sed '/^$/d' || true)
# App Hosting の YAML では、名前と値が別の行になる（variable: 行と value: 行）。名前に危険な語を含む変数の value: を検出する
for Y in $(cd "$WORK" && find . -type f -name 'apphosting*.yaml'); do
  H=$(awk -v kw="$KEYWORDS" -v f="${Y#./}" '
    BEGIN { IGNORECASE = 1 }
    /variable:/ { name = $0; sub(/.*variable:[[:space:]]*/, "", name); hot = (tolower(name) ~ kw) ; next }
    /^[[:space:]]*-[[:space:]]/ { hot = 0 }
    hot && /value:/ { print f ":" NR ": " name " に平文の値があります（Secret Manager の参照にしてください）"; hot = 0 }
  ' "$WORK/$Y")
  [ -n "$H" ] && HITS+=$'\n'"$H"
done
HITS=$(printf '%s' "$HITS" | sed '/^$/d')
[ -z "$HITS" ] || fail "秘密情報らしき値が見つかりました。確認して取り除いてください:
${HITS//$WORK\//}"

# ---- 3. 検査を通ったものだけを提出先に反映する ----
git -C "$SUBMIT" rm -rq --ignore-unmatch -- . >/dev/null
(cd "$WORK" && tar -cf - .) | tar -xf - -C "$SUBMIT"
git -C "$SUBMIT" add -A
echo "== 提出用リポジトリへの変更（A=追加 M=変更 D=削除）=="
git -C "$SUBMIT" status --short
[ "${ALLOWED:-0}" -gt 0 ] && echo "注意: submit-allow: で許可した行が ${ALLOWED} 行あります（内容を確認してください）"
echo "OK: $(git -C "$DEV" rev-parse --short "$COMMIT") の内容で検査を通過しました。確認してから次を実行してください:"
echo "  git -C \"$SUBMIT\" commit -m \"Submission $(git -C "$DEV" rev-parse --short "$COMMIT")\" && git -C \"$SUBMIT\" push origin main"
echo "やり直すとき: git -C \"$SUBMIT\" reset --hard"
