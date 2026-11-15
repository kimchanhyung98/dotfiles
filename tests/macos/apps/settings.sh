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

# 원격 변경이 없어도 매번 macOS 설정과 배경화면을 복원하고 프로세스를 재시작한다.
fixture_seed="$test_home/settings-seed"
fixture_source="$test_home/settings-source"
fake_bin="$test_home/bin"
call_log="$test_home/settings-calls.log"
mkdir -p "$fixture_seed" "$fake_bin" "$test_home/Pictures/Wallpapers"
touch "$test_home/Pictures/Wallpapers/tahoe-untitled.png"
settings_scripts=("$repo_dir"/home/.chezmoiscripts/darwin/*-macos-settings.sh.tmpl)
test "${#settings_scripts[@]}" -eq 1
cp "${settings_scripts[0]}" "$fixture_seed/"
HOME="$test_home" git -C "$fixture_seed" init --quiet
HOME="$test_home" git -C "$fixture_seed" add .
HOME="$test_home" git -C "$fixture_seed" \
    -c user.name='dotfiles tests' -c user.email='dotfiles-tests@example.invalid' \
    commit --quiet -m initial
HOME="$test_home" git clone --quiet --bare "$fixture_seed" "$test_home/settings-remote.git"
HOME="$test_home" git clone --quiet "$test_home/settings-remote.git" "$fixture_source"

cat > "$fake_bin/mock" <<'EOF'
#!/bin/bash
set -euo pipefail
command_name="${0##*/}"
printf '%s:%s\n' "$command_name" "$*" >> "$HOME/settings-calls.log"
case "$command_name" in
    defaults)
        if [ "${1:-} ${2:-} ${3:-}" = 'write com.apple.dock tilesize' ]; then
            printf '%s\n' "$5" > "$HOME/dock-size"
        fi
        ;;
    killall | osascript) ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$fake_bin/mock"
for command_name in defaults killall osascript; do
    ln -s mock "$fake_bin/$command_name"
done

for attempt in 1 2; do
    printf '57\n' > "$test_home/dock-size"
    : > "$call_log"
    PATH="$fake_bin:$PATH" run_chezmoi "$test_home" --source "$fixture_source" \
        update --no-tty --force > "$test_home/settings-update.log" 2>&1
    test "$(cat "$test_home/dock-size")" = 48
    for process in Dock Finder SystemUIServer; do
        grep -Fxq "killall:$process" "$call_log"
    done
    grep -Fq "osascript:-e tell application \"System Events\" to tell every desktop to set picture to \"$test_home/Pictures/Wallpapers/tahoe-untitled.png\"" "$call_log"
    if [ "$attempt" -eq 1 ]; then
        cp "$call_log" "$test_home/first-settings-calls.log"
    else
        cmp "$call_log" "$test_home/first-settings-calls.log"
    fi
done
