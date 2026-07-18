#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"

render_plist_json() {
    local source_file="$1"
    local name="$2"
    local rendered="$test_home/$name.plist"
    local json="$test_home/$name.json"
    run_chezmoi "$test_home" execute-template < "$source_file" > "$rendered"
    plutil -lint "$rendered" >/dev/null
    plutil -convert json -o "$json" "$rendered"
    printf '%s\n' "$json"
}

tokscale_json="$(render_plist_json \
    "$repo_dir/home/Library/LaunchAgents/ai.tokscale.submit.plist.tmpl" tokscale)"
dotfiles_json="$(render_plist_json \
    "$repo_dir/home/Library/LaunchAgents/dev.dotfiles.update.plist.tmpl" dotfiles)"
tokscale_submit="$test_home/tokscale-submit.sh"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/dot_config/tokscale/executable_submit.sh.tmpl" \
    > "$tokscale_submit"
bash -n "$tokscale_submit"
grep -Fq 'export TZ="Asia/Seoul"' "$tokscale_submit"
grep -Fq 'export TOKSCALE_DEVICE_NAME=' "$tokscale_submit"
grep -Fq 'bunx tokscale@latest whoami' "$tokscale_submit"
grep -Fq 'bunx tokscale@latest submit' "$tokscale_submit"

jq -e '
    .Label == "ai.tokscale.submit"
    and .RunAtLoad == false
    and ([.StartCalendarInterval[].Day] == [1,4,7,10,13,16,19,22,25,28])
    and ([.StartCalendarInterval[].Hour] | all(. == 14))
    and ([.StartCalendarInterval[].Minute] | all(. == 0))
' "$tokscale_json" >/dev/null
jq -e '
    .Label == "dev.dotfiles.update"
    and .RunAtLoad == false
    and ([.StartCalendarInterval[].Day] == [1,16])
    and ([.StartCalendarInterval[].Hour] | all(. == 14))
    and ([.StartCalendarInterval[].Minute] | all(. == 0))
' "$dotfiles_json" >/dev/null

for source_file in \
    "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_after_07-tokscale-launchd.sh.tmpl" \
    "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_after_08-dotfiles-update-launchd.sh.tmpl"; do
    rendered="$test_home/$(basename "$source_file" .tmpl)"
    run_chezmoi "$test_home" execute-template < "$source_file" > "$rendered"
    bash -n "$rendered"
    grep -Fq 'launchctl bootstrap "gui/${uid}" "$plist"' "$rendered"
    if grep -Eqi '(last[_-]?run|state[_-]?file|cache[_-]?file)' "$rendered"; then
        echo "launchd installer contains a state-file gate: $source_file" >&2
        exit 1
    fi
done
