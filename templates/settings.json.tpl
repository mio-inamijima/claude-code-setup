{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "curl -H \"Title: Claude Code\" -d \"Claude Codeがタスクを完了しました\" ntfy.sh/{{NTFY_TOPIC}}"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "curl -H \"Title: Claude Code\" -d \"Claude Codeが意思決定を求めています\" ntfy.sh/{{NTFY_TOPIC}}"
          }
        ]
      }
    ]
  },
  "$schema": "https://json.schemastore.org/claude-code-settings.json"
}