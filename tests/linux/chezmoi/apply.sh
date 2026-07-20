#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/linux-apply.sh
source "$tests_root/lib/linux-apply.sh"

fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT
linux_apply_dotfiles "$fixture_root"

test -f "$HOME/.zshrc"
test -f "$HOME/.gitconfig"
test -x "$HOME/.local/bin/dotfiles-doctor"
grep -Fq 'export EDITOR="vim"' "$HOME/.profile"
test "$(getent passwd "$(id -un)" | cut -d: -f7)" = "$(command -v zsh)"
test "$(readlink -f /etc/localtime)" = "/usr/share/zoneinfo/Asia/Seoul"
