#!/usr/bin/env bash
set -euo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$hook_dir/pre_tool_use_common.sh"

normalized_command="$(hook_normalized_command)"
deny() { hook_deny "Blocked global package installation by repository policy."; }

if hook_grep_command "$normalized_command" "${HOOK_COMMAND_BOUNDARY}(npm|pnpm|yarn)([[:space:]][^;&|]*)?[[:space:]]+(-(g|-[[:space:]]*global)|--global|global)([[:space:]]|$)"; then
  deny
  exit 0
fi

if hook_grep_command "$normalized_command" "${HOOK_COMMAND_BOUNDARY}((python3?|py)[[:space:]]+-m[[:space:]]+)?pip3?[[:space:]]+install[[:space:]][^;&|]*(--user|--break-system-packages)([[:space:]]|$)"; then
  deny
  exit 0
fi

if hook_grep_command "$normalized_command" "${HOOK_COMMAND_BOUNDARY}(cargo[[:space:]]+install|brew[[:space:]]+install|gem[[:space:]]+install|go[[:space:]]+install)([[:space:]]|$)"; then
  deny
fi
