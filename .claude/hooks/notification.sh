#!/bin/bash
# Claude Code Notification Hook - AskUserQuestion 알림

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_PATH="${SCRIPT_DIR}/claude.png"

INPUT=$(cat)
MESSAGE_LENGTH=30
NOTIFY_SOUND="${CLAUDE_NOTIFY_SOUND:-Purr}"

get_project_name() {
    local cwd
    cwd=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
    [[ -n "$cwd" ]] && basename "$cwd" || echo "Claude Code"
}

get_question() {
    local transcript_path question
    transcript_path=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

    [[ -z "$transcript_path" || ! -f "$transcript_path" ]] && echo "입력 대기 중" && return

    question=$(tail -100 "$transcript_path" 2>/dev/null | \
        jq -r '.message.content[]? | select(.type == "tool_use" and .name == "AskUserQuestion") | .input.questions[0].question' 2>/dev/null | \
        tail -1)

    if [[ -n "$question" && "$question" != "null" ]]; then
        local cleaned
        cleaned=$(echo "$question" | tr '\n' ' ' | sed 's/  */ /g')
        [[ ${#cleaned} -gt $MESSAGE_LENGTH ]] && echo "${cleaned:0:$MESSAGE_LENGTH}..." || echo "$cleaned"
    else
        echo "입력 대기 중"
    fi
}

PROJECT_NAME=$(get_project_name)
MESSAGE="💬 $(get_question)"

terminal-notifier -title "$PROJECT_NAME" -message "$MESSAGE" -sound "$NOTIFY_SOUND" -appIcon "$ICON_PATH"
exit 0
