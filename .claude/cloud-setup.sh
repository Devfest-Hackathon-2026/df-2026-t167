#!/usr/bin/env bash
# クラウドの Claude Code 環境のセットアップスクリプト（環境の設定に bash .claude/cloud-setup.sh を登録する）。
# 公開パッケージだけを入れる。環境変数（GCP_SA_KEY など）はセットアップ中には読めないので、ログインは SessionStart のフックで行う。
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/dev.sh setup
bash scripts/dev.sh doctor || true
echo 'セッションでは: export PW_CHROMIUM_PATH=/opt/pw-browsers/chromium; bash scripts/dev.sh check'
