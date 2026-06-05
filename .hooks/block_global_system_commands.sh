#!/usr/bin/env bash
set -euo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$hook_dir/pre_tool_use_common.sh"

normalized_command="$(hook_normalized_command)"
deny() { hook_deny "Blocked global/system command by repository policy."; }
system_path='(/($|[[:space:]])|~|\$HOME|/(etc|usr|bin|sbin|System|Library|Applications|opt|var)(/|[[:space:]]|$))'
if hook_grep_command "$normalized_command" "${HOOK_COMMAND_BOUNDARY}(sudo|doas|su|dd)([[:space:]]|$)|${HOOK_COMMAND_BOUNDARY}(mkfs([.][^[:space:]]*)?|diskutil[[:space:]]+erase)([[:space:]]|$)"; then
  deny
  exit 0
fi
if hook_grep_command "$normalized_command" "${HOOK_COMMAND_BOUNDARY}(chmod|chown)[[:space:]][^;&|]*-R[^;&|]*${system_path}|${HOOK_COMMAND_BOUNDARY}rm[[:space:]][^;&|]*-(r|f|rf|fr)[^;&|]*${system_path}"; then
  deny
  exit 0
fi
if hook_grep_command "$normalized_command" "(>|>>)[[:space:]]*(/etc|/usr|/bin|/sbin|/System|/Library|/Applications|/opt|~|\$HOME)(/|[[:space:]]|$)"; then
  deny
fi
