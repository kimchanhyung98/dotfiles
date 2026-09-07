#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
codex_home="$test_home/.codex"
mkdir -p "$codex_home"
run_chezmoi "$test_home" apply --include=files "$codex_home/config.toml"
cmp "$repo_dir/home/dot_codex/config.toml.tmpl" "$codex_home/config.toml"

cd "$test_home"
env CODEX_HOME="$codex_home" codex app-server --strict-config --stdio </dev/null
