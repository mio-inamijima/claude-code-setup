# Claude Code グローバル設定セットアップツール

Claude Codeのグローバル設定（通知フックとカスタムコマンド）を簡単にセットアップするツールです。

## 機能

- **通知設定**: タスク完了時と意思決定要求時にntfy.sh経由で通知を送信
- **カスタムコマンド**: 8つの開発ワークフロー用コマンドを自動設定
- **安全なセットアップ**: 既存設定のバックアップ機能付き
- **macOS対応**: macOSで動作確認済み

## インストール方法

### 方法1: GitHubからクローン（推奨）

```bash
git clone https://github.com/yourusername/claude-code-setup.git
cd claude-code-setup
chmod +x setup.sh test.sh
./setup.sh
```

### 方法2: ワンライナーインストール

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/claude-code-setup/main/setup.sh | bash
```

### 方法3: ZIPダウンロード

1. リリースページからZIPファイルをダウンロード
2. 解凍して`setup.sh`を実行

```bash
unzip claude-code-setup.zip
cd claude-code-setup
chmod +x setup.sh
./setup.sh
```

## 使用方法

### 初回セットアップ

```bash
./setup.sh
```

実行すると以下の手順で設定が進みます：

1. **ntfy.sh通知先の入力**: 
   - 通知を受け取るトピック名を入力します
   - 例: `claudecode-yourname`
   - 使用可能文字: 英数字、ハイフン、アンダースコア

2. **既存設定のバックアップ**:
   - 既存の設定がある場合、バックアップを作成するか選択できます
   - バックアップはタイムスタンプ付きで保存されます

3. **設定ファイルの生成**:
   - `~/.claude/settings.json`: 通知フックの設定
   - `~/.claude/settings.local.json`: パーミッション設定
   - `~/.claude/commands/`: カスタムコマンド群

4. **通知テスト**:
   - セットアップ完了後、テスト通知を送信できます
   - https://ntfy.sh/your-topic で通知を確認

### 強制上書きモード

既存設定を強制的に上書きする場合：

```bash
./setup.sh --force
```

### 設定のテスト

セットアップ後の動作確認：

```bash
./test.sh
```

以下の項目がチェックされます：
- ディレクトリ構造の確認
- 設定ファイルの存在と形式
- コマンドファイルの確認
- ntfy.sh接続テスト

## カスタムコマンド

以下のコマンドが自動的に設定されます：

| コマンド | 説明 |
|---------|------|
| `/task_start` | 新しいタスクを開始 |
| `/research` | コードベースの調査を実行 |
| `/design` | 設計書を作成 |
| `/code` | 設計に基づいてコーディング |
| `/review` | コードレビューを実行 |
| `/push` | 変更をリモートにプッシュ |
| `/push_main` | mainブランチへ直接プッシュ |
| `/setup_dirs` | プロジェクトディレクトリを整備 |

## 通知の受信方法

### Webブラウザ
https://ntfy.sh/your-topic にアクセス

### モバイルアプリ
1. ntfy.shアプリをインストール（iOS/Android）
2. トピックを購読: `your-topic`

### デスクトップ通知
```bash
# macOS/Linux
curl -s ntfy.sh/your-topic/sse | while read -r line; do
    [[ "$line" == "data:"* ]] && osascript -e "display notification \"${line:6}\" with title \"Claude Code\""
done
```

## ファイル構成

```
claude-code-setup/
├── setup.sh                    # メインセットアップスクリプト
├── test.sh                     # テストスクリプト
├── README.md                   # このファイル
└── templates/                  # テンプレートファイル
    ├── settings.json.tpl       # 通知フック設定
    ├── settings.local.json.tpl # パーミッション設定
    └── commands/               # カスタムコマンド定義
        ├── code.md
        ├── design.md
        ├── push_main.md
        ├── push.md
        ├── research.md
        ├── review.md
        ├── setup_dirs.md
        └── task_start.md
```

## トラブルシューティング

### 通知が届かない
1. ntfy.shトピック名が正しいか確認
2. インターネット接続を確認
3. `./test.sh`で通知テストを実行

### JSON形式エラー
1. `jq`をインストール: `brew install jq`
2. `./test.sh`でJSON検証を実行

### パーミッションエラー
```bash
chmod +x setup.sh test.sh
chmod 600 ~/.claude/settings*.json
```

## 設定のバックアップと復元

### バックアップ
```bash
cp -r ~/.claude ~/.claude.backup.$(date +%Y%m%d)
```

### 復元
```bash
cp ~/.claude/settings.json.backup.20260108_1234 ~/.claude/settings.json
cp ~/.claude/settings.local.json.backup.20260108_1234 ~/.claude/settings.local.json
cp -r ~/.claude/commands.backup.20260108_1234/* ~/.claude/commands/
```

## セキュリティ

- 設定ファイルは600パーミッション（所有者のみ読み書き可能）で作成
- ntfy.shトピック名は推測困難なものを使用推奨
- 公開リポジトリにプッシュする際は個人情報を削除

## 要件

- **OS**: macOS（推奨）、Linux対応可能
- **依存ツール**: 
  - bash 4.0以上
  - curl（通知送信用）
  - jq（オプション、JSON検証用）

## ライセンス

MIT License

## 貢献

プルリクエストを歓迎します！

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/AmazingFeature`)
3. 変更をコミット (`git commit -m 'Add some AmazingFeature'`)
4. ブランチにプッシュ (`git push origin feature/AmazingFeature`)
5. プルリクエストを作成

## サポート

問題や質問がある場合：
- [Issues](https://github.com/yourusername/claude-code-setup/issues)で報告
- 設定例は[Wiki](https://github.com/yourusername/claude-code-setup/wiki)を参照

## 更新履歴

### v1.0.0 (2026-01-08)
- 初回リリース
- 基本的なセットアップ機能
- 8つのカスタムコマンド対応
- ntfy.sh通知統合