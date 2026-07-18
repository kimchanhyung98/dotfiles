#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"

while IFS= read -r template; do
    run_chezmoi "$test_home" execute-template < "$template" >/dev/null
done < <(
    find "$repo_dir/home" -type f -name '*.tmpl' ! -name '.chezmoi.toml.tmpl' | \
        LC_ALL=C sort
)

dry_run_log="$test_home/dry-run.log"
if ! run_chezmoi "$test_home" apply --dry-run --exclude=externals \
    --refresh-externals=never >"$dry_run_log" 2>&1; then
    cat "$dry_run_log" >&2
    exit 1
fi
