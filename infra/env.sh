# 共通の変数。使い方: source infra/env.sh
export PROJECT_ID="df2026-t167"
export REGION="asia-northeast1"          # Cloud Run・Firestore・Vertex AI
export APPHOSTING_REGION="asia-east1"    # App Hosting（東京は非対応）
export DEV_REPO="genellect/df-2026-t167-dev"   # 作成した公開の開発用リポジトリの名前に合わせる（WIF はこのリポジトリだけを許可する）
export SUBMIT_REPO="Devfest-Hackathon-2026/df-2026-t167"
export GEMINI_MODEL="ここに決めたモデルID"  # Vertex AI の Model Garden で asia-northeast1 で使えるものを確認して固定する
