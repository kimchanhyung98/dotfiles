#!/usr/bin/env bash
set -euo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$hook_dir/pre_tool_use_common.sh"

normalized_command="$(hook_normalized_command)"

if hook_grep_command "$normalized_command" "${HOOK_COMMAND_BOUNDARY}(curl|wget)[^;&|]*[[:space:]]*[|][[:space:]]*(sudo[[:space:]]+)?(sh|bash|zsh|fish)([[:space:]]|$)"; then
  hook_deny "Blocked piping remote content directly into a shell."
fi
