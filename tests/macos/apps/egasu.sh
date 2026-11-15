#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
test_processes=""
cleanup() {
    local test_pid
    for test_pid in $test_processes; do
        kill "$test_pid" 2>/dev/null || true
    done
    rm -rf "$test_home"
}
trap cleanup EXIT
configure_chezmoi_test_home "$test_home"

plist="$repo_dir/home/dot_config/egasu/egasu.plist"
config="$test_home/.config/egasu/egasu.plist"
fake_bin="$test_home/bin"
call_log="$test_home/egasu-calls.log"
test_app="$test_home/Applications/egasu.app"
info_plist="$test_home/egasu-Info.plist"
defaults_plist="$test_home/egasu-defaults.plist"

plutil -lint "$plist" >/dev/null
if plutil -p "$plist" | grep -Eq 'providerSnapshots|"SU[A-Z]|betaUpdatesEnabled|settings.schemaVersion|access_token|refresh_token'; then
    echo 'egasu plist contains update preferences, volatile or secret values' >&2
    exit 1
fi

mkdir -p "$(dirname "$config")" "$fake_bin" "$test_home/Applications"
cp "$plist" "$config"
plutil -create xml1 "$info_plist"
plutil -insert CFBundleShortVersionString -string 1.0.0 "$info_plist"
plutil -insert CFBundleIdentifier -string com.kimchanhyung98.openusage "$info_plist"
plutil -create xml1 "$defaults_plist"
plutil -insert betaUpdatesEnabled -bool true "$defaults_plist"
plutil -insert SUAutomaticallyUpdate -bool false "$defaults_plist"
plutil -insert SUHasLaunchedBefore -bool true "$defaults_plist"
/usr/libexec/PlistBuddy -c 'Add :openusage.settings.schemaVersion integer 3' "$defaults_plist"

cat > "$fake_bin/command" <<'EOF'
#!/bin/bash
set -eu

command_name="${0##*/}"
printf '%s:%s\n' "$command_name" "$*" >> "$EGASU_CALL_LOG"

case "$command_name" in
    curl)
        case "$*" in
            *releases/latest*)
                printf '%s' "https://github.com/kimchanhyung98/egasu/releases/tag/v${EGASU_LATEST:-1.0.0}"
                exit 0
                ;;
        esac
        [ "${EGASU_DOWNLOAD_STATUS:-0}" -eq 0 ] || exit "$EGASU_DOWNLOAD_STATUS"
        output=""
        while [ "$#" -gt 0 ]; do
            if [ "$1" = "-o" ]; then
                output="$2"
                shift 2
            else
                shift
            fi
        done
        test -n "$output"
        touch "$output"
        ;;
    hdiutil)
        if [ "$1" = "attach" ]; then
            while [ "$#" -gt 0 ]; do
                if [ "$1" = "-mountpoint" ]; then
                    mkdir -p "$2/egasu.app"
                    exit 0
                fi
                shift
            done
            exit 1
        fi
        ;;
    ditto)
        test -d "$1"
        mkdir -p "$2/Contents/MacOS"
        cp "$EGASU_INFO_PLIST" "$2/Contents/Info.plist"
        [ "${EGASU_COPY_STATUS:-0}" -eq 0 ] || exit "$EGASU_COPY_STATUS"
        touch "$2/Contents/MacOS/egasu"
        chmod +x "$2/Contents/MacOS/egasu"
        ;;
    defaults)
        test "$1" = "import"
        test "$2" = "com.kimchanhyung98.openusage"
        test "$3" = "$EGASU_CONFIG"
        /usr/bin/defaults import "$EGASU_DEFAULTS" "$3"
        ;;
    pkill)
        test "$1" = '-f'
        test "$2" = "^${EGASU_APP//./[.]}/Contents/MacOS/egasu([[:space:]]|$)"
        exec /usr/bin/pkill "$@"
        ;;
    killall) exit 1 ;;
    open)
        test "$1" = "-g"
        test "$2" = "$EGASU_APP"
        exit "${EGASU_OPEN_STATUS:-0}"
        ;;
esac
EOF

chmod +x "$fake_bin/command"
for command_name in curl hdiutil ditto defaults pkill killall open; do
    ln -s command "$fake_bin/$command_name"
done

rendered_source="$test_home/egasu-source.sh"
rendered="$test_home/egasu.sh"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_after_09-egasu.sh.tmpl" \
    > "$rendered_source"
sed "s|app=\"/Applications/egasu.app\"|app=\"$test_app\"|" "$rendered_source" > "$rendered"

bash -n "$rendered"
grep -Fq 'repo="kimchanhyung98/egasu"' "$rendered"
grep -Fq 'releases/latest' "$rendered"
grep -Fq 'defaults import com.kimchanhyung98.openusage' "$rendered"
grep -Fq 'hdiutil attach' "$rendered"
grep -Fq 'install failed; skip' "$rendered"
grep -Fq 'open -g "$app"' "$rendered"

run_installer() {
    if [ "$#" -eq 0 ]; then
        set -- bash "$rendered"
    fi
    EGASU_CALL_LOG="$call_log" \
    EGASU_INFO_PLIST="$info_plist" \
    EGASU_CONFIG="$config" \
    EGASU_APP="$test_app" \
    EGASU_DEFAULTS="$defaults_plist" \
    HOME="$test_home" \
    XDG_CONFIG_HOME="$test_home/.config" \
    PATH="$fake_bin:$PATH" \
        "$@"
}

for failure in download copy bundle; do
    : > "$call_log"
    case "$failure" in
        download) EGASU_DOWNLOAD_STATUS=22 run_installer > "$test_home/failure.log" 2>&1 ;;
        copy) EGASU_COPY_STATUS=17 run_installer > "$test_home/failure.log" 2>&1 ;;
        bundle)
            plutil -replace CFBundleIdentifier -string com.example.invalid "$info_plist"
            run_installer > "$test_home/failure.log" 2>&1
            plutil -replace CFBundleIdentifier -string com.kimchanhyung98.openusage "$info_plist"
            ;;
    esac
    grep -Fq '[egasu][warning] install failed; skip' "$test_home/failure.log"
    test ! -e "$test_app"
    test -z "$(find "$test_home/Applications" -name '.egasu-install.*' -print)"
done

: > "$call_log"
EGASU_OPEN_STATUS=1 run_installer > "$test_home/first-run.log" 2>&1

test -d "$test_app"
test -x "$test_app/Contents/MacOS/egasu"
grep -Fq 'curl:-fsSL -o /dev/null -w %{url_effective} https://github.com/kimchanhyung98/egasu/releases/latest' "$call_log"
grep -Fq 'https://github.com/kimchanhyung98/egasu/releases/download/v1.0.0/egasu-1.0.0.dmg' "$call_log"
grep -Fq 'defaults:import com.kimchanhyung98.openusage' "$call_log"
grep -Fq "open:-g $test_app" "$call_log"
grep -Fq '[egasu][warning] installed but could not launch automatically' "$test_home/first-run.log"

printf 'installed app\n' > "$test_app/preserved"
for installed_version in 0.1.0 1.0.0 2.0.0-beta.1; do
    plutil -replace CFBundleShortVersionString -string "$installed_version" "$test_app/Contents/Info.plist"
    : > "$call_log"
    run_installer > "$test_home/existing-run.log" 2>&1
    grep -Fq '[egasu] already installed; updates are managed in-app' "$test_home/existing-run.log"
    if grep -Eq '^(curl|hdiutil|ditto):' "$call_log"; then
        echo 'egasu checked or replaced an existing installation' >&2
        exit 1
    fi
    test "$(plutil -extract CFBundleShortVersionString raw -o - "$test_app/Contents/Info.plist")" = "$installed_version"
    test "$(cat "$test_app/preserved")" = 'installed app'
    test "$(plutil -extract betaUpdatesEnabled raw -o - "$defaults_plist")" = true
    test "$(plutil -extract SUAutomaticallyUpdate raw -o - "$defaults_plist")" = false
    test "$(plutil -extract SUHasLaunchedBefore raw -o - "$defaults_plist")" = true
    test "$(/usr/libexec/PlistBuddy -c 'Print :openusage.settings.schemaVersion' "$defaults_plist")" = 3
done

rm -rf "$test_app"
plutil -replace CFBundleShortVersionString -string 1.2.3 "$info_plist"
: > "$call_log"
EGASU_LATEST=1.2.3 run_installer > "$test_home/latest-run.log" 2>&1
grep -Fq 'releases/download/v1.2.3/egasu-1.2.3.dmg' "$call_log"
test "$(plutil -extract CFBundleShortVersionString raw -o - "$test_app/Contents/Info.plist")" = 1.2.3

dev_app="$test_home/dist/egasu.app"
bash -c 'exec -a "$1/Contents/MacOS/egasu" /bin/sleep 60' _ "$test_app" &
installed_pid=$!
test_processes="$installed_pid"
bash -c 'exec -a "$1/Contents/MacOS/egasu" /bin/sleep 60' _ "$dev_app" &
dev_pid=$!
test_processes="$test_processes $dev_pid"
for _attempt in {1..20}; do
    if /usr/bin/pgrep -f "^${test_app//./[.]}/Contents/MacOS/egasu 60$" >/dev/null; then
        break
    fi
    sleep 0.05
done
/usr/bin/pgrep -f "^${test_app//./[.]}/Contents/MacOS/egasu 60$" >/dev/null
: > "$call_log"
run_installer > "$test_home/process-run.log" 2>&1
grep -q '^pkill:' "$call_log"
if wait "$installed_pid" 2>/dev/null; then
    echo 'egasu setup did not stop the installed app process' >&2
    exit 1
fi
test_processes="$dev_pid"
kill -0 "$dev_pid"
kill "$dev_pid"
wait "$dev_pid" 2>/dev/null || true
test_processes=""

fixture_source="$test_home/egasu-source"
mkdir -p "$fixture_source"
fixture_script="$fixture_source/run_onchange_after_09-egasu.sh"
cp "$rendered" "$fixture_script"
for attempt in 1 2 3; do
    if [ "$attempt" -eq 3 ]; then
        printf '\n# fixture source change\n' >> "$fixture_script"
    fi
    : > "$call_log"
    run_installer chezmoi --source "$fixture_source" --destination "$test_home" \
        --persistent-state "$test_home/egasu-state.boltdb" --refresh-externals=never \
        apply --no-tty > "$test_home/chezmoi-apply.log" 2>&1
    if [ "$attempt" -eq 2 ]; then
        test ! -s "$call_log"
    else
        grep -q '^defaults:import com.kimchanhyung98.openusage ' "$call_log"
        if grep -Eq '^(curl|hdiutil|ditto):' "$call_log"; then
            echo 'chezmoi apply attempted to update an installed egasu app' >&2
            exit 1
        fi
    fi
done
