#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
load_config

ARCH=$(uname -m)

info "Enabling required RHEL10 repositories..."
sudo subscription-manager repos \
  --enable="rhel-10-for-${ARCH}-appstream-rpms" \
  --enable="rhel-10-for-${ARCH}-baseos-rpms" \
  --enable="codeready-builder-for-rhel-10-${ARCH}-rpms"

info "Adding CUDA repository..."
sudo dnf config-manager --add-repo \
  "https://developer.download.nvidia.com/compute/cuda/repos/rhel10/x86_64/cuda-rhel10.repo"
sudo dnf clean expire-cache

info "Installing kernel headers..."
sudo dnf install -y kernel-devel-matched kernel-headers

info "Installing CUDA drivers and libraries (version ${CFG_CUDA_VER})..."
sudo dnf install -y nvidia-driver-cuda
sudo dnf install -y \
  "cuda-nvcc-${CFG_CUDA_VER}" \
  "cuda-cudart-devel-${CFG_CUDA_VER}" \
  "cuda-libraries-devel-${CFG_CUDA_VER}"

append_if_missing 'export PATH=/usr/local/cuda/bin:$PATH' "$HOME/.bashrc"

info "Installing cuDNN and TensorRT..."
sudo dnf install -y libcudnn9-cuda-13

TENSORRT_RPM="/tmp/tensorrt.rpm"
wget "$CFG_TENSORRT_RPM_URL" -O "$TENSORRT_RPM"
sudo rpm -Uvh "$TENSORRT_RPM"
sudo dnf clean expire-cache
sudo dnf install -y libnvonnxparsers10 tensorrt
sudo rm -f "$TENSORRT_RPM"

info "Installing CUDA profilers (Nsight Systems ${CFG_NSIGHT_SYSTEMS_VER}, Compute ${CFG_NSIGHT_COMPUTE_VER})..."
sudo dnf install -y \
  "nsight-systems-${CFG_NSIGHT_SYSTEMS_VER}" \
  "nsight-compute-${CFG_NSIGHT_COMPUTE_VER}"
append_if_missing "export PATH=\$PATH:/opt/nvidia/nsight-compute/${CFG_NSIGHT_COMPUTE_VER}" "$HOME/.bashrc"

info "Configuring perf event access for profiling..."
echo 'kernel.perf_event_paranoid=2' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
echo 'options nvidia NVreg_RestrictProfilingToAdminUsers=0' | \
  sudo tee /etc/modprobe.d/nvidia-profiling.conf

info "Rebuilding initramfs and reloading nvidia modules..."
sudo dracut --force
sudo modprobe -r nvidia_uvm nvidia_drm nvidia_modeset nvidia && sudo modprobe nvidia

success "CUDA setup complete."
