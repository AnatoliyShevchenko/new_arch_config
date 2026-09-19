#!/bin/bash

set -e

echo "==> Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

echo "==> Installing k3s..."
curl -sfL https://get.k3s.io | bash

echo "==> Dev tools installed successfully!"