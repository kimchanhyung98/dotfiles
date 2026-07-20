#!/usr/bin/env bash
set -euo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.hooks/pre_tool_use_common.sh
source "$hook_dir/pre_tool_use_common.sh"

project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
parent_dir="$(dirname "$project_root")"
deny() { hook_deny "Blocked modifying files outside sibling project directories: '$parent_dir' and everything above it are write-protected by repository policy."; }

extract_paths() {
  printf '%s\n' "$payload" | jq -r '.. | objects | to_entries[] | select((.key | test("(^|_)(file_)?path$|^file$|^filename$"; "i")) and (.value | type == "string")) | .value'
  if [ "$tool_name" = "apply_patch" ]; then
    printf '%s\n' "$payload" | jq -r '.. | strings' | sed -nE \
      -e 's/^\*\*\* (Add|Update|Delete) File: (.*)$/\2/p' \
      -e 's/^\*\*\* Move to: (.*)$/\1/p' \
      -e 's/^--- a\/(.*)$/\1/p' \
      -e 's/^\+\+\+ b\/(.*)$/\1/p'
  fi
}

resolve_path() {
  python3 -c 'import os, sys; print(os.path.realpath(os.path.join(sys.argv[2], sys.argv[1])))' "$1" "$cwd"
}

payload="$(cat)"
tool_name="$(printf '%s\n' "$payload" | jq -r '.tool_name // ""')"
cwd="$(printf '%s\n' "$payload" | jq -r '.cwd // empty')"
[ -n "$cwd" ] || cwd="$project_root"

while IFS= read -r file_path; do
  [ -n "$file_path" ] || continue
  resolved="$(resolve_path "$file_path")"
  case "$resolved" in
    "$parent_dir"/*/*) ;;
    /tmp/*|/private/tmp/*|/var/folders/*|/private/var/folders/*) ;;
    *)
      deny
      exit 0
      ;;
  esac
done < <(extract_paths)
