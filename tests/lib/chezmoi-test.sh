#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_dir="$(cd "$tests_root/.." && pwd)"
chezmoi_source_dir="${CHEZMOI_TEST_SOURCE_DIR:-$repo_dir/home}"

configure_chezmoi_test_home() {
    local test_home="$1"
    local homebrew_prefix="${2:-$test_home/homebrew}"
    local test_source="$test_home/.local/share/chezmoi-test"

    mkdir -p "$test_home/.config/chezmoi" "$test_source"
    # 외부 아카이브는 테스트 범위에서 제외하고 나머지 관리 소스를 그대로 검증한다.
    tar -C "$chezmoi_source_dir" --exclude='.chezmoiexternal.toml' -cf - . \
        | tar -C "$test_source" -xf -
    cat > "$test_home/.config/chezmoi/chezmoi.toml" <<EOF
sourceDir = "$test_source"
cacheDir = "$test_home/.cache/chezmoi"

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
