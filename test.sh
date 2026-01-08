#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CLAUDE_DIR="$HOME/.claude"
TEST_PASSED=true

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}Claude Code 設定テスト${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo
}

test_directory_structure() {
    echo -e "${YELLOW}ディレクトリ構造をテスト中...${NC}"
    
    if [[ -d "$CLAUDE_DIR" ]]; then
        echo -e "${GREEN}✓ ~/.claude/ ディレクトリが存在${NC}"
    else
        echo -e "${RED}✗ ~/.claude/ ディレクトリが存在しません${NC}"
        TEST_PASSED=false
    fi
    
    if [[ -d "$CLAUDE_DIR/commands" ]]; then
        echo -e "${GREEN}✓ ~/.claude/commands/ ディレクトリが存在${NC}"
    else
        echo -e "${RED}✗ ~/.claude/commands/ ディレクトリが存在しません${NC}"
        TEST_PASSED=false
    fi
    
    echo
}

test_settings_files() {
    echo -e "${YELLOW}設定ファイルをテスト中...${NC}"
    
    if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
        echo -e "${GREEN}✓ settings.json が存在${NC}"
        
        if command -v jq &> /dev/null; then
            if jq empty "$CLAUDE_DIR/settings.json" 2>/dev/null; then
                echo -e "${GREEN}✓ settings.json が有効なJSON${NC}"
                
                local has_hooks=$(jq 'has("hooks")' "$CLAUDE_DIR/settings.json")
                if [[ "$has_hooks" == "true" ]]; then
                    echo -e "${GREEN}✓ hooks設定が存在${NC}"
                    
                    local has_stop_hook=$(jq '.hooks | has("Stop")' "$CLAUDE_DIR/settings.json")
                    if [[ "$has_stop_hook" == "true" ]]; then
                        echo -e "${GREEN}✓ Stop hookが設定済み${NC}"
                    else
                        echo -e "${RED}✗ Stop hookが未設定${NC}"
                        TEST_PASSED=false
                    fi
                    
                    local has_notification_hook=$(jq '.hooks | has("Notification")' "$CLAUDE_DIR/settings.json")
                    if [[ "$has_notification_hook" == "true" ]]; then
                        echo -e "${GREEN}✓ Notification hookが設定済み${NC}"
                    else
                        echo -e "${RED}✗ Notification hookが未設定${NC}"
                        TEST_PASSED=false
                    fi
                else
                    echo -e "${RED}✗ hooks設定が存在しません${NC}"
                    TEST_PASSED=false
                fi
            else
                echo -e "${RED}✗ settings.json のJSON形式が無効${NC}"
                TEST_PASSED=false
            fi
        else
            echo -e "${YELLOW}⚠ jqがインストールされていないため、JSON検証をスキップ${NC}"
        fi
        
        local perms=$(stat -f "%Lp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
        if [[ "$perms" == "600" ]]; then
            echo -e "${GREEN}✓ settings.json のパーミッションが適切 (600)${NC}"
        else
            echo -e "${YELLOW}⚠ settings.json のパーミッション: $perms (推奨: 600)${NC}"
        fi
    else
        echo -e "${RED}✗ settings.json が存在しません${NC}"
        TEST_PASSED=false
    fi
    
    echo
    
    if [[ -f "$CLAUDE_DIR/settings.local.json" ]]; then
        echo -e "${GREEN}✓ settings.local.json が存在${NC}"
        
        if command -v jq &> /dev/null; then
            if jq empty "$CLAUDE_DIR/settings.local.json" 2>/dev/null; then
                echo -e "${GREEN}✓ settings.local.json が有効なJSON${NC}"
            else
                echo -e "${RED}✗ settings.local.json のJSON形式が無効${NC}"
                TEST_PASSED=false
            fi
        fi
        
        local perms=$(stat -f "%Lp" "$CLAUDE_DIR/settings.local.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.local.json" 2>/dev/null)
        if [[ "$perms" == "600" ]]; then
            echo -e "${GREEN}✓ settings.local.json のパーミッションが適切 (600)${NC}"
        else
            echo -e "${YELLOW}⚠ settings.local.json のパーミッション: $perms (推奨: 600)${NC}"
        fi
    else
        echo -e "${RED}✗ settings.local.json が存在しません${NC}"
        TEST_PASSED=false
    fi
    
    echo
}

test_command_files() {
    echo -e "${YELLOW}コマンドファイルをテスト中...${NC}"
    
    local expected_commands=("code.md" "design.md" "push_main.md" "push.md" "research.md" "review.md" "setup_dirs.md" "task_start.md")
    local missing_count=0
    
    for cmd in "${expected_commands[@]}"; do
        if [[ -f "$CLAUDE_DIR/commands/$cmd" ]]; then
            echo -e "${GREEN}✓ $cmd が存在${NC}"
        else
            echo -e "${RED}✗ $cmd が存在しません${NC}"
            missing_count=$((missing_count + 1))
            TEST_PASSED=false
        fi
    done
    
    if [[ $missing_count -eq 0 ]]; then
        echo -e "${GREEN}✓ 全てのコマンドファイルが存在${NC}"
    else
        echo -e "${RED}✗ $missing_count 個のコマンドファイルが不足${NC}"
    fi
    
    echo
}

test_ntfy_connection() {
    echo -e "${YELLOW}ntfy.sh接続をテスト中...${NC}"
    
    if [[ -f "$CLAUDE_DIR/settings.json" ]] && command -v jq &> /dev/null; then
        local ntfy_topic=$(jq -r '.hooks.Stop[0].hooks[0].command' "$CLAUDE_DIR/settings.json" 2>/dev/null | sed -n 's/.*ntfy.sh\/\([^"]*\).*/\1/p')
        
        if [[ -n "$ntfy_topic" ]]; then
            echo -e "${GREEN}✓ ntfy.shトピック検出: $ntfy_topic${NC}"
            
            echo -e "${YELLOW}通知テストを送信しますか？ (y/n):${NC}"
            read -r -p "> " test_choice
            
            if [[ "$test_choice" == "y" ]] || [[ "$test_choice" == "Y" ]]; then
                if curl -s -o /dev/null -w "%{http_code}" \
                    -H "Title: Claude Code Test" \
                    -d "テスト通知: $(date '+%Y-%m-%d %H:%M:%S')" \
                    "https://ntfy.sh/$ntfy_topic" | grep -q "200"; then
                    echo -e "${GREEN}✓ ntfy.sh通知テスト成功${NC}"
                else
                    echo -e "${RED}✗ ntfy.sh通知テスト失敗${NC}"
                    TEST_PASSED=false
                fi
            else
                echo -e "${YELLOW}⚠ 通知テストをスキップ${NC}"
            fi
        else
            echo -e "${RED}✗ ntfy.shトピックが設定されていません${NC}"
            TEST_PASSED=false
        fi
    else
        echo -e "${YELLOW}⚠ settings.json またはjqが存在しないため、通知テストをスキップ${NC}"
    fi
    
    echo
}

print_summary() {
    echo -e "${BLUE}=================================${NC}"
    if [[ "$TEST_PASSED" == true ]]; then
        echo -e "${GREEN}テスト結果: 成功${NC}"
        echo -e "${GREEN}全てのテストが正常に完了しました！${NC}"
    else
        echo -e "${RED}テスト結果: 失敗${NC}"
        echo -e "${RED}上記のエラーを確認してください${NC}"
    fi
    echo -e "${BLUE}=================================${NC}"
}

show_config_info() {
    echo
    echo -e "${YELLOW}現在の設定情報:${NC}"
    echo "設定ディレクトリ: $CLAUDE_DIR"
    
    if [[ -f "$CLAUDE_DIR/settings.json" ]] && command -v jq &> /dev/null; then
        local ntfy_topic=$(jq -r '.hooks.Stop[0].hooks[0].command' "$CLAUDE_DIR/settings.json" 2>/dev/null | sed -n 's/.*ntfy.sh\/\([^"]*\).*/\1/p')
        if [[ -n "$ntfy_topic" ]]; then
            echo "ntfy.shトピック: $ntfy_topic"
            echo "通知URL: https://ntfy.sh/$ntfy_topic"
        fi
    fi
    
    if [[ -d "$CLAUDE_DIR/commands" ]]; then
        local cmd_count=$(ls -1 "$CLAUDE_DIR/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
        echo "コマンドファイル数: $cmd_count"
    fi
    
    echo
}

main() {
    print_header
    
    test_directory_structure
    test_settings_files
    test_command_files
    test_ntfy_connection
    
    print_summary
    show_config_info
    
    if [[ "$TEST_PASSED" == false ]]; then
        exit 1
    fi
}

main