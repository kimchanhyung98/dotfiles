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

if ! awk '
    $0 == "include_only = []" { include_only = NR }
    $0 == "experimental_use_profile = false" { experimental_use_profile = NR }
    $0 == "[shell_environment_policy.set]" { set_table = NR; set_table_count++ }
    END {
        exit !(set_table_count == 1 &&
            include_only < set_table &&
            experimental_use_profile < set_table)
    }
' "$rendered"; then
    echo 'shell_environment_policy.set must be an explicit trailing table' >&2
    exit 1
fi

codex_home="$test_home/codex-home"
mkdir -p "$codex_home"
cp "$rendered" "$codex_home/config.toml"
CODEX_HOME="$codex_home" codex --strict-config mcp-server </dev/null
