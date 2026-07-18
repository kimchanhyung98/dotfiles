#!/usr/bin/env bash

set -u

if [ "$#" -ne 1 ]; then
    echo "usage: tests/run.sh <environment>" >&2
    exit 2
fi

environment="$1"
tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
environment_root="$tests_root/$environment"

if [ ! -d "$environment_root" ]; then
    echo "[test][error] unknown environment: $environment" >&2
    exit 2
fi

passed=0
failed=0

while IFS= read -r test_file; do
    test_name="${test_file#"$tests_root/"}"
    echo "[test] $test_name"
    if bash "$test_file"; then
        echo "[test][pass] $test_name"
        passed=$((passed + 1))
    else
        echo "[test][fail] $test_name" >&2
        failed=$((failed + 1))
    fi
done < <(find "$environment_root" -mindepth 2 -type f -name '*.sh' | LC_ALL=C sort)

if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
    echo "[test][error] no test cases found for: $environment" >&2
    exit 1
fi

echo "[test] $environment: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
