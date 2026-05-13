#!/usr/bin/env bash
# Renders rhel10-minimal.ks.tmpl with values from config.json.
# Usage:  ./kickstart/generate.sh > kickstart/rhel10-minimal.ks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/../config.json"

command -v jq &>/dev/null || { echo "Error: jq is required" >&2; exit 1; }
[[ -f "$CONFIG" ]] || { echo "Error: config.json not found at ${CONFIG}" >&2; exit 1; }

GIT_EMAIL=$(jq -r '.user.email' "$CONFIG")
GIT_NAME=$(jq -r '.user.name' "$CONFIG")

sed \
  -e "s|__GIT_EMAIL__|${GIT_EMAIL}|g" \
  -e "s|__GIT_NAME__|${GIT_NAME}|g" \
  "${SCRIPT_DIR}/rhel10-minimal.ks.tmpl"
