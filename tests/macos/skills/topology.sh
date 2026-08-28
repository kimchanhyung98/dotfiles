#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
managed="$(run_chezmoi "$test_home" managed --include=all)"
skill_dir="$repo_dir/home/dot_skills/i-have-adhd"

grep -Fqx 'disable-model-invocation: true' "$skill_dir/SKILL.md"
grep -Fqx '  allow_implicit_invocation: false' "$skill_dir/agents/openai.yaml"
test ! -e "$skill_dir/agents/gemini.toml"

for target in \
    .claude/CLAUDE.md \
    .claude/skills \
    .codex/AGENTS.md \
    .copilot/copilot-instructions.md \
    .kimi-code/AGENTS.md \
    .kimi-code/config.toml \
    .omp/agent/AGENTS.md \
    .omp/agent/config.yml \
    .agents/skills \
    .kiro/agents/yolo.json \
    .kiro/settings/cli.json \
    .kiro/skills \
    .kiro/steering/AGENTS.md \
    .skills/i-have-adhd/LICENSE \
    .skills/i-have-adhd/SKILL.md \
    .skills/i-have-adhd/agents/openai.yaml \
    .local/bin/mattpocock-skills-sync; do
    grep -Fxq "$target" <<<"$managed"
done
