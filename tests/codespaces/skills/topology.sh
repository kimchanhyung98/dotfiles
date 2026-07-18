#!/usr/bin/env bash

set -euo pipefail

test -d "$HOME/.skills"
test -L "$HOME/.claude/skills"
test -L "$HOME/.agents/skills"
test "$(readlink -f "$HOME/.claude/CLAUDE.md")" = "$HOME/AGENTS.md"
test "$(readlink -f "$HOME/.codex/AGENTS.md")" = "$HOME/AGENTS.md"
test "$(readlink -f "$HOME/.copilot/copilot-instructions.md")" = "$HOME/AGENTS.md"
test -f "$HOME/.skills/tdd/SKILL.md"
