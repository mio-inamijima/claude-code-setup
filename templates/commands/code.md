---
description: 設計に基づいてコーディング
---

設計書に基づいてコーディングを実行します。

1. `.claude_task` から現在のfilenameを読み込む
2. `design/{filename}.txt` を読み込む
3. 設計に従ってコーディング
4. 完了後、`git diff > result/{filename}.txt` を実行
5. 変更ファイル一覧を表示