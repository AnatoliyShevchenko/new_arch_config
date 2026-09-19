#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/../configs"

echo "==> Copying configs..."

# User configs
mkdir -p ~/.config/{hypr,kitty,Code/User} ~/.local/state/noctalia

cp -r "$CONFIGS_DIR/hypr/." ~/.config/hypr/
cp -r "$CONFIGS_DIR/kitty/." ~/.config/kitty/
cp -r "$CONFIGS_DIR/zsh/." ~/
cp -r "$CONFIGS_DIR/noctalia/." ~/.local/state/noctalia/

cp "$CONFIGS_DIR/vscode/settings.json" ~/.config/Code/User/settings.json

# Манифесты k3s. Единственное, что копируется не ради программы с фиксированным
# путём, а ради человека: репозиторий после установки удаляется, а применять
# манифесты и править их надо будет и потом.
mkdir -p ~/k8s
cp -r "$CONFIGS_DIR/k8s/." ~/k8s/

echo "==> Installing VSCode extensions..."
while IFS= read -r ext; do
    code --install-extension "$ext" --force
done < "$CONFIGS_DIR/vscode/extensions.txt"

# System configs
sudo cp "$CONFIGS_DIR/greetd/config.toml" /etc/greetd/config.toml

echo "==> Configs copied successfully!"
