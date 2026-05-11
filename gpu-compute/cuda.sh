#!/bin/bash

# ====== ENVS ======
CUDA_VER="13-1"
ARCH=$(uname -m)

# ====== Add Repos ======
## RHEL10 required repos by nvidia
sudo subscription-manager repos \
  --enable=rhel-10-for-${ARCH}-appstream-rpms \
  --enable=rhel-10-for-${ARCH}-baseos-rpms \
  --enable=codeready-builder-for-rhel-10-${ARCH}-rpms

## Add cuda repo
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel10/x86_64/cuda-rhel10.repo
sudo dnf clean expire-cache

# ====== Install kernel header ======
## Install DKMS kernel headers
sudo dnf install -y kernel-devel-matched kernel-headers

# ====== Install cuda drivers ======
sudo dnf install -y nvidia-driver-cuda
sudo dnf install -y cuda-nvcc-${CUDA_VER} cuda-cudart-devel-${CUDA_VER} cuda-libraries-devel-${CUDA_VER}
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# ====== Install tensortt sdk and tools ======
sudo dnf install -y libcudnn9-cuda-13

wget \
     "https://developer.download.nvidia.com/compute/tensorrt/10.16.1/local_installers/nv-tensorrt-local-repo-rhel9-10.16.1-cuda-13.2-1.0-1.x86_64.rpm" \
     -O /tmp/tensorrt-10.16.1.rpm

sudo rpm -Uvh /tmp/tensorrt-10.16.1.rpm
sudo dnf clean expire-cache
sudo dnf install -y libnvonnxparsers10
sudo dnf install -y tensorrt

sudo rm /tmp/tensorrt-10.16.1.rpm 

# ====== Install cuda profilers ======
sudo dnf install -y nsight-systems-2025.6.3 nsight-compute-2026.1.1
## Add and configure ncu for RHEL10
echo 'export PATH=$PATH:/opt/nvidia/nsight-compute/2026.1.1' >> ~/.bashrc
source "${HOME}/.bashrc"
echo 'kernel.perf_event_paranoid=2' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo 'options nvidia NVreg_RestrictProfilingToAdminUsers=0' | sudo tee /etc/modprobe.d/nvidia-profiling.conf
sudo dracut --force
sudo modprobe -r nvidia_uvm nvidia_drm nvidia_modeset nvidia && sudo modprobe nvidia
