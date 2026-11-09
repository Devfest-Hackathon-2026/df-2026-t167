@AGENTS.md

# Claude Code 向けの補足

[AGENTS.md](AGENTS.md) は冒頭の `@AGENTS.md` で読み込まれる。作業の手順・検査・マージの権限は AGENTS.md と [CONTRIBUTING](CONTRIBUTING.md) に従い、この文書で上書きしない。

- クラウド環境のセットアップスクリプトには `bash .claude/cloud-setup.sh` を登録する。セッションでは `bash scripts/dev.sh doctor` で準備を確かめてから `serve` で起動する。
- クラウド環境では、用意済みの Chromium を使う。`export PW_CHROMIUM_PATH=/opt/pw-browsers/chromium` を付けて `check` を実行する。
- 環境変数 `GCP_SA_KEY` があれば、セッションの開始時に `.claude/settings.json` のフックが gcloud にログインする。本番の GCP を操作するのは、依頼者が指示したときだけ。
- コミットには、Claude Code が付ける `Co-Authored-By` 行を残す。
