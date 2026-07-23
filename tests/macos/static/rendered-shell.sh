#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

if ! command -v shellcheck >/dev/null 2>&1; then
    echo 'shellcheck is required for make test-macos' >&2
    exit 1
fi

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"

for script in \
    "$repo_dir"/home/.chezmoiscripts/*.sh.tmpl \
    "$repo_dir"/home/.chezmoiscripts/darwin/*.sh.tmpl; do
    rendered="$test_home/$(basename "$script" .tmpl)"
    run_chezmoi "$test_home" execute-template < "$script" > "$rendered"
    bash -n "$rendered"
    shellcheck -s bash -S warning "$rendered"
    if [ "$(basename "$script")" = "run_once_before_01-prerequisites.sh.tmpl" ]; then
        grep -Fq 'bash "$installer" --no-modify-path' "$rendered"
    fi
done
