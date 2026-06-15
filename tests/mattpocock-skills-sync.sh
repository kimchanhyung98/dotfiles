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

TARGET_DIR="$TMPDIR/skills"

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

make_archive() {
    local version="$1"
    local archive="$2"
    local root="$TMPDIR/upstream-$version/skills-main"
    local skill_root
    local skill_name

    mkdir -p "$root"
    printf 'MIT License\n' > "$root/LICENSE"

    for skill_root in "${SKILL_ROOTS[@]}"; do
        skill_name="${skill_root##*/}"
        mkdir -p "$root/$skill_root"
        printf '# %s\n\nversion=%s\n' "$skill_name" "$version" > "$root/$skill_root/SKILL.md"
    done

    tar -czf "$archive" -C "$TMPDIR/upstream-$version" skills-main
}

ARCHIVE_V1="$TMPDIR/skills-v1.tar.gz"
ARCHIVE_V2="$TMPDIR/skills-v2.tar.gz"
make_archive "v1" "$ARCHIVE_V1"
make_archive "v2" "$ARCHIVE_V2"

TARGET_DIR="$TARGET_DIR" MATTPOCOCK_SKILLS_ARCHIVE="$ARCHIVE_V1" bash "$SYNC_SCRIPT" >/dev/null

[ -f "$TARGET_DIR/diagnose/SKILL.md" ] || fail "diagnose skill was not installed"
grep -q 'version=v1' "$TARGET_DIR/diagnose/SKILL.md" || fail "initial skill content mismatch"
[ -f "$TARGET_DIR/.mattpocock-skills/managed-skills.txt" ] || fail "managed manifest was not written"
[ -f "$TARGET_DIR/.mattpocock-skills/LICENSE" ] || fail "upstream license was not stored in runtime state"

printf 'stale\n' > "$TARGET_DIR/diagnose/removed-on-refresh.md"
mkdir -p "$TARGET_DIR/old-managed"
printf 'old-managed\n' >> "$TARGET_DIR/.mattpocock-skills/managed-skills.txt"

TARGET_DIR="$TARGET_DIR" MATTPOCOCK_SKILLS_ARCHIVE="$ARCHIVE_V2" bash "$SYNC_SCRIPT" >/dev/null

grep -q 'version=v2' "$TARGET_DIR/diagnose/SKILL.md" || fail "rerun did not refresh skill content"
[ ! -e "$TARGET_DIR/diagnose/removed-on-refresh.md" ] || fail "rerun did not replace managed skill directory"
[ ! -e "$TARGET_DIR/old-managed" ] || fail "stale managed skill was not removed"

mkdir -p "$TMPDIR/conflict/grill-me"
if TARGET_DIR="$TMPDIR/conflict" MATTPOCOCK_SKILLS_ARCHIVE="$ARCHIVE_V1" bash "$SYNC_SCRIPT" >/dev/null 2>&1; then
    fail "unmanaged conflicting skill was overwritten"
fi
