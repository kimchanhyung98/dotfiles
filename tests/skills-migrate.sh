#!/bin/bash
#
# Regression checks for the shared skills cleanup script.

set -euo pipefail

SCRIPT_PATH="${1:?usage: skills-migrate.sh <script-path>}"

fail() {
    echo "    FAIL: $1"
    exit 1
}

TMPHOME="$(mktemp -d)"
ERRLOG="$(mktemp)"
trap 'rm -rf "$TMPHOME" "$ERRLOG"' EXIT

mkdir -p \
    "$TMPHOME/.claude/skills/demo" \
    "$TMPHOME/.agents/skills/legacy" \
    "$TMPHOME/.skills/current"

printf 'demo\n' > "$TMPHOME/.claude/skills/demo/SKILL.md"
printf 'legacy\n' > "$TMPHOME/.agents/skills/legacy/SKILL.md"
printf 'current\n' > "$TMPHOME/.skills/current/SKILL.md"

HOME="$TMPHOME" bash "$SCRIPT_PATH" 2>"$ERRLOG"

if grep -q 'command not found' "$ERRLOG"; then
    cat "$ERRLOG"
    fail "cleanup script called an undefined command"
fi

[ -f "$TMPHOME/.skills/current/SKILL.md" ] || fail "existing ~/.skills content was removed"
[ ! -e "$TMPHOME/.skills/demo" ] || fail "Claude legacy skill was copied into ~/.skills"
[ ! -e "$TMPHOME/.skills/legacy" ] || fail "Agents legacy skill was copied into ~/.skills"

[ ! -e "$TMPHOME/.claude/skills" ] || fail "Claude source skills directory was not removed"
[ ! -e "$TMPHOME/.agents/skills" ] || fail "Agents source skills directory was not removed"
