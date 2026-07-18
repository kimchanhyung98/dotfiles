#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
sync_script="$repo_dir/home/dot_local/bin/executable_mattpocock-skills-sync"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

skill_roots=(
    skills/engineering/codebase-design
    skills/engineering/diagnosing-bugs
    skills/engineering/domain-modeling
    skills/engineering/grill-with-docs
    skills/engineering/improve-codebase-architecture
    skills/engineering/prototype
    skills/engineering/setup-matt-pocock-skills
    skills/engineering/tdd
    skills/engineering/to-issues
    skills/engineering/to-prd
    skills/engineering/triage
    skills/productivity/grill-me
    skills/productivity/grilling
    skills/productivity/handoff
    skills/productivity/writing-great-skills
)

make_fixture_repo() {
    local version="$1"
    local fixture_repo="$2"
    local skill_root

    git init --quiet "$fixture_repo"
    git -C "$fixture_repo" checkout --quiet -b main
    printf 'MIT License\n' > "$fixture_repo/LICENSE"
    for skill_root in "${skill_roots[@]}"; do
        mkdir -p "$fixture_repo/$skill_root"
        printf '# fixture\n\nversion=%s\n' "$version" > "$fixture_repo/$skill_root/SKILL.md"
    done
    mkdir -p "$fixture_repo/skills/engineering/diagnosing-bugs/scripts"
    printf 'version=%s\n' "$version" > \
        "$fixture_repo/skills/engineering/diagnosing-bugs/scripts/helper.txt"
    git -C "$fixture_repo" add .
    git -C "$fixture_repo" \
        -c user.name='dotfiles tests' \
        -c user.email='dotfiles-tests@example.invalid' \
        commit --quiet -m "fixtures $version"
    git -C "$fixture_repo" tag v1.0.1
}

fixture_v1="$test_root/fixture-v1"
fixture_v2="$test_root/fixture-v2"
make_fixture_repo v1 "$fixture_v1"
make_fixture_repo v2 "$fixture_v2"

test_home="$test_root/home"
HOME="$test_home" MATTPOCOCK_SKILLS_REPO_URL="file://$fixture_v1" \
    bash "$sync_script" >/dev/null

grep -Fq 'version=v1' "$test_home/.skills/diagnosing-bugs/SKILL.md"
test -f "$test_home/.skills/diagnosing-bugs/scripts/helper.txt"

printf 'stale\n' > "$test_home/.skills/diagnosing-bugs/stale.txt"
mkdir -p "$test_home/.skills/.mattpocock-skills"
HOME="$test_home" MATTPOCOCK_SKILLS_REPO_URL="file://$fixture_v2" \
    bash "$sync_script" >/dev/null

grep -Fq 'version=v2' "$test_home/.skills/diagnosing-bugs/SKILL.md"
test ! -e "$test_home/.skills/diagnosing-bugs/stale.txt"
test ! -e "$test_home/.skills/.mattpocock-skills"
