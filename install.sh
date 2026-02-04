#!/bin/bash
#
# Install chezmoi and apply dotfiles
# Usage: curl -fsSL https://raw.githubusercontent.com/kimchanhyung98/dotfiles/main/install.sh | bash
#

set -eufo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo_error "This script is designed for macOS only."
    exit 1
fi

echo_info "Starting dotfiles installation..."

# Install chezmoi if not present
if ! command -v chezmoi &>/dev/null; then
    echo_info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
else
    echo_info "chezmoi is already installed."
fi

# Initialize and apply dotfiles
echo_info "Applying dotfiles with chezmoi..."
chezmoi init --apply kimchanhyung98

echo_info "Dotfiles installation complete!"
echo_info "Please restart your terminal to apply changes."
