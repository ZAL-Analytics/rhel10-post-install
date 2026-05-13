# rhel10-post-install

Post-install automation for RHEL 10 development workstations. Three equivalent methods: Bash scripts, Ansible, or Kickstart (automated install).

## Configuration

Edit **`config.json`** at the repo root before running anything:

```json
{
  "user":    { "name": "Your Name", "email": "you@example.com" },
  "ssh":     { "github_key_name": "github" },
  "claude":  { "model": "sonnet", ... },
  "cuda":    { "version": "13-1", "tensorrt_rpm_url": "...", ... },
  "hw_tests":{ "memory_mb": 2048, "memory_passes": 1 }
}
```

All targets (Bash, Ansible, Kickstart) read from this single file. Requires `jq` for Bash and Kickstart generation.

## Bash

```bash
cd bash/
chmod +x setup.sh
./setup.sh [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--skip-base` | Skip base package installation |
| `--skip-keys` | Skip SSH / git / Claude configuration |
| `--skip-hw-tests` | Skip hardware benchmark tests |
| `--gpu cuda\|vulkan\|both\|none` | GPU compute backend (default: `none`) |

```bash
./setup.sh --gpu cuda
./setup.sh --skip-base --skip-keys --skip-hw-tests --gpu vulkan
./setup.sh --gpu both
```

## Ansible

Requires `community.general` and `ansible.posix` collections. `config.json` is loaded automatically as vars.

```bash
cd ansible/
ansible-playbook -i inventory/hosts.yml site.yml

# Override flags on the command line
ansible-playbook -i inventory/hosts.yml site.yml \
  -e "gpu_backend=cuda" \
  -e "run_hw_tests=true"
```

## Kickstart

For automated RHEL10 minimal installs from scratch. GPU compute setup must be done after first boot.

1. Fill in `config.json`.
2. Generate the kickstart file:
   ```bash
   ./kickstart/generate.sh > kickstart/rhel10-minimal.ks
   ```
3. Edit `kickstart/rhel10-minimal.ks` to set disk, root password hash, and timezone, then serve it:
   ```bash
   inst.ks=http://your-server/kickstart/rhel10-minimal.ks
   ```

After first boot, run GPU setup:
```bash
bash/setup.sh --skip-base --skip-keys --skip-hw-tests --gpu cuda
```

## What gets installed

| Step | Packages / Actions |
|------|--------------------|
| Base | EPEL, kernel-devel, vim, git, wget, curl, rsync |
| Toolchain | gcc, clang, lld, cmake, ninja, python3, rust (rustup) |
| Keys & access | GitHub SSH key, git config, Claude Code settings |
| HW tests | memtester, hdparm + smartctl + fio per disk |
| GPU: cuda | nvidia-driver-cuda, CUDA, cuDNN, TensorRT, Nsight |
| GPU: vulkan | vulkan-loader, glslang, spirv-tools, shaderc (built), slang (built) |
