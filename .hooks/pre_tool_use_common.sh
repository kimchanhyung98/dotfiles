#!/usr/bin/env bash

# Shared by the guard scripts that source this file.
# Quotes and parentheses can occur in arguments, so only shell separators are
# treated as command boundaries.
# shellcheck disable=SC2034
HOOK_COMMAND_BOUNDARY='(^|[;&|][[:space:]]*)'
# shellcheck disable=SC2034
HOOK_COMMAND_END='([[:space:];&|]|$)'

hook_command_text() {
  jq -jr '.tool_input.command // ""'
}

hook_normalized_command() {
  hook_command_text | tr '\n\t' '; ' | sed -E 's/[[:space:]]+/ /g'
}

hook_deny() {
  jq -cn --arg reason "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
}

hook_grep_command() {
  printf '%s\n' "$1" | grep -Eq "$2"
}
