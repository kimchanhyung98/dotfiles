#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
codex_config="$test_home/.codex/config.toml"
source_config="$repo_dir/home/dot_codex/config.toml.tmpl"
project_config="$repo_dir/.codex/config.toml"
mkdir -p "$test_home/.codex"

run_chezmoi "$test_home" apply --include=files "$codex_config"
cmp "$source_config" "$codex_config"

for config in "$codex_config" "$project_config"; do
    run_chezmoi "$test_home" execute-template --with-stdin \
        '{{ fromToml .chezmoi.stdin | toJson }}' < "$config" \
        | jq -e '
            .model == "gpt-6-astra" and
            .model_reasoning_effort == "xhigh" and
            .plan_mode_reasoning_effort == "ultra" and
            .default_permissions == ":danger-full-access" and
            .approval_policy == "on-request" and
            .allow_login_shell == false and
            (has("sandbox_mode") | not) and
            (has("sandbox_workspace_write") | not) and
            .cli_auth_credentials_store == "auto" and
            .web_search == "live" and
            .agents.max_concurrent_threads_per_session == 12 and
            .agents.max_depth == 2 and
            (.agents | has("max_threads") | not) and
            .features.context_management.experimental_mode == true and
            .features.prevent_idle_sleep == true and
            .features.memories == true and
            .features.hooks == true and
            .features.code_mode.enabled == false and
            (.features.network_proxy // false) == false and
            .memories.generate_memories == true and
            .memories.use_memories == true and
            .tui.resume_cwd == "session" and
            .tui.notifications == false and
            .shell_environment_policy == {
                inherit: "all",
                ignore_default_excludes: false,
                set: {},
                experimental_use_profile: false,
                filters: {"AWS_*": "exclude", "AZURE_*": "exclude"}
            } and
            .apps._default.destructive_enabled == false and
            .apps._default.approvals_reviewer == "auto_review" and
            .apps._default.default_tools_approval_mode == "writes"
        ' >/dev/null

    # Keep the official sample, including unused examples, as the comparison baseline.
    grep -Fxq '# Core Model Selection' "$config"
    grep -Fxq '# max_context_tokens = 2000' "$config"
    grep -Fxq '# Canonical case-insensitive filters. "include" entries create an allowlist.' "$config"
    grep -Fxq '# [mcp_servers.github.oauth]' "$config"
    grep -Fxq '# OpenTelemetry (OTEL) - disabled by default' "$config"
done

cmp <(sed -n '/^#/p' "$source_config") <(sed -n '/^#/p' "$project_config")
run_chezmoi "$test_home" apply --include=files "$codex_config"
cmp "$source_config" "$codex_config"
