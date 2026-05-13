#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

disks=$(sudo fdisk -l | grep -E "Disk /dev/(nvme|sd)" | awk '{print $2}' | tr -d ':')

if [[ -z "$disks" ]]; then
  warn "No disks found to benchmark."
  exit 0
fi

while IFS= read -r disk; do
  info "=== Benchmarking: $disk ==="

  if [[ "$disk" == *nvme* ]]; then
    smart_dev=$(echo "$disk" | sed 's/n[0-9]*$//')
    smart_flags="-d nvme"
  else
    smart_dev="$disk"
    smart_flags=""
  fi

  FIO_TMP="/tmp/fio-test-$(basename "$disk")"

  sudo hdparm -tT --direct "$disk"
  # shellcheck disable=SC2086
  sudo smartctl -H $smart_flags "$smart_dev"
  # shellcheck disable=SC2086
  sudo smartctl -a $smart_flags "$smart_dev"
  # shellcheck disable=SC2086
  sudo smartctl -t short $smart_flags "$smart_dev"

  sudo fio --name=seq-read --rw=read --bs=1M --size=1G \
    --filename="$disk" --direct=1 --numjobs=1 --runtime=30 \
    --time_based --group_reporting

  sudo fio --name=seq-write --rw=write --bs=1M --size=1G \
    --filename="$FIO_TMP" --direct=1 --numjobs=1 --runtime=30 \
    --time_based --group_reporting

  sudo fio --name=rand-rw --rw=randrw --bs=4k --size=1G \
    --filename="$FIO_TMP" --direct=1 --numjobs=4 --runtime=60 \
    --time_based --group_reporting

  sudo rm -f "$FIO_TMP"

  success "Done: $disk"
done <<< "$disks"
