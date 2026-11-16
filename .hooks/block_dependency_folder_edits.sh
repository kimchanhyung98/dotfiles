#!/usr/bin/env bash
set -euo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.hooks/pre_tool_use_common.sh
source "$hook_dir/pre_tool_use_common.sh"

blocked_dir='(^|/)(node_modules|vendor|\.venv|venv|__pycache__|\.git)(/|$)'
deny() { hook_deny "Blocked editing dependency/cache/internal directory by repository policy."; }

extract_paths() {
  printf '%s\n' "$payload" | jq -r '.. | objects | to_entries[] | select((.key | test("(^|_)(file_)?path$|^file$|^filename$"; "i")) and (.value | type == "string")) | .value'
  printf '%s\n' "$payload" | jq -r '.. | strings' | sed -nE \
    -e 's/^\*\*\* (Add|Update|Delete) File: (.*)$/\2/p' \
    -e 's/^\*\*\* Move to: (.*)$/\1/p' \
    -e 's/^--- a\/(.*)$/\1/p' \
    -e 's/^\+\+\+ b\/(.*)$/\1/p'
}

payload="$(cat)"
cwd="$(printf '%s\n' "$payload" | jq -r '.cwd // empty')"
[ -n "$cwd" ] || cwd="$PWD"
while IFS= read -r file_path; do
  [ -n "$file_path" ] || continue
  if ! resolved="$(python3 -c 'import os, sys; print(os.path.realpath(os.path.join(sys.argv[2], sys.argv[1])))' "$file_path" "$cwd")"; then
    deny
    exit 0
  fi
  if printf '%s\n' "$file_path" "$resolved" | grep -Eq "$blocked_dir"; then
    deny
    exit 0
  fi
done < <(extract_paths)
