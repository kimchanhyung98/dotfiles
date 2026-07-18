#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"

rectangle="$repo_dir/home/dot_config/rectangle/RectangleConfig.json"
stats="$repo_dir/home/dot_config/stats/Stats.plist"
jq empty "$rectangle"
plutil -lint "$stats" >/dev/null
if plutil -p "$stats" | grep -Eq 'NSOSPLastRootDirectory|remote_id|access_token|refresh_token'; then
    echo 'Stats plist contains machine-specific or secret values' >&2
    exit 1
fi

rendered="$test_home/app-settings.sh"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_after_05-app-settings.sh.tmpl" \
    > "$rendered"
bash -n "$rendered"
grep -Fq 'Application Support/Rectangle/RectangleConfig.json' "$rendered"
grep -Fq 'defaults import eu.exelban.Stats' "$rendered"
grep -Fq 'PlistBuddy' "$rendered"
grep -Fq 'remote_id' "$rendered"
if grep -Eq 'defaults write eu\.exelban\.Stats .*(access_token|refresh_token)' "$rendered"; then
    echo 'Stats setup writes secret values with defaults' >&2
    exit 1
fi
