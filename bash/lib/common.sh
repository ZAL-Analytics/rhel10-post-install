#!/usr/bin/env bash
# Shared utilities sourced by all post-install scripts

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
success() { echo -e "${GREEN}[ OK ]${NC}  $*"; }
die()     { echo -e "${RED}[ERR ]${NC}  $*" >&2; exit 1; }

require_cmd() {
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null || die "Required command not found: $cmd"
  done
}

# Append a line to a file only if not already present
append_if_missing() {
  local line="$1" file="${2:-$HOME/.bashrc}"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# Repo root is two levels above bash/lib/
_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${_COMMON_DIR}/../.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/config.json"

# Reads config.json and exports CFG_* variables used by individual scripts.
# Requires: jq
load_config() {
  require_cmd jq
  [[ -f "$CONFIG_FILE" ]] || die "config.json not found at ${CONFIG_FILE}"

  CFG_USER_NAME=$(jq -r '.user.name' "$CONFIG_FILE")
  CFG_USER_EMAIL=$(jq -r '.user.email' "$CONFIG_FILE")

  CFG_GITHUB_KEY_NAME=$(jq -r '.ssh.github_key_name' "$CONFIG_FILE")
  CFG_GITHUB_KEY="$HOME/.ssh/${CFG_GITHUB_KEY_NAME}"

  CFG_CLAUDE_MODEL=$(jq -r '.claude.model' "$CONFIG_FILE")
  CFG_CLAUDE_MAX_THINKING=$(jq -r '.claude.max_thinking_tokens' "$CONFIG_FILE")
  CFG_CLAUDE_AUTOCOMPACT=$(jq -r '.claude.autocompact_pct' "$CONFIG_FILE")
  CFG_CLAUDE_SUBAGENT=$(jq -r '.claude.subagent_model' "$CONFIG_FILE")

  CFG_CUDA_VER=$(jq -r '.cuda.version' "$CONFIG_FILE")
  CFG_TENSORRT_RPM_URL=$(jq -r '.cuda.tensorrt_rpm_url' "$CONFIG_FILE")
  CFG_NSIGHT_SYSTEMS_VER=$(jq -r '.cuda.nsight_systems_version' "$CONFIG_FILE")
  CFG_NSIGHT_COMPUTE_VER=$(jq -r '.cuda.nsight_compute_version' "$CONFIG_FILE")

  CFG_MEM_MB=$(jq -r '.hw_tests.memory_mb' "$CONFIG_FILE")
  CFG_MEM_PASSES=$(jq -r '.hw_tests.memory_passes' "$CONFIG_FILE")
}
