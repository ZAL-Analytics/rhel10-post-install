#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

SHADERC_REPO_DIR="/tmp/shaderc"
SLANG_REPO_DIR="/tmp/slang"

info "Installing Vulkan loader and dev tools..."
sudo dnf install -y \
  vulkan-loader vulkan-loader-devel vulkan-headers vulkan-validation-layers \
  glslang glslang-devel spirv-tools spirv-tools-devel spirv-headers-devel

info "Configuring NVIDIA Vulkan ICD..."
sudo mkdir -p /etc/vulkan/icd.d
sudo dnf install -y nvidia-driver-libs --setopt=install_weak_deps=False
sudo dnf autoremove -y

DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
info "Detected NVIDIA driver version: ${DRIVER_VER}"

sudo tee /etc/vulkan/icd.d/nvidia_icd.json << 'EOF'
{
    "file_format_version" : "1.0.0",
    "ICD": {
        "library_path": "libGLX_nvidia.so.0",
        "api_version" : "1.3"
    }
}
EOF

info "Building shaderc from source..."
require_cmd git cmake ninja python3
git clone https://github.com/google/shaderc "$SHADERC_REPO_DIR"
cd "$SHADERC_REPO_DIR"
python3 utils/git-sync-deps
mkdir build && cd build

cmake .. \
  -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DSHADERC_SKIP_TESTS=ON \
  -DSHADERC_SKIP_EXAMPLES=ON \
  -DSHADERC_ENABLE_SHARED_CRT=ON

ninja -j"$(nproc)"
sudo ninja install
sudo ldconfig
cd "$HOME"
rm -rf "$SHADERC_REPO_DIR"
success "shaderc installed."

info "Building slang from source..."
sudo dnf install -y libxml2-devel curl-devel
git clone https://github.com/shader-slang/slang "$SLANG_REPO_DIR"
cd "$SLANG_REPO_DIR"
git submodule update --init --recursive
mkdir build && cd build

cmake .. \
  -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DCMAKE_CXX_FLAGS="-w -Wno-error -DVK_USE_PLATFORM_HEADLESS_EXT" \
  -DCMAKE_C_FLAGS="-w -Wno-error -DVK_USE_PLATFORM_HEADLESS_EXT" \
  -DSLANG_ENABLE_TESTS=OFF \
  -DSLANG_ENABLE_EXAMPLES=OFF \
  -DSLANG_ENABLE_GFX=OFF \
  -DSLANG_ENABLE_SLANGD=OFF \
  -DSLANG_ENABLE_SLANG_RHI=OFF \
  -DSLANG_SLANG_LLVM_FLAVOR=DISABLE

ninja -j"$(nproc)"
sudo ninja install
sudo ldconfig
cd "$HOME"
rm -rf "$SLANG_REPO_DIR"
success "slang installed."

success "Vulkan setup complete."
