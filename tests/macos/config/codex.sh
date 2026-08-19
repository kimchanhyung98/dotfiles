#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
rendered="$test_home/config.toml"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/dot_codex/config.toml.tmpl" > "$rendered"

codex_home="$test_home/codex-home"
mkdir -p "$codex_home"
cp "$rendered" "$codex_home/config.toml"
CODEX_HOME="$codex_home" codex --strict-config mcp-server </dev/null
