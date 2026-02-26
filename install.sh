#!/bin/bash
#
# Install chezmoi and apply dotfiles
# Usage: curl -fsSL https://raw.githubusercontent.com/kimchanhyung98/dotfiles/main/install.sh | bash
#

set -eufo pipefail

# 출력 색상 정의
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

# 지원 OS 확인 (macOS, Linux만 지원)
OS="$(uname -s)"
if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
    echo_error "This script supports macOS and Linux only."
    exit 1
fi

echo_info "Detected OS: $OS"

echo_info "Starting dotfiles installation..."

# chezmoi 설치 (dotfile 관리 도구)
if ! command -v chezmoi &>/dev/null; then
    echo_info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
else
    echo_info "chezmoi is already installed."
fi

# dotfiles 초기화 및 적용
echo_info "Applying dotfiles with chezmoi..."
chezmoi init --apply kimchanhyung98

echo_info "Dotfiles installation complete!"
echo_info "Please restart your terminal to apply changes."
