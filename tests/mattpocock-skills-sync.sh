#!/bin/bash
#
# Regression checks for mattpocock skills runtime sync.

set -euo pipefail

SYNC_SCRIPT="${1:?usage: mattpocock-skills-sync.sh <sync-script-path>}"

fail() {
    echo "    FAIL: $1"
    exit 1
}

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

SKILL_ROOTS=(
    "skills/engineering/diagnose"
    "skills/engineering/grill-with-docs"
    "skills/engineering/improve-codebase-architecture"
    "skills/engineering/prototype"
    "skills/engineering/setup-matt-pocock-skills"
    "skills/engineering/tdd"
    "skills/engineering/to-issues"
    "skills/engineering/to-prd"
    "skills/engineering/triage"
    "skills/engineering/zoom-out"
    "skills/productivity/grill-me"
    "skills/productivity/handoff"
    "skills/productivity/write-a-skill"
)

make_repo() {
    local version="$1"
    local repo="$2"
    local skill_root
    local skill_name

    mkdir -p "$repo"
    git -C "$repo" init >/dev/null 2>&1
    git -C "$repo" checkout -b main >/dev/null 2>&1

    printf 'MIT License\n' > "$repo/LICENSE"

    for skill_root in "${SKILL_ROOTS[@]}"; do
        skill_name="${skill_root##*/}"
        mkdir -p "$repo/$skill_root"
        printf '# %s\n\nversion=%s\n' "$skill_name" "$version" > "$repo/$skill_root/SKILL.md"
    done

    mkdir -p "$repo/skills/engineering/diagnose/scripts"
    printf '#!/bin/sh\n# version=%s\n' "$version" \
        > "$repo/skills/engineering/diagnose/scripts/hitl-loop.template.sh"
    printf 'ADR format version=%s\n' "$version" \
        > "$repo/skills/engineering/grill-with-docs/ADR-FORMAT.md"

    git -C "$repo" add .
    git -C "$repo" \
        -c user.name='dotfiles tests' \
        -c user.email='dotfiles-tests@example.invalid' \
        commit -m "fixtures $version" >/dev/null
}

REPO_V1="$TMPDIR/repo-v1"
REPO_V2="$TMPDIR/repo-v2"
make_repo "v1" "$REPO_V1"
make_repo "v2" "$REPO_V2"

HOME_DIR="$TMPDIR/home"
HOME="$HOME_DIR" MATTPOCOCK_SKILLS_REPO_URL="file://$REPO_V1" bash "$SYNC_SCRIPT" >/dev/null
TARGET_DIR="$HOME_DIR/.skills"

[ -f "$TARGET_DIR/diagnose/SKILL.md" ] || fail "diagnose skill was not installed"
grep -q 'version=v1' "$TARGET_DIR/diagnose/SKILL.md" || fail "initial skill content mismatch"
[ -f "$TARGET_DIR/diagnose/scripts/hitl-loop.template.sh" ] || fail "nested companion file was not copied"
grep -q 'version=v1' "$TARGET_DIR/diagnose/scripts/hitl-loop.template.sh" || \
    fail "nested companion file content mismatch"
[ -f "$TARGET_DIR/grill-with-docs/ADR-FORMAT.md" ] || fail "sibling companion file was not copied"
[ ! -e "$TARGET_DIR/diagnose/.mattpocock-skills-source" ] || fail "managed skill marker should not be written"
[ ! -e "$TARGET_DIR/.mattpocock-skills" ] || fail "runtime state directory should not be written"

printf 'stale\n' > "$TARGET_DIR/diagnose/removed-on-refresh.md"
printf 'stale\n' > "$TARGET_DIR/diagnose/scripts/removed-on-refresh.sh"
mkdir -p "$TARGET_DIR/.mattpocock-skills"

HOME="$HOME_DIR" MATTPOCOCK_SKILLS_REPO_URL="file://$REPO_V2" bash "$SYNC_SCRIPT" >/dev/null

grep -q 'version=v2' "$TARGET_DIR/diagnose/SKILL.md" || fail "rerun did not refresh skill content"
grep -q 'version=v2' "$TARGET_DIR/diagnose/scripts/hitl-loop.template.sh" || \
    fail "rerun did not refresh nested companion file"
[ ! -e "$TARGET_DIR/diagnose/removed-on-refresh.md" ] || fail "rerun did not replace skill directory"
[ ! -e "$TARGET_DIR/diagnose/scripts/removed-on-refresh.sh" ] || \
    fail "rerun did not replace nested skill directory content"
[ ! -e "$TARGET_DIR/.mattpocock-skills" ] || fail "stale runtime state directory was not removed"

REPLACE_HOME="$TMPDIR/replace-home"
mkdir -p "$REPLACE_HOME/.skills/grill-me"
printf 'replace-me\n' > "$REPLACE_HOME/.skills/grill-me/SKILL.md"

HOME="$REPLACE_HOME" MATTPOCOCK_SKILLS_REPO_URL="file://$REPO_V1" bash "$SYNC_SCRIPT" >/dev/null

grep -q 'version=v1' "$REPLACE_HOME/.skills/grill-me/SKILL.md" || \
    fail "selected skill was not replaced"
