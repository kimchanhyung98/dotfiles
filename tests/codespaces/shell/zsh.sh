#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CHEZMOI_TEST_SOURCE_DIR="${CHEZMOI_TEST_SOURCE_DIR:-$HOME/.local/share/chezmoi}"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"
# shellcheck source=tests/lib/zsh-config.sh
source "$tests_root/lib/zsh-config.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
test_zsh_config "$test_home" "$CHEZMOI_TEST_SOURCE_DIR"
