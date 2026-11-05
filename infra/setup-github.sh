#!/usr/bin/env bash
# 開発用リポジトリの GitHub 設定をそろえる（gh でログイン済みのリポジトリ管理者が1回実行する）。
#   - マージは squash だけ。PR のタイトルがそのまま main のコミットの件名になる
#   - マージしたブランチは自動で削除する
#   - main は PR 経由でだけ更新し、CI（test）の成功を必須にする。レビューの承認は必須にしない（速度優先）
# 使い方: bash infra/setup-github.sh
set -euo pipefail
source "$(dirname "$0")/env.sh"
R="$DEV_REPO"
gh repo edit "$R" --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false \
  --delete-branch-on-merge --enable-auto-merge
gh api -X PATCH "repos/$R" -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY >/dev/null
echo "OK: squash だけ・マージ後にブランチを削除・auto-merge を有効にしました"
# 公開リポジトリでは無料。よく知られた形式の鍵（GCP のサービスアカウントの鍵など）を含む push を GitHub が止める
if gh api -X PATCH "repos/$R" -f 'security_and_analysis[secret_scanning][status]=enabled' \
     -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled' >/dev/null 2>&1; then
  echo "OK: secret scanning と push protection を有効にしました"
else
  echo "[--] push protection を有効にできませんでした。Settings → Code security で有効にしてください"
fi

EXISTING=$(gh api "repos/$R/rulesets" --jq '.[] | select(.name=="main") | .id' 2>/dev/null || true)
BODY=$(cat <<'JSON'
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false, "require_last_push_approval": false,
        "required_review_thread_resolution": false, "allowed_merge_methods": ["squash"] } },
    { "type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [ { "context": "test" } ] } }
  ]
}
JSON
)
if [ -n "$EXISTING" ]; then M=PUT; P="repos/$R/rulesets/$EXISTING"; else M=POST; P="repos/$R/rulesets"; fi
if printf '%s' "$BODY" | gh api -X "$M" "$P" --input - >/dev/null 2>&1; then
  echo "OK: main のルール（PR 必須・CI の test が必須・force push と削除の禁止）を設定しました"
else
  # 公開リポジトリなら Free プランでも設定できる。失敗するのは主に、gh のアカウントが管理者でないとき
  echo "[--] main のルールを設定できませんでした（gh のアカウントがリポジトリの管理者か確かめてください）。"
  echo "     オーナーが実行し直すまでは、main へ直接 push せず、gh pr checks --watch で CI の成功を確かめてからマージしてください。"
fi
