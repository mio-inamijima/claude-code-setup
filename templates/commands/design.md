---
description: タスクの設計書を作成
---

現在のタスクの設計書を作成します。

1. `.claude_task` から現在のfilenameを読み込む
2. `request/{filename}.txt` を読み込む
3. `research/{filename}.txt` があれば参照
4. 設計書を `design/{filename}.txt` に作成:
   - 概要
   - アーキテクチャ
   - 実装方針
   - 必要な変更ファイル
   - テスト方針