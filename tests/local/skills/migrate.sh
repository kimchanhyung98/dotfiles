#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
script_path="$repo_dir/home/.chezmoiscripts/run_once_before_00-skills-ssot-migrate.sh.tmpl"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

mkdir -p \
    "$test_home/.claude/skills/demo" \
    "$test_home/.agents/skills/legacy" \
    "$test_home/.codex/skills/old" \
    "$test_home/.skills/current"
printf 'demo\n' > "$test_home/.claude/skills/demo/SKILL.md"
printf 'legacy\n' > "$test_home/.agents/skills/legacy/SKILL.md"
printf 'old\n' > "$test_home/.codex/skills/old/SKILL.md"
printf 'current\n' > "$test_home/.skills/current/SKILL.md"

HOME="$test_home" bash "$script_path"

test ! -e "$test_home/.claude/skills"
test ! -e "$test_home/.agents/skills"
grep -Fxq 'old' "$test_home/.codex/skills/old/SKILL.md"
grep -Fxq 'current' "$test_home/.skills/current/SKILL.md"
test ! -e "$test_home/.local/share/dotfiles-backups"

ln -s ../.skills "$test_home/.claude/skills"
ln -s ../.skills "$test_home/.agents/skills"
HOME="$test_home" bash "$script_path"
HOME="$test_home" bash "$script_path"

test -L "$test_home/.claude/skills"
test -L "$test_home/.agents/skills"
test "$(readlink "$test_home/.claude/skills")" = '../.skills'
test "$(readlink "$test_home/.agents/skills")" = '../.skills'
grep -Fxq 'current' "$test_home/.skills/current/SKILL.md"
