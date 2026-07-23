#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"

plist="$repo_dir/home/dot_config/openusage/OpenUsage.plist"
config="$test_home/.config/openusage/OpenUsage.plist"
fake_bin="$test_home/bin"
call_log="$test_home/openusage-calls.log"
test_app="$test_home/Applications/OpenUsage.app"
info_plist="$test_home/OpenUsage-Info.plist"

plutil -lint "$plist" >/dev/null
if plutil -p "$plist" | grep -Eq 'providerSnapshots|SULastCheckTime|SUUpdateGroupIdentifier|access_token|refresh_token'; then
    echo 'OpenUsage plist contains volatile or secret values' >&2
    exit 1
fi

mkdir -p "$(dirname "$config")" "$fake_bin"
cp "$plist" "$config"
plutil -create xml1 "$info_plist"
plutil -insert CFBundleShortVersionString -string 0.7.6 "$info_plist"

cat > "$fake_bin/command" <<'EOF'
#!/bin/bash
set -eu

command_name="${0##*/}"
printf '%s:%s\n' "$command_name" "$*" >> "$OPENUSAGE_CALL_LOG"

case "$command_name" in
    curl)
        case "$*" in
            *releases/latest*)
                printf '%s' 'https://github.com/robinebers/openusage/releases/tag/v0.7.6'
                exit 0
                ;;
        esac
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
                    mkdir -p "$2/OpenUsage.app"
                    exit 0
                fi
                shift
            done
            exit 1
        fi
        ;;
    ditto)
        test -d "$1"
        mkdir -p "$2/Contents"
        cp "$OPENUSAGE_INFO_PLIST" "$2/Contents/Info.plist"
        ;;
    defaults)
        test "$1" = "import"
        test "$2" = "com.robinebers.openusage"
        test "$3" = "$OPENUSAGE_CONFIG"
        ;;
    killall)
        test "$1" = "OpenUsage"
        ;;
    open)
        test "$1" = "-g"
        test "$2" = "$OPENUSAGE_APP"
        exit "$OPENUSAGE_OPEN_STATUS"
        ;;
esac
EOF

chmod +x "$fake_bin/command"
for command_name in curl hdiutil ditto defaults killall open; do
    ln -s command "$fake_bin/$command_name"
done

rendered_source="$test_home/openusage-source.sh"
rendered="$test_home/openusage.sh"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_after_09-openusage.sh.tmpl" \
    > "$rendered_source"
sed "s|app=\"/Applications/OpenUsage.app\"|app=\"$test_app\"|" "$rendered_source" > "$rendered"

bash -n "$rendered"
grep -Fq 'repo="robinebers/openusage"' "$rendered"
grep -Fq 'releases/latest' "$rendered"
grep -Fq 'defaults import com.robinebers.openusage' "$rendered"
grep -Fq 'hdiutil attach' "$rendered"
grep -Fq 'killall OpenUsage' "$rendered"
grep -Fq 'install failed; skip' "$rendered"
grep -Fq '/usr/bin/plutil -extract CFBundleShortVersionString' "$rendered"
grep -Fq 'open -g "$app"' "$rendered"

OPENUSAGE_CALL_LOG="$call_log" \
OPENUSAGE_INFO_PLIST="$info_plist" \
OPENUSAGE_CONFIG="$config" \
OPENUSAGE_APP="$test_app" \
OPENUSAGE_OPEN_STATUS=1 \
HOME="$test_home" \
PATH="$fake_bin:/usr/bin:/bin" \
    bash "$rendered" > "$test_home/first-run.log" 2>&1

test -d "$test_app"
grep -Fq 'curl:-fsSL -o /dev/null -w %{url_effective} https://github.com/robinebers/openusage/releases/latest' "$call_log"
grep -Fq 'https://github.com/robinebers/openusage/releases/download/v0.7.6/OpenUsage-0.7.6.dmg' "$call_log"
grep -Fq 'defaults:import com.robinebers.openusage' "$call_log"
grep -Fq "open:-g $test_app" "$call_log"
grep -Fq '[openusage][warning] installed but could not launch automatically' "$test_home/first-run.log"

: > "$call_log"
OPENUSAGE_CALL_LOG="$call_log" \
OPENUSAGE_INFO_PLIST="$info_plist" \
OPENUSAGE_CONFIG="$config" \
OPENUSAGE_APP="$test_app" \
OPENUSAGE_OPEN_STATUS=0 \
HOME="$test_home" \
PATH="$fake_bin:/usr/bin:/bin" \
    bash "$rendered" > "$test_home/second-run.log" 2>&1

grep -Fq '[openusage] 0.7.6 already installed' "$test_home/second-run.log"
grep -Fq 'defaults:import com.robinebers.openusage' "$call_log"
if grep -Fq 'OpenUsage-0.7.6.dmg' "$call_log"; then
    echo 'OpenUsage reinstalled the current version' >&2
    exit 1
fi
