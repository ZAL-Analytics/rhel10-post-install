#!/bin/bash

# ====== Setup repositoreies and keys ======
## EPEL Repo
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm

# ====== Install packages ======
## System
sudo dnf install -y kernel-devel htop

## Text editing and manupilation
sudo dnf install -y vim

## Source control and remote file management
sudo dnf install -y git wget curl rsync

## Coding and scripting

### C/C++
sudo dnf install -y gcc gcc-c++ clang lld cmake ninja-build

### Python
sudo dnf install -y python3 python3-pip

### Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

