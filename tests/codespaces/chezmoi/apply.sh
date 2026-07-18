#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/linux-apply.sh
source "$tests_root/lib/linux-apply.sh"

fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT
login_shell_before="$(getent passwd "$(id -un)" | cut -d: -f7)"
timezone_before="$(readlink -f /etc/localtime 2>/dev/null || true)"
linux_apply_dotfiles "$fixture_root"

test -f "$HOME/.zshrc"
test -f "$HOME/.gitconfig"
test -x "$HOME/.local/bin/dotfiles-doctor"
test ! -e "$HOME/.ssh/known_hosts"
test ! -e "$HOME/Documents/GitHub"
test "$(getent passwd "$(id -un)" | cut -d: -f7)" = "$login_shell_before"
test "$(readlink -f /etc/localtime 2>/dev/null || true)" = "$timezone_before"
