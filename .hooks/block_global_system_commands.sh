#!/usr/bin/env bash
set -euo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.hooks/pre_tool_use_common.sh
source "$hook_dir/pre_tool_use_common.sh"

normalized_command="$(hook_normalized_command)"
deny() { hook_deny "Blocked global/system command by repository policy."; }
# `$HOME` is intentionally escaped and matched as command text.
system_path="(/($|[[:space:];&|()'\"])|~|\\\$HOME|/(etc|usr|bin|sbin|System|Library|Applications|opt|var)(/|[[:space:];&|()'\"]|$))"
command_prefix='((command|env)[[:space:]]+)*'
executable_prefix='(/[[:alnum:]_./-]*/)?'

if hook_grep_command "$normalized_command" "${HOOK_COMMAND_BOUNDARY}${command_prefix}${executable_prefix}(sudo|doas|su|dd)${HOOK_COMMAND_END}|${HOOK_COMMAND_BOUNDARY}${command_prefix}${executable_prefix}(mkfs([.][^[:space:]]*)?|diskutil[[:space:]]+erase)${HOOK_COMMAND_END}"; then
  deny
  exit 0
fi
if hook_grep_command "$normalized_command" "${HOOK_COMMAND_BOUNDARY}${command_prefix}${executable_prefix}(chmod|chown)[[:space:]][^;&|]*(-R|--recursive)[^;&|]*${system_path}|${HOOK_COMMAND_BOUNDARY}${command_prefix}${executable_prefix}rm[[:space:]][^;&|]*(-[^;&|[:space:]]*[rRf][^;&|[:space:]]*|--(recursive|force))[^;&|]*${system_path}"; then
  deny
  exit 0
fi
if hook_grep_command "$normalized_command" "(>|>>)[[:space:]]*(/etc|/usr|/bin|/sbin|/System|/Library|/Applications|/opt|~|\\\$HOME)(/|${HOOK_COMMAND_END})"; then
  deny
fi
