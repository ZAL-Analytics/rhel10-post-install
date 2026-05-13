#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
load_config

info "Installing hardware testing tools..."
sudo dnf install -y memtester hdparm smartmontools fio

info "Running memory benchmark (${CFG_MEM_MB} MB, ${CFG_MEM_PASSES} pass(es))..."
sudo memtester "$CFG_MEM_MB" "$CFG_MEM_PASSES"

info "Running disk benchmarks..."
bash "${SCRIPT_DIR}/hw-testers/disks.sh"

success "Hardware tests complete."
