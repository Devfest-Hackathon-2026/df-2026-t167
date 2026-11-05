#!/usr/bin/env bash
# Codex のクラウド環境のセットアップスクリプト（環境の設定に bash .codex/setup.sh を登録する）。
# インターネットに接続できる間に、依存・E2E 用のブラウザ・Firestore エミュレータをすべて取得しておく。
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/dev.sh setup
if [ -z "${PW_CHROMIUM_PATH:-}" ]; then (cd web && npx playwright install --with-deps chromium); fi
# エミュレータの本体（jar）は初回起動時にダウンロードされるので、ここで取得しておく
firebase/node_modules/.bin/firebase setup:emulators:firestore
bash scripts/dev.sh doctor || true
echo "準備完了。検査は bash scripts/dev.sh check"
