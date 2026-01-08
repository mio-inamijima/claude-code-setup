#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FORCE_MODE=false

if [[ "$1" == "--force" ]]; then
    FORCE_MODE=true
fi

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}Claude Code セットアップスクリプト${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo
}

check_dependencies() {
    echo -e "${YELLOW}依存関係をチェック中...${NC}"
    
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}エラー: curlがインストールされていません${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}警告: jqがインストールされていません。JSON検証がスキップされます${NC}"
    fi
    
    echo -e "${GREEN}✓ 依存関係チェック完了${NC}"
    echo
}

get_ntfy_topic() {
    local topic=""
    
    while [[ -z "$topic" ]]; do
        echo "ntfy.shの通知先トピック名を入力してください" >&2
        echo "（例: claudecode-username）:" >&2
        read -r -p "> " topic
        
        # 改行や空白を除去
        topic=$(echo "$topic" | tr -d '\n\r' | xargs)
        
        if [[ -z "$topic" ]]; then
            echo -e "${RED}トピック名は必須です。再度入力してください。${NC}" >&2
        elif [[ "$topic" =~ [^a-zA-Z0-9_-] ]]; then
            echo -e "${RED}トピック名は英数字、ハイフン、アンダースコアのみ使用可能です。${NC}" >&2
            topic=""
        fi
    done
    
    echo "$topic"
}

backup_existing_files() {
    local backup_needed=false
    
    if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
        backup_needed=true
    fi
    
    if [[ -f "$CLAUDE_DIR/settings.local.json" ]]; then
        backup_needed=true
    fi
    
    if [[ -d "$CLAUDE_DIR/commands" ]]; then
        backup_needed=true
    fi
    
    if [[ "$backup_needed" == true ]] && [[ "$FORCE_MODE" == false ]]; then
        echo -e "${YELLOW}既存の設定が見つかりました。${NC}"
        read -r -p "バックアップを作成しますか？ (y/n): " backup_choice
        
        if [[ "$backup_choice" == "y" ]] || [[ "$backup_choice" == "Y" ]]; then
            echo -e "${YELLOW}バックアップを作成中...${NC}"
            
            if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
                cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup.$TIMESTAMP"
                echo -e "${GREEN}✓ settings.json をバックアップしました${NC}"
            fi
            
            if [[ -f "$CLAUDE_DIR/settings.local.json" ]]; then
                cp "$CLAUDE_DIR/settings.local.json" "$CLAUDE_DIR/settings.local.json.backup.$TIMESTAMP"
                echo -e "${GREEN}✓ settings.local.json をバックアップしました${NC}"
            fi
            
            if [[ -d "$CLAUDE_DIR/commands" ]]; then
                cp -r "$CLAUDE_DIR/commands" "$CLAUDE_DIR/commands.backup.$TIMESTAMP"
                echo -e "${GREEN}✓ commands ディレクトリをバックアップしました${NC}"
            fi
            echo
        fi
    fi
}

create_directories() {
    echo -e "${YELLOW}必要なディレクトリを作成中...${NC}"
    
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR/commands"
    
    echo -e "${GREEN}✓ ディレクトリ作成完了${NC}"
    echo
}

copy_templates() {
    local ntfy_topic="$1"
    
    echo -e "${YELLOW}設定ファイルを生成中...${NC}"
    
    cp "$SCRIPT_DIR/templates/settings.json.tpl" "$CLAUDE_DIR/settings.json"
    sed -i '' "s|{{NTFY_TOPIC}}|$ntfy_topic|g" "$CLAUDE_DIR/settings.json"
    chmod 600 "$CLAUDE_DIR/settings.json"
    echo -e "${GREEN}✓ settings.json を生成しました${NC}"
    
    cp "$SCRIPT_DIR/templates/settings.local.json.tpl" "$CLAUDE_DIR/settings.local.json"
    chmod 600 "$CLAUDE_DIR/settings.local.json"
    echo -e "${GREEN}✓ settings.local.json を生成しました${NC}"
    
    echo -e "${YELLOW}コマンドファイルをコピー中...${NC}"
    for cmd_file in "$SCRIPT_DIR/templates/commands"/*.md; do
        if [[ -f "$cmd_file" ]]; then
            basename_file=$(basename "$cmd_file")
            cp "$cmd_file" "$CLAUDE_DIR/commands/$basename_file"
            echo -e "${GREEN}✓ $basename_file をコピーしました${NC}"
        fi
    done
    
    echo
}

validate_setup() {
    echo -e "${YELLOW}設定を検証中...${NC}"
    
    local validation_passed=true
    
    if [[ ! -f "$CLAUDE_DIR/settings.json" ]]; then
        echo -e "${RED}✗ settings.json が見つかりません${NC}"
        validation_passed=false
    else
        echo -e "${GREEN}✓ settings.json が存在します${NC}"
        
        if command -v jq &> /dev/null; then
            if jq empty "$CLAUDE_DIR/settings.json" 2>/dev/null; then
                echo -e "${GREEN}✓ settings.json は有効なJSONです${NC}"
            else
                echo -e "${RED}✗ settings.json のJSON形式が無効です${NC}"
                validation_passed=false
            fi
        fi
    fi
    
    if [[ ! -f "$CLAUDE_DIR/settings.local.json" ]]; then
        echo -e "${RED}✗ settings.local.json が見つかりません${NC}"
        validation_passed=false
    else
        echo -e "${GREEN}✓ settings.local.json が存在します${NC}"
        
        if command -v jq &> /dev/null; then
            if jq empty "$CLAUDE_DIR/settings.local.json" 2>/dev/null; then
                echo -e "${GREEN}✓ settings.local.json は有効なJSONです${NC}"
            else
                echo -e "${RED}✗ settings.local.json のJSON形式が無効です${NC}"
                validation_passed=false
            fi
        fi
    fi
    
    local expected_commands=("code.md" "design.md" "push_main.md" "push.md" "research.md" "review.md" "setup_dirs.md" "task_start.md")
    for cmd in "${expected_commands[@]}"; do
        if [[ -f "$CLAUDE_DIR/commands/$cmd" ]]; then
            echo -e "${GREEN}✓ $cmd が存在します${NC}"
        else
            echo -e "${RED}✗ $cmd が見つかりません${NC}"
            validation_passed=false
        fi
    done
    
    echo
    
    if [[ "$validation_passed" == true ]]; then
        return 0
    else
        return 1
    fi
}

test_notification() {
    local ntfy_topic="$1"
    
    echo -e "${YELLOW}通知テストを送信しますか？ (y/n):${NC}"
    read -r -p "> " test_choice
    
    if [[ "$test_choice" == "y" ]] || [[ "$test_choice" == "Y" ]]; then
        echo -e "${YELLOW}テスト通知を送信中...${NC}"
        
        if curl -s -o /dev/null -w "%{http_code}" \
            -H "Title: Claude Code Setup Test" \
            -d "セットアップが正常に完了しました！" \
            "https://ntfy.sh/$ntfy_topic" | grep -q "200"; then
            echo -e "${GREEN}✓ 通知テスト成功！${NC}"
            echo -e "${GREEN}  https://ntfy.sh/$ntfy_topic で確認してください${NC}"
        else
            echo -e "${YELLOW}⚠ 通知テストに失敗しました。ntfy.shのトピック名を確認してください${NC}"
        fi
    fi
    echo
}

main() {
    print_header
    check_dependencies
    
    NTFY_TOPIC=$(get_ntfy_topic | tr -d '\n\r')
    echo -e "${GREEN}トピック名: $NTFY_TOPIC${NC}"
    echo
    
    backup_existing_files
    create_directories
    copy_templates "$NTFY_TOPIC"
    
    if validate_setup; then
        echo -e "${GREEN}=================================${NC}"
        echo -e "${GREEN}セットアップが正常に完了しました！${NC}"
        echo -e "${GREEN}=================================${NC}"
        echo
        
        test_notification "$NTFY_TOPIC"
        
        echo "設定ファイルの場所:"
        echo "  - $CLAUDE_DIR/settings.json"
        echo "  - $CLAUDE_DIR/settings.local.json"
        echo "  - $CLAUDE_DIR/commands/"
        echo
        echo "Claude Codeを再起動して設定を反映してください。"
    else
        echo -e "${RED}=================================${NC}"
        echo -e "${RED}セットアップ中にエラーが発生しました${NC}"
        echo -e "${RED}=================================${NC}"
        echo
        echo "上記のエラーを確認して、必要に応じて手動で修正してください。"
        exit 1
    fi
}

main