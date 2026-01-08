---
description: プロジェクトディレクトリ構造を設定
---

プロジェクトに必要なディレクトリ構造を整備します。

1. 以下のディレクトリを作成（存在しなければ）:
   - `request/` - 要件ファイル
   - `design/` - 設計書
   - `research/` - 調査結果
   - `result/` - 変更履歴（git diff）
2. `.gitignore` に以下を追加（まだなければ）:
   - `.claude_task`
   - `result/`
3. ディレクトリ構造を表示して確認