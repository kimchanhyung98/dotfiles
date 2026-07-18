#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
validator="$repo_dir/.husky/validate-branch.cjs"
test_repo="$(mktemp -d)"
trap 'rm -rf "$test_repo"' EXIT

git -C "$test_repo" init -q
git -C "$test_repo" config user.name 'Dotfiles Test'
git -C "$test_repo" config user.email 'dotfiles-test@example.invalid'
git -C "$test_repo" commit -q --allow-empty -m 'test fixture'
git -C "$test_repo" branch -M main

(cd "$test_repo" && node "$validator")

git -C "$test_repo" checkout -q -b feature/v6
(cd "$test_repo" && node "$validator")

git -C "$test_repo" checkout -q -b Invalid-Name
if (cd "$test_repo" && node "$validator") >/dev/null 2>&1; then
    echo 'invalid current branch was accepted' >&2
    exit 1
fi
