#!/usr/bin/env bash
set -euo pipefail

CODEBERG_KEY="$HOME/.ssh/codeberg"
SSH_CONFIG="$HOME/.ssh/config"

# ====== SSH keys ======

# Codeberg 
ssh-keygen -t ed25519 -a 100 -f "$KEY" -N "" -C "codeberg"

# Append the Host entry to ~/.ssh/config
cat >> "$SSH_CONFIG" <<'EOF'

Host codeberg.org
  HostName codeberg.org
  User git
  IdentityFile ~/.ssh/codeberg
EOF

echo "Done. Public key to add to Codeberg:"

# ====== Git credentials ======
git config --global user.email "arsalan@anwari.nl"
git config --global user.name "arsalan-anwari"

# ====== Claude keys and settings ======
mkdir -p ~/.claude
cat > ~/.claude/settings.json << 'EOF'
{
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "20000",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50",
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/read-once/hook.sh"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/read-once/compact.sh"
          }
        ]
      }
    ]
  }
}
EOF

curl -fsSL https://raw.githubusercontent.com/Bande-a-Bonnot/Boucle-framework/main/tools/read-once/install.sh | bash

echo "Written to ~/.claude/settings.json"

