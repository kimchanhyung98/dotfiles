#!/usr/bin/env bash

set -euo pipefail

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
source_dir="${CHEZMOI_TEST_SOURCE_DIR:-$HOME/.local/share/chezmoi}"

HOME="$test_home" \
XDG_CONFIG_HOME="$test_home/.config" \
CODESPACES=true \
GITHUB_USER=TestUser \
GIT_COMMITTER_EMAIL=test@example.com \
CODESPACE_NAME=test-codespace \
    chezmoi init --no-tty --source "$source_dir"

config="$test_home/.config/chezmoi/chezmoi.toml"
grep -Fq 'name = "TestUser"' "$config"
grep -Fq 'email = "test@example.com"' "$config"
grep -Fq 'deviceName = "test-codespace"' "$config"

for missing in GITHUB_USER GIT_COMMITTER_EMAIL CODESPACE_NAME; do
    missing_home="$test_home/missing-$missing"
    mkdir -p "$missing_home/.config"
    if env HOME="$missing_home" \
        XDG_CONFIG_HOME="$missing_home/.config" \
        CODESPACES=true \
        GITHUB_USER=TestUser \
        GIT_COMMITTER_EMAIL=test@example.com \
        CODESPACE_NAME=test-codespace \
        "$missing=" \
            chezmoi init --no-tty --source "$source_dir" \
            >"$missing_home/stdout.log" 2>"$missing_home/stderr.log"; then
        echo "Codespaces config accepted an empty $missing" >&2
        exit 1
    fi
    grep -Fq "$missing is required" "$missing_home/stderr.log"
done
