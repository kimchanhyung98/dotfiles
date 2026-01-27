#!/bin/bash
# Claude Code Stop Hook - 작업 완료 알림

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_PATH="${SCRIPT_DIR}/claude.png"

INPUT=$(cat)
MESSAGE_LENGTH=30
NOTIFY_SOUND="${CLAUDE_NOTIFY_SOUND:-Glass}"
HISTORY_FILE="${HOME}/.claude/history.jsonl"

get_project_name() {
    local cwd
    cwd=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
    [[ -n "$cwd" ]] && basename "$cwd" || echo "Claude Code"
}

get_prompt() {
    local session_id prompt
    session_id=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

    [[ -z "$session_id" || ! -f "$HISTORY_FILE" ]] && return

    prompt=$(grep "\"sessionId\":\"$session_id\"" "$HISTORY_FILE" 2>/dev/null | tail -1 | jq -r '.display // empty' 2>/dev/null)

    if [[ -n "$prompt" ]]; then
        local cleaned
        cleaned=$(echo "$prompt" | tr '\n' ' ' | sed 's/  */ /g')
        [[ ${#cleaned} -gt $MESSAGE_LENGTH ]] && echo "${cleaned:0:$MESSAGE_LENGTH}..." || echo "$cleaned"
    fi
}

get_status() {
    case "$1" in
        end_turn)      echo "✓" ;;
        max_tokens)    echo "⚠" ;;
        stop_sequence) echo "■" ;;
        tool_use)      echo "⚙" ;;
        *)             echo "●" ;;
    esac
}

get_sound() {
    case "$1" in
        end_turn)   echo "Glass" ;;
        max_tokens) echo "Basso" ;;
        *)          echo "$NOTIFY_SOUND" ;;
    esac
}

PROJECT_NAME=$(get_project_name)
REASON=$(echo "$INPUT" | jq -r '.stop_reason // empty' 2>/dev/null)
STATUS=$(get_status "$REASON")
PROMPT=$(get_prompt)
SOUND=$(get_sound "$REASON")

[[ -n "$PROMPT" ]] && MESSAGE="${STATUS} ${PROMPT}" || MESSAGE="${STATUS} 작업 완료"

terminal-notifier -title "$PROJECT_NAME" -message "$MESSAGE" -sound "$SOUND" -appIcon "$ICON_PATH"
exit 0
