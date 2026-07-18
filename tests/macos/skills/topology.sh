#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
managed="$(run_chezmoi "$test_home" managed --include=all)"

for target in \
    .claude/CLAUDE.md \
    .claude/skills \
    .codex/AGENTS.md \
    .copilot/copilot-instructions.md \
    .agents/skills \
    .local/bin/mattpocock-skills-sync; do
    grep -Fxq "$target" <<<"$managed"
done
