#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

source_config="$repo_dir/home/dot_kimi-code/config.toml"

grep -Fxq 'default_model = "kimi-code/k3"' "$source_config"
grep -Fxq 'default_permission_mode = "auto"' "$source_config"
grep -Fxq 'pattern = "AgentSwarm"' "$source_config"
grep -Fxq 'telemetry = false' "$source_config"
grep -Fxq 'effort = "max"' "$source_config"

for guard in \
    block_git_origin_push \
    block_global_system_commands \
    block_global_package_install \
    block_pipe_to_shell \
    block_dependency_folder_edits \
    block_parent_directory_writes; do
    grep -Fq ".hooks/$guard.sh" "$source_config"
    test -x "$repo_dir/.hooks/$guard.sh"
done

kimi_bin="$(command -v kimi || true)"
[ -n "$kimi_bin" ] || kimi_bin="$HOME/.kimi-code/bin/kimi"
test -x "$kimi_bin"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
kimi_home="$test_home/kimi-home"
mkdir -p "$kimi_home"
cp "$source_config" "$kimi_home/config.toml"
KIMI_CODE_HOME="$kimi_home" "$kimi_bin" doctor
