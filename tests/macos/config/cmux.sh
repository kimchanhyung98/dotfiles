#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
rendered="$test_home/cmux.json"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/dot_config/cmux/cmux.json.tmpl" > "$rendered"

jq -e '
    type == "object"
    and .schemaVersion == 1
    and .automation.socketControlMode == "allowAll"
    and .automation.claudeCodeIntegration == true
    and .automation.workspaceAutoNaming == true
    and .automation.autoNamingAgent == "claude"
    and .terminal.agentHibernation.enabled == true
' "$rendered" >/dev/null
