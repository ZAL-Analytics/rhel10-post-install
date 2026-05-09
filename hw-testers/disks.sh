#!/bin/bash

disks=$(sudo fdisk -l | grep -E "Disk /dev/(nvme|sd)" | awk '{print $2}' | tr -d ':')

if [ -z "$disks" ]; then
  echo "No disks found to benchmark"
else
  while IFS= read -r disk; do
    echo "=== Benchmarking: $disk ==="

    if [[ "$disk" == *nvme* ]]; then
      smart_dev=$(echo "$disk" | sed 's/n[0-9]*$//')
      smart_flags="-d nvme"
    else
      smart_dev="$disk"
      smart_flags=""
    fi

    sudo hdparm -tT --direct "$disk"
    sudo smartctl -H $smart_flags "$smart_dev"
    sudo smartctl -a $smart_flags "$smart_dev"
    sudo smartctl -t short $smart_flags "$smart_dev"

    sudo fio --name=seq-read --rw=read --bs=1M --size=1G \
      --filename="$disk" --direct=1 --numjobs=1 --runtime=30 \
      --time_based --group_reporting

    sudo fio --name=seq-write --rw=write --bs=1M --size=1G \
      --filename=/tmp/fio-test --direct=1 --numjobs=1 --runtime=30 \
      --time_based --group_reporting

    sudo fio --name=rand-rw --rw=randrw --bs=4k --size=1G \
      --filename=/tmp/fio-test --direct=1 --numjobs=4 --runtime=60 \
      --time_based --group_reporting

    sudo rm -f /tmp/fio-test

    echo "=== Done: $disk ==="
  done <<< "$disks"
fi
