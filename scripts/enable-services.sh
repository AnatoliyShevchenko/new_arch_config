#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/../configs"

echo "==> Enabling services..."

sudo systemctl enable greetd
sudo systemctl enable tailscaled
sudo systemctl enable sshd

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

# Свой юнит: гасит буст AMD через /sys/devices/system/cpu/cpufreq/boost.
# Копирование и включение держим рядом, чтобы не следить за порядком между
# скриптами.
sudo cp "$CONFIGS_DIR/systemd/system/amd-boost-disable.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now amd-boost-disable

echo "==> Services enabled successfully!"
echo "Note: You may need to re-login for docker group to take effect."
