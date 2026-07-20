#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_dir"

git diff --check
git diff --cached --check

list_shell_scripts() {
    local file
    while IFS= read -r file; do
        [ -f "$file" ] || continue
        case "$file" in
            *.tmpl) continue ;;
        esac
        if head -n 1 "$file" | grep -Eq '^#!.*(ba|z|k)?sh'; then
            printf '%s\n' "$file"
        fi
    done < <(git ls-files --cached --others --exclude-standard | LC_ALL=C sort)
}

while IFS= read -r script; do
    bash -n "$script"
done < <(list_shell_scripts)

while IFS= read -r zsh_file; do
    [ -f "$zsh_file" ] || continue
    zsh -n "$zsh_file"
done < <(git ls-files --cached --others --exclude-standard '*.zsh' | LC_ALL=C sort)

while IFS= read -r json_file; do
    [ -f "$json_file" ] || continue
    case "$json_file" in
        *.json) jq empty "$json_file" ;;
    esac
done < <(git ls-files --cached --others --exclude-standard | LC_ALL=C sort)

if command -v shellcheck >/dev/null 2>&1; then
    while IFS= read -r script; do
        shellcheck --severity=error "$script"
    done < <(list_shell_scripts)
else
    echo "[test][skip] shellcheck not found; skipping shellcheck lint" >&2
fi
