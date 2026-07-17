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

# curl | bash로 실행해도 chezmoi 프롬프트는 제어 터미널에서 입력받는다.
if ! { exec 3</dev/tty; } 2>/dev/null; then
    echo_error "This installer requires an interactive terminal."
    exit 1
fi

trap 'echo "[install][error] Installation interrupted. Please re-run the script." >&2' EXIT

# 지원 OS 확인 (macOS, Linux만 지원)
OS="$(uname -s)"
if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
    echo_error "This script supports macOS and Linux only."
    exit 1
fi

if [[ "$OS" == "Linux" ]]; then
    if [[ ! -r /etc/os-release ]]; then
        echo_error "Cannot identify the Linux distribution."
        exit 1
    fi
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        echo_error "Linux support requires Ubuntu."
        exit 1
    fi
    if [[ "${CODESPACES:-false}" != "true" && "${VERSION_ID:-}" != "26.04" ]]; then
        echo_error "Native Linux support requires Ubuntu 26.04 LTS."
        exit 1
    fi
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
echo_info "Name (GitHub username and Git author), email, and device name are required."
chezmoi init --apply kimchanhyung98 <&3
exec 3>&-

echo_info "Dotfiles installation complete!"
echo_info "Please restart your terminal to apply changes."

trap - EXIT
