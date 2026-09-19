#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/../packages"

echo "==> Installing packages from official repositories..."
sudo pacman -S --needed --noconfirm - < "$PACKAGES_DIR/pacman.txt"

if ! command -v paru &> /dev/null; then
    echo "==> Installing Paru..."
    git clone https://aur.archlinux.org/paru.git
    cd paru && makepkg -si && cd ..
    rm -rf paru
fi

paru -S --needed --noconfirm - < "$PACKAGES_DIR/aur.txt"

echo "==> Packages installed successfully!"