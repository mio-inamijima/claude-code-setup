---
description: Read権限のみで調査を実行
allowed-tools: View, Bash(cat:*), Bash(grep:*), Bash(find:*)
---

現在のタスクについて調査を実行します。

1. `.claude_task` から現在のfilenameを読み込む
2. Read権限のみで以下を調査:
   - コードベースの関連実装
   - 類似機能の実装パターン
   - 依存関係の確認
3. 調査結果を `research/{filename}.txt` に保存