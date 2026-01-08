{
  "permissions": {
    "allow": [
      "Bash(lsof:*)",
      "Bash(sudo lsof:*)",
      "Bash(sudo -u postgres /Library/PostgreSQL/12/bin/pg_ctl:*)",
      "Read(//Library/LaunchDaemons/**)",
      "Bash(echo $PATH)",
      "Bash(source:*)",
      "Bash(pkill:*)"
    ]
  },
  "enableAllProjectMcpServers": false
}