#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test_case_env="$tests_root/lib/test-case-env.sh"

if output="$(
    DOTFILES_TEST_CASE=fixture BASH_ENV="$test_case_env" \
        bash -c $'set -euo pipefail\nassert_value() {\n    test actual = expected\n}\nassert_value' 2>&1
)"; then
    echo 'failing fixture unexpectedly succeeded' >&2
    exit 1
fi

test "$output" = \
    '[test][error] fixture:3: exit 1: test actual = expected'
