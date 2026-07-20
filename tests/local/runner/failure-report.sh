#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_case_env="$tests_root/lib/test-case-env.sh"
output_file="$(mktemp)"
trap 'rm -f "$output_file"' EXIT

if DOTFILES_TEST_CASE=fixture BASH_ENV="$test_case_env" \
    bash -c $'set -euo pipefail\nassert_value() {\n    test actual = expected\n}\nassert_value' \
    2>"$output_file"; then
    echo 'failing fixture unexpectedly succeeded' >&2
    exit 1
fi

test "$(wc -l < "$output_file" | tr -d ' ')" = "1"
grep -Eq \
    '^\[test\]\[error\] fixture:[0-9]+: exit 1: test actual = expected$' \
    "$output_file"
