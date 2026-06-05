#!/usr/bin/env bash

HOOK_COMMAND_BOUNDARY='(^|[;&|][[:space:]]*)'

hook_command_text() {
  jq -r '.tool_input.command // ""'
}

hook_normalized_command() {
  hook_command_text | tr '\n\t' '  ' | sed -E 's/[[:space:]]+/ /g'
}

hook_deny() {
  jq -cn --arg reason "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
}

hook_grep_command() {
  printf '%s\n' "$1" | grep -Eq "$2"
}
