#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================"
echo "  Arch + Hyprland + Noctalia Setup Script"
echo "================================"
echo

sudo sed -i 's/#ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen
sudo locale-gen

"$SCRIPT_DIR/scripts/install-packages.sh"

# Том до k3s: на /HDD-WD лежит hostPath jellyfin, и там же ставится
# drop-in, который упорядочивает остановку k3s с размонтированием.
"$SCRIPT_DIR/scripts/mount-volumes.sh"

"$SCRIPT_DIR/scripts/enable-services.sh"

"$SCRIPT_DIR/scripts/install-dev-tools.sh"

"$SCRIPT_DIR/scripts/set-environment.sh"

"$SCRIPT_DIR/scripts/copy-configs.sh"

# После copy-configs: бинды на геймпад и телевизор живут в hyprland.lua,
# а скрипты, которые они зовут, раскладывает couch-control.
"$SCRIPT_DIR/scripts/couch-control.sh"

echo
echo "================================"
echo "  Setup complete!"
echo "================================"
echo "Reboot to start using Hyprland with greetd."