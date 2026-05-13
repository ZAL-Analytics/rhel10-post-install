#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

info "Installing EPEL repository..."
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm

info "Installing system packages..."
sudo dnf install -y kernel-devel htop

info "Installing text editors..."
sudo dnf install -y vim

info "Installing source control and file transfer tools..."
sudo dnf install -y git wget curl rsync

info "Installing C/C++ toolchain..."
sudo dnf install -y gcc gcc-c++ clang lld cmake ninja-build

info "Installing Python..."
sudo dnf install -y python3 python3-pip

info "Installing Rust via rustup..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
append_if_missing 'source "$HOME/.cargo/env"' "$HOME/.bashrc"

success "Base packages installed."
