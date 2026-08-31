#!/usr/bin/env bash

set -euo pipefail

test -d "$HOME/.skills"
test -L "$HOME/.claude/skills"
test -L "$HOME/.agents/skills"
test -L "$HOME/.kiro/skills"
test "$(readlink -f "$HOME/.claude/skills")" = "$HOME/.skills"
test "$(readlink -f "$HOME/.agents/skills")" = "$HOME/.skills"
test "$(readlink -f "$HOME/.kiro/skills")" = "$HOME/.skills"
test "$(readlink -f "$HOME/.claude/CLAUDE.md")" = "$HOME/AGENTS.md"
test "$(readlink -f "$HOME/.codex/AGENTS.md")" = "$HOME/AGENTS.md"
test "$(readlink -f "$HOME/.copilot/copilot-instructions.md")" = "$HOME/AGENTS.md"
test "$(readlink -f "$HOME/.kimi-code/AGENTS.md")" = "$HOME/AGENTS.md"
test "$(readlink -f "$HOME/.kiro/steering/AGENTS.md")" = "$HOME/AGENTS.md"
test "$(readlink -f "$HOME/.omp/agent/AGENTS.md")" = "$HOME/AGENTS.md"
test -f "$HOME/.skills/i-have-adhd/LICENSE"
test -f "$HOME/.skills/i-have-adhd/SKILL.md"
grep -Fqx 'disable-model-invocation: true' "$HOME/.skills/i-have-adhd/SKILL.md"
grep -Fq '$i-have-adhd in Codex for the current turn' "$HOME/.skills/i-have-adhd/SKILL.md"
grep -Fqx '  allow_implicit_invocation: false' "$HOME/.skills/i-have-adhd/agents/openai.yaml"
test ! -e "$HOME/.skills/i-have-adhd/agents/gemini.toml"
test -f "$HOME/.skills/tdd/SKILL.md"
