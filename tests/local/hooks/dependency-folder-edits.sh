#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
hook_path="$repo_dir/.hooks/block_dependency_folder_edits.sh"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

project="$test_root/project with spaces"
mkdir -p "$project/node_modules/pkg" "$project/src" "$test_root/shared-cache" "$test_root/cached-project"
ln -s node_modules "$project/alias"
ln -s alias "$project/alias-chain"
ln -s src "$project/source-alias"
ln -s "$test_root/shared-cache" "$test_root/cached-project/node_modules"
printf 'original\n' > "$project/node_modules/pkg/existing.js"
test_cwd="$project"

assert_decision() {
    local expected="$1" file_path="$2" tool_name="${3:-Write}" payload output
    payload="$(jq -cn --arg cwd "$test_cwd" --arg path "$file_path" --arg tool "$tool_name" '
        {cwd: $cwd, tool_name: $tool, tool_input:
            (if $tool == "apply_patch" then {input: ("*** Update File: " + $path)}
             else {file_path: $path} end)}
    ')"
    output="$(printf '%s\n' "$payload" | bash "$hook_path")"
    if [ "$expected" = deny ]; then
        if ! printf '%s\n' "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null; then
            echo "[test][error] expected deny: $tool_name $file_path" >&2
            exit 1
        fi
    elif [ -n "$output" ]; then
        echo "[test][error] expected allow: $tool_name $file_path" >&2
        exit 1
    fi
}

for tool_name in Write apply_patch; do
    assert_decision deny node_modules/pkg/new.js "$tool_name"
    assert_decision deny alias/pkg/new.js "$tool_name"
    assert_decision deny alias/pkg/existing.js "$tool_name"
    assert_decision deny alias-chain/pkg/new.js "$tool_name"
    assert_decision deny "$project/alias/pkg/new.js" "$tool_name"
    assert_decision deny "$test_root/cached-project/node_modules/new.js" "$tool_name"
    assert_decision allow src/new.js "$tool_name"
    assert_decision allow source-alias/new.js "$tool_name"
    assert_decision allow src/node_modules-extra.js "$tool_name"
done

test_cwd="$project/node_modules/pkg"
assert_decision deny new.js
test_cwd=""
(
    cd "$project"
    assert_decision deny alias/pkg/new.js
    assert_decision allow source-alias/new.js
)

test "$(cat "$project/node_modules/pkg/existing.js")" = original
test ! -e "$project/node_modules/pkg/new.js"
test ! -e "$test_root/shared-cache/new.js"
