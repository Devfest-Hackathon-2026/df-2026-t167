#!/usr/bin/env bash
# クラウドの Claude Code などの AI ツール用サービスアカウント（プロジェクトの編集者）を作り、鍵を出力する。
# 手元の PC の AI ツールは、各自の gcloud auth login / gcloud auth application-default login で足りるので不要。
# 使い方: bash infra/setup-ai-access.sh   （鍵は ~/ai-dev-key.json に作られる）
set -euo pipefail
source "$(dirname "$0")/env.sh"
SA="ai-dev@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud iam service-accounts describe "$SA" --project "$PROJECT_ID" >/dev/null 2>&1 \
  || gcloud iam service-accounts create ai-dev --project "$PROJECT_ID" --display-name="AI tools"
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:${SA}" --role=roles/editor --condition=None >/dev/null
gcloud iam service-accounts keys create "$HOME/ai-dev-key.json" --iam-account="$SA" --project "$PROJECT_ID"
echo "中身を Claude Code の環境変数 GCP_SA_KEY に登録してください（cat ~/ai-dev-key.json）"
