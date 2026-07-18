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

expected="$repo_dir/.codex/config.toml"
if ! cmp -s "$expected" "$rendered"; then
    echo 'rendered Codex config differs from the repository config' >&2
    diff -u "$expected" "$rendered" >&2 || true
    exit 1
fi

codex_home="$test_home/codex-home"
mkdir -p "$codex_home"
cp "$rendered" "$codex_home/config.toml"
CODEX_HOME="$codex_home" codex --strict-config mcp-server </dev/null
