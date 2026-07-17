#!/usr/bin/env bash
set -euo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.hooks/pre_tool_use_common.sh
source "$hook_dir/pre_tool_use_common.sh"

normalized_command="$(hook_normalized_command)"
command_prefix='((command|env)[[:space:]]+)*'
download_command='(curl|wget|/[[:alnum:]_./-]*/(curl|wget))'
shell_command='(sh|bash|zsh|fish|/[[:alnum:]_./-]*/(sh|bash|zsh|fish))'

if hook_grep_command "$normalized_command" "${HOOK_COMMAND_BOUNDARY}${command_prefix}${download_command}[^;&|]*[[:space:]]*[|][[:space:];]*(sudo[[:space:]]+)?${shell_command}${HOOK_COMMAND_END}"; then
  hook_deny "Blocked piping remote content directly into a shell."
fi
