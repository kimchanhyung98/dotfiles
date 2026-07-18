#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_dir="$(cd "$tests_root/.." && pwd)"
chezmoi_source_dir="${CHEZMOI_TEST_SOURCE_DIR:-$repo_dir/home}"

configure_chezmoi_test_home() {
    local test_home="$1"
    local homebrew_prefix="${2:-$test_home/homebrew}"

    mkdir -p "$test_home/.config/chezmoi"
    cat > "$test_home/.config/chezmoi/chezmoi.toml" <<EOF
sourceDir = "$chezmoi_source_dir"

[data]
    name = "Test User"
    email = "test@example.com"
    deviceName = "test-device"
    hostname = "test-host"
    isAppleSilicon = true
    homebrewPrefix = "$homebrew_prefix"
EOF
}

run_chezmoi() {
    local test_home="$1"
    shift
    HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" chezmoi "$@"
}
