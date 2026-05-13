#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

SKIP_BASE=false
SKIP_KEYS=false
SKIP_HW_TESTS=false
GPU_BACKEND="none"

usage() {
  cat <<'EOF'
Usage: ./setup.sh [OPTIONS]

Options:
  --skip-base         Skip base package installation
  --skip-keys         Skip SSH / git / Claude configuration
  --skip-hw-tests     Skip hardware benchmark tests
  --gpu <backend>     GPU compute backend: cuda | vulkan | both | none  (default: none)
  -h, --help          Show this help message

Examples:
  ./setup.sh --gpu cuda
  ./setup.sh --skip-hw-tests --gpu both
  ./setup.sh --skip-base --skip-keys --gpu vulkan
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-base)      SKIP_BASE=true ;;
    --skip-keys)      SKIP_KEYS=true ;;
    --skip-hw-tests)  SKIP_HW_TESTS=true ;;
    --gpu)            shift; GPU_BACKEND="${1:?--gpu requires: cuda | vulkan | both | none}" ;;
    -h|--help)        usage ;;
    *) die "Unknown option: $1. Use -h for help." ;;
  esac
  shift
done

[[ "$GPU_BACKEND" =~ ^(cuda|vulkan|both|none)$ ]] || \
  die "Invalid GPU backend '${GPU_BACKEND}'. Choose: cuda | vulkan | both | none"

[[ "$SKIP_BASE"     == false ]] && { info "Step 1/4: base packages";   bash "${SCRIPT_DIR}/base-pkg.sh"; }
[[ "$SKIP_KEYS"     == false ]] && { info "Step 2/4: keys and access"; bash "${SCRIPT_DIR}/keys-and-access.sh"; }
[[ "$SKIP_HW_TESTS" == false ]] && { info "Step 3/4: hardware tests";  bash "${SCRIPT_DIR}/hw-testers.sh"; }

info "Step 4/4: GPU compute (backend: ${GPU_BACKEND})"
case "$GPU_BACKEND" in
  cuda)   bash "${SCRIPT_DIR}/gpu-compute/cuda.sh" ;;
  vulkan) bash "${SCRIPT_DIR}/gpu-compute/vulkan.sh" ;;
  both)
    bash "${SCRIPT_DIR}/gpu-compute/cuda.sh"
    bash "${SCRIPT_DIR}/gpu-compute/vulkan.sh"
    ;;
  none) info "Skipping GPU compute setup." ;;
esac

success "Post-install complete."
