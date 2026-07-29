#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"

omp_config="$test_home/.omp/agent/config.yml"
source_config="$(run_chezmoi "$test_home" source-path "$omp_config")"

run_chezmoi "$test_home" apply --exclude=scripts,externals --refresh-externals=never
cmp "$source_config" "$omp_config"

printf 'modelRoles:\n  default: stale/model\n' > "$omp_config"
run_chezmoi "$test_home" apply --force --exclude=externals --refresh-externals=never "$omp_config"

cmp "$source_config" "$omp_config"
