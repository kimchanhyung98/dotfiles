#!/usr/bin/env bash

set -euo pipefail

source_dir="${CHEZMOI_TEST_SOURCE_DIR:-$HOME/.local/share/chezmoi}"
while IFS= read -r -d '' script; do
    rendered="$(mktemp)"
    trap 'rm -f "$rendered"' EXIT
    chezmoi execute-template < "$script" > "$rendered"
    bash -n "$rendered"
    shellcheck -s bash -S warning "$rendered"
    rm -f "$rendered"
    trap - EXIT
done < <(
    find "$source_dir/.chezmoiscripts" "$source_dir/.chezmoiscripts/linux" \
        -maxdepth 1 -type f -name '*.sh.tmpl' -print0
)
