#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
rendered="$test_home/settings.json"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/dot_claude/settings.json.tmpl" > "$rendered"

jq empty "$rendered"
diff -u "$repo_dir/.claude/settings.json" "$rendered"
jq -e '
    .permissions.deny
    | index("Edit(../**)") != null
      and index("Write(../**)") == null
' "$rendered" >/dev/null
