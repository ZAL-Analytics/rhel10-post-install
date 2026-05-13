#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
load_config

SSH_CONFIG="$HOME/.ssh/config"

# SSH key for GitHub
if [[ ! -f "$CFG_GITHUB_KEY" ]]; then
  info "Generating GitHub SSH key at ${CFG_GITHUB_KEY}..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$CFG_GITHUB_KEY" -N "" -C "$CFG_USER_EMAIL"
  success "Key generated."
else
  warn "GitHub SSH key already exists at ${CFG_GITHUB_KEY}, skipping."
fi

if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
  info "Adding github.com entry to SSH config..."
  cat >> "$SSH_CONFIG" <<EOF

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/${CFG_GITHUB_KEY_NAME}
EOF
  chmod 600 "$SSH_CONFIG"
fi

echo ""
info "Public key to add to GitHub (Settings → SSH keys):"
cat "${CFG_GITHUB_KEY}.pub"
echo ""

info "Configuring git..."
git config --global user.email "$CFG_USER_EMAIL"
git config --global user.name "$CFG_USER_NAME"

info "Writing Claude Code settings..."
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" <<EOF
{
  "model": "${CFG_CLAUDE_MODEL}",
  "env": {
    "MAX_THINKING_TOKENS": "${CFG_CLAUDE_MAX_THINKING}",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "${CFG_CLAUDE_AUTOCOMPACT}",
    "CLAUDE_CODE_SUBAGENT_MODEL": "${CFG_CLAUDE_SUBAGENT}"
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

info "Installing read-once hook..."
curl -fsSL https://raw.githubusercontent.com/Bande-a-Bonnot/Boucle-framework/main/tools/read-once/install.sh | bash

success "Keys and access configured."
