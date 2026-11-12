#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
homebrew_prefix="$test_home/homebrew"
fake_bin="$homebrew_prefix/bin"
call_log="$test_home/calls.log"
plugin_state="$test_home/plugins.json"
output_log="$test_home/output.log"
chezmoi_bin="$(command -v chezmoi)"
mkdir -p "$fake_bin"
configure_chezmoi_test_home "$test_home" "$homebrew_prefix"
ln -s "$(command -v jq)" "$fake_bin/jq"

cat > "$fake_bin/mock" <<'EOF'
#!/bin/bash
set -euo pipefail

command_name="${0##*/}"
printf '%s:%s\n' "$command_name" "$*" >> "$ORCA_TEST_ROOT/calls.log"
case "$command_name" in
    open)
        test "$*" = '-g /Applications/Orca.app'
        touch "$ORCA_TEST_ROOT/runtime-started"
        ;;
    sleep)
        test "$*" = '1'
        ;;
    orca)
        case "${2:-}" in
            list)
                test "$*" = 'plugin list --environment local --json'
                case "$ORCA_TEST_MODE" in
                    start) test -f "$ORCA_TEST_ROOT/runtime-started" ;;
                    timeout) exit 1 ;;
                    malformed) printf '{invalid json\n'; exit 0 ;;
                esac
                cat "$ORCA_TEST_ROOT/plugins.json"
                ;;
            install)
                test "$#" -eq 7
                test "$1" = 'plugin'
                test "$4 $5 $6 $7" = '--catalog official --environment local'
                case "$ORCA_TEST_MODE:$3" in
                    approval:stablyai.orca-docx|mixed:stablyai.orca-spreadsheet)
                        echo "orca plugin install $3 --approve test-fingerprint --environment local" >&2
                        exit 3
                        ;;
                    mixed:stablyai.orca-docx)
                        echo 'plugin_invalid fixture' >&2
                        exit 2
                        ;;
                esac
                jq --arg key "$3" \
                    '.result.plugins += [{pluginKey: $key, status: "idle", version: "fixture"}]' \
                    "$ORCA_TEST_ROOT/plugins.json" > "$ORCA_TEST_ROOT/plugins.next.json"
                mv "$ORCA_TEST_ROOT/plugins.next.json" "$ORCA_TEST_ROOT/plugins.json"
                ;;
            *) exit 1 ;;
        esac
        ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$fake_bin/mock"
for command_name in orca open sleep; do
    ln -s mock "$fake_bin/$command_name"
done

rendered="$test_home/orca-plugins.sh"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_after_10-orca-plugins.sh.tmpl" \
    > "$rendered"
bash -n "$rendered"

reset_plugins() {
    printf '%s\n' '{"ok":true,"result":{"plugins":[]}}' > "$plugin_state"
}

run_sync() {
    local mode="$1" expected_status="$2" actual_status=0
    : > "$call_log"
    rm -f "$test_home/runtime-started"
    HOME="$test_home" PATH="/usr/bin:/bin" \
        ORCA_TEST_ROOT="$test_home" ORCA_TEST_MODE="$mode" \
        bash "$rendered" > "$output_log" 2>&1 || actual_status=$?
    if [ "$expected_status" = nonzero ]; then
        test "$actual_status" -ne 0
    else
        test "$actual_status" -eq "$expected_status"
    fi
}

reset_plugins
run_sync normal 0
test "$(grep -c '^orca:plugin install ' "$call_log")" -eq 7
for plugin in oled-theme material-icons http systemd docx spreadsheet image-markup; do
    jq -e --arg key "stablyai.orca-$plugin" \
        '.result.plugins | any(.pluginKey == $key)' "$plugin_state" >/dev/null
done
if grep -Eq '^(open|sleep):' "$call_log"; then
    echo 'An available Orca runtime was unnecessarily opened or delayed' >&2
    exit 1
fi

cat > "$plugin_state" <<'EOF'
{"ok":true,"result":{"plugins":[
  {"pluginKey":"stablyai.orca-oled-theme","status":"disabled","version":"old-local"},
  {"pluginKey":"user.custom-plugin","status":"idle","version":"custom-local"}
]}}
EOF
run_sync normal 0
test "$(grep -c '^orca:plugin install ' "$call_log")" -eq 6
jq -e '.result.plugins | any(.pluginKey == "stablyai.orca-oled-theme" and .status == "disabled" and .version == "old-local")' \
    "$plugin_state" >/dev/null
jq -e '.result.plugins | any(.pluginKey == "user.custom-plugin" and .version == "custom-local")' \
    "$plugin_state" >/dev/null
cp "$plugin_state" "$test_home/preserved.json"
run_sync normal 0
cmp "$plugin_state" "$test_home/preserved.json"
if grep -q '^orca:plugin install ' "$call_log"; then
    echo 'Existing plugins were reinstalled' >&2
    exit 1
fi

reset_plugins
run_sync approval 3
grep -Fq -- '--approve test-fingerprint' "$output_log"
test "$(grep -c '^orca:plugin install ' "$call_log")" -eq 7
jq -e '.result.plugins | (any(.pluginKey == "stablyai.orca-docx") | not) and any(.pluginKey == "stablyai.orca-image-markup")' \
    "$plugin_state" >/dev/null

reset_plugins
run_sync mixed 1
grep -Fq 'plugin_invalid fixture' "$output_log"
grep -Fq -- '--approve test-fingerprint' "$output_log"
test "$(grep -c '^orca:plugin install ' "$call_log")" -eq 7
jq -e '.result.plugins | length == 5 and any(.pluginKey == "stablyai.orca-image-markup")' \
    "$plugin_state" >/dev/null

reset_plugins
run_sync start 0
test "$(grep -c '^open:' "$call_log")" -eq 1
test "$(grep -c '^sleep:' "$call_log")" -eq 1
test "$(grep -c '^orca:plugin install ' "$call_log")" -eq 7

reset_plugins
run_sync timeout 1
test "$(grep -c '^open:' "$call_log")" -eq 1
test "$(grep -c '^sleep:' "$call_log")" -eq 15
if grep -q '^orca:plugin install ' "$call_log"; then
    echo 'Plugins were installed before the runtime was ready' >&2
    exit 1
fi

reset_plugins
run_sync malformed nonzero
if grep -q '^orca:plugin install ' "$call_log"; then
    echo 'Malformed plugin inventory was accepted' >&2
    exit 1
fi

mv "$fake_bin/orca" "$test_home/orca-link"
run_sync normal 1
test ! -s "$call_log"
mv "$test_home/orca-link" "$fake_bin/orca"

# 승인 대기 실패를 chezmoi가 완료로 기록하지 않고 다음 apply에서 재시도한다.
fixture_home="$test_home/fixture-home"
fixture_source="$test_home/fixture-source"
mkdir -p "$fixture_source"
configure_chezmoi_test_home "$fixture_home" "$homebrew_prefix"
cp "$rendered" "$fixture_source/run_onchange_after_10-orca-plugins.sh"
reset_plugins
actual_status=0
HOME="$fixture_home" XDG_CONFIG_HOME="$fixture_home/.config" \
    ORCA_TEST_ROOT="$test_home" ORCA_TEST_MODE=approval \
    "$chezmoi_bin" --source "$fixture_source" apply > "$output_log" 2>&1 || actual_status=$?
test "$actual_status" -ne 0
: > "$call_log"
HOME="$fixture_home" XDG_CONFIG_HOME="$fixture_home/.config" \
    ORCA_TEST_ROOT="$test_home" ORCA_TEST_MODE=normal \
    "$chezmoi_bin" --source "$fixture_source" apply > "$output_log" 2>&1
test "$(grep -c '^orca:plugin install ' "$call_log")" -eq 1
grep -Fq 'orca:plugin install stablyai.orca-docx --catalog official --environment local' "$call_log"
: > "$call_log"
HOME="$fixture_home" XDG_CONFIG_HOME="$fixture_home/.config" \
    ORCA_TEST_ROOT="$test_home" ORCA_TEST_MODE=normal \
    "$chezmoi_bin" --source "$fixture_source" apply > "$output_log" 2>&1
test ! -s "$call_log"
