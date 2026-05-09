#!/bin/bash

# ====== Install testing suits for hardware components ======
## Memory
sudo dnf install -y memtester

## Drives
sudo dnf install -y hdparm smartmontools fio

# ====== Run different benchmarks for hardware components ======
## Memory
sudo memtester 2048 1

## Drives
./post-install/disks.sh
