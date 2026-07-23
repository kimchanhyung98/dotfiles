#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
homebrew_prefix="$test_home/homebrew"
fake_bin="$test_home/.local/bin"
call_log="$test_home/calls.log"
bundle_state="$test_home/bundle-satisfied"
homebrew_only_state="$test_home/homebrew-only-satisfied"
tap_state="$test_home/doppler-tapped"
trust_state="$test_home/doppler-trusted"
outdated_state="$test_home/outdated-package"
mkdir -p "$homebrew_prefix/bin" "$fake_bin"
configure_chezmoi_test_home "$test_home" "$homebrew_prefix"

cat > "$homebrew_prefix/bin/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    shellenv)
        printf 'export PATH="%s/bin:$PATH"\n' "$HOMEBREW_PREFIX"
        ;;
    bundle)
        if [ "${2:-}" = "check" ]; then
            test -f "$BUNDLE_STATE"
            if [[ " $* " != *" --no-upgrade "* ]]; then
                test ! -f "$OUTDATED_STATE"
            fi
        else
            bundle_file=""
            for argument in "$@"; do
                case "$argument" in
                    --file=*) bundle_file="${argument#--file=}" ;;
                esac
            done
            test -f "$bundle_file"
            if [[ " $* " == *" --no-upgrade "* ]]; then
                echo 'brew bundle fallback must preserve normal upgrades' >&2
                exit 1
            fi
            if [ "${XCODES_INSTALLED:-1}" = "1" ]; then
                test "${HOMEBREW_BUNDLE_BREW_SKIP:-}" = 'xcodes'
            else
                test -z "${HOMEBREW_BUNDLE_BREW_SKIP:-}"
            fi
            grep -q '^brew "ruby"' "$bundle_file"
            grep -q '^brew "xcodes"' "$bundle_file"
            grep -q '^cask "ghostty"' "$bundle_file"
            if grep -q '^brew "git"' "$bundle_file"; then
                grep -q '^brew "dopplerhq/cli/doppler"' "$bundle_file"
                test -f "$TRUST_STATE"
                printf 'brew bundle full\n' >> "$CALL_LOG"
                rm -f "$OUTDATED_STATE"
                touch "$BUNDLE_STATE"
            else
                test "$(grep -c '^brew ' "$bundle_file")" = "2"
                if grep -q '^brew "dopplerhq/cli/doppler"' "$bundle_file"; then
                    echo 'Homebrew-only Brewfile contains a zerobrew formula' >&2
                    exit 1
                fi
                test ! -f "$TAP_STATE"
                test ! -f "$TRUST_STATE"
                printf 'brew bundle homebrew-only\n' >> "$CALL_LOG"
                touch "$HOMEBREW_ONLY_STATE"
            fi
        fi
        ;;
    list)
        test "${2:-}" = "--formula"
        test "${3:-}" = "--versions"
        test "${4:-}" = "xcodes"
        test "${XCODES_INSTALLED:-1}" = "1"
        ;;
    tap)
        test "${2:-}" = "dopplerhq/cli"
        printf 'brew tap\n' >> "$CALL_LOG"
        if [ ! -f "$TAP_STATE" ]; then
            rm -f "$TRUST_STATE"
            touch "$TAP_STATE"
        fi
        ;;
    trust)
        test "${2:-}" = "--formula"
        test "${3:-}" = "dopplerhq/cli/doppler"
        printf 'brew trust\n' >> "$CALL_LOG"
        touch "$TRUST_STATE"
        ;;
    *) exit 1 ;;
esac
EOF
cat > "$fake_bin/zb" <<'EOF'
#!/usr/bin/env sh

case "${1:-}" in
    init)
        test "${2:-}" = "--no-modify-path"
        printf 'zb init\n' >> "$CALL_LOG"
        ;;
    list)
        printf 'zb list\n' >> "$CALL_LOG"
        if [ "${ZB_LIST_EMPTY:-0}" = "1" ]; then
            printf 'No formulas installed.\n'
        elif [ "${ZB_LIST_DISJOINT:-0}" = "1" ]; then
            printf 'manual-only 1.0.0\ncask:ghostty 1.0.0\n'
        else
            printf 'git 2.50.1\nruby 4.0.6\npkgconf 3.0.4\nmanual-only 1.0.0\ncask:ghostty 1.0.0\nxcodes 1.6.0\n'
        fi
        ;;
    upgrade)
        shift
        printf 'zb upgrade %s\n' "$*" >> "$CALL_LOG"
        if [ "$*" != "git pkgconf" ]; then
            echo "unexpected zerobrew upgrade targets: $*" >&2
            exit 1
        fi
        ;;
    bundle)
        test "${2:-}" = "install"
        test "${3:-}" = "-f"
        test -f "${4:-}"
        if grep -Eq '^brew "(ruby|xcodes)"' "${4:-}"; then
            echo 'zerobrew Brewfile contains a Homebrew-only formula' >&2
            exit 1
        fi
        grep -q '^brew "git"' "${4:-}"
        grep -q '^brew "dopplerhq/cli/doppler"' "${4:-}"
        if grep -q '^cask ' "${4:-}"; then
            echo 'zerobrew Brewfile contains a Homebrew-only cask' >&2
            exit 1
        fi
        printf 'zb bundle\n' >> "$CALL_LOG"
        if [ "${ZB_FAIL:-0}" = "1" ]; then
            exit 1
        fi
        ;;
esac
exit 0
EOF
chmod +x "$homebrew_prefix/bin/brew" "$fake_bin/zb"
touch "$outdated_state"

rendered="$test_home/brew-packages.sh"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_03-brew-packages.sh.tmpl" \
    > "$rendered"

PATH="/usr/bin:/bin" \
HOME="$test_home" \
ZEROBREW_PREFIX="$test_home/absent-zerobrew" \
HOMEBREW_PREFIX="$homebrew_prefix" \
BUNDLE_STATE="$bundle_state" \
HOMEBREW_ONLY_STATE="$homebrew_only_state" \
TAP_STATE="$tap_state" \
TRUST_STATE="$trust_state" \
OUTDATED_STATE="$outdated_state" \
CALL_LOG="$call_log" \
    bash "$rendered" >/dev/null

test "$(sed -n '1p' "$call_log")" = 'zb init'
test "$(sed -n '2p' "$call_log")" = 'zb list'
test "$(sed -n '3p' "$call_log")" = 'zb upgrade git pkgconf'
test "$(sed -n '4p' "$call_log")" = 'zb bundle'
test "$(sed -n '5p' "$call_log")" = 'brew bundle homebrew-only'
test "$(wc -l < "$call_log" | tr -d ' ')" = "5"
test ! -f "$bundle_state"
test -f "$homebrew_only_state"
test -f "$outdated_state"

: > "$call_log"
rm -f "$homebrew_only_state"
custom_zerobrew_prefix="$test_home/custom-zerobrew"
mkdir -p "$custom_zerobrew_prefix/bin"
cp "$fake_bin/zb" "$custom_zerobrew_prefix/bin/zb"
PATH="/usr/bin:/bin" \
HOME="$test_home" \
ZEROBREW_PREFIX="$custom_zerobrew_prefix" \
HOMEBREW_PREFIX="$homebrew_prefix" \
BUNDLE_STATE="$bundle_state" \
HOMEBREW_ONLY_STATE="$homebrew_only_state" \
TAP_STATE="$tap_state" \
TRUST_STATE="$trust_state" \
OUTDATED_STATE="$outdated_state" \
CALL_LOG="$call_log" \
ZB_LIST_EMPTY=1 \
XCODES_INSTALLED=0 \
    bash "$rendered" >/dev/null

test "$(sed -n '1p' "$call_log")" = 'zb init'
test "$(sed -n '2p' "$call_log")" = 'zb list'
test "$(sed -n '3p' "$call_log")" = 'zb bundle'
test "$(sed -n '4p' "$call_log")" = 'brew bundle homebrew-only'
test "$(wc -l < "$call_log" | tr -d ' ')" = "4"
test -f "$homebrew_only_state"

# 설치 목록이 비어 있지 않아도 Brewfile과 교집합이 없으면 upgrade를 건너뛴다.
: > "$call_log"
rm -f "$homebrew_only_state"
PATH="/usr/bin:/bin" \
HOME="$test_home" \
ZEROBREW_PREFIX="$test_home/absent-zerobrew" \
HOMEBREW_PREFIX="$homebrew_prefix" \
BUNDLE_STATE="$bundle_state" \
HOMEBREW_ONLY_STATE="$homebrew_only_state" \
TAP_STATE="$tap_state" \
TRUST_STATE="$trust_state" \
OUTDATED_STATE="$outdated_state" \
CALL_LOG="$call_log" \
ZB_LIST_DISJOINT=1 \
    bash "$rendered" >/dev/null

test "$(sed -n '1p' "$call_log")" = 'zb init'
test "$(sed -n '2p' "$call_log")" = 'zb list'
test "$(sed -n '3p' "$call_log")" = 'zb bundle'
test "$(sed -n '4p' "$call_log")" = 'brew bundle homebrew-only'
test "$(wc -l < "$call_log" | tr -d ' ')" = "4"
test -f "$homebrew_only_state"

: > "$call_log"
rm -f "$homebrew_only_state"
PATH="/usr/bin:/bin" \
HOME="$test_home" \
ZEROBREW_PREFIX="$test_home/absent-zerobrew" \
HOMEBREW_PREFIX="$homebrew_prefix" \
BUNDLE_STATE="$bundle_state" \
HOMEBREW_ONLY_STATE="$homebrew_only_state" \
TAP_STATE="$tap_state" \
TRUST_STATE="$trust_state" \
OUTDATED_STATE="$outdated_state" \
CALL_LOG="$call_log" \
ZB_FAIL=1 \
    bash "$rendered" >/dev/null 2>&1

test "$(sed -n '1p' "$call_log")" = 'zb init'
test "$(sed -n '2p' "$call_log")" = 'zb list'
test "$(sed -n '3p' "$call_log")" = 'zb upgrade git pkgconf'
test "$(sed -n '4p' "$call_log")" = 'zb bundle'
test "$(sed -n '5p' "$call_log")" = 'brew tap'
test "$(sed -n '6p' "$call_log")" = 'brew trust'
test "$(sed -n '7p' "$call_log")" = 'brew bundle full'
test -f "$tap_state"
test -f "$trust_state"
test -f "$bundle_state"
test ! -f "$outdated_state"

: > "$call_log"
rm -f "$bundle_state" "$tap_state" "$trust_state"
touch "$outdated_state"
chmod -x "$fake_bin/zb"

PATH="/usr/bin:/bin" \
HOME="$test_home" \
ZEROBREW_PREFIX="$test_home/absent-zerobrew" \
HOMEBREW_PREFIX="$homebrew_prefix" \
BUNDLE_STATE="$bundle_state" \
HOMEBREW_ONLY_STATE="$homebrew_only_state" \
TAP_STATE="$tap_state" \
TRUST_STATE="$trust_state" \
OUTDATED_STATE="$outdated_state" \
CALL_LOG="$call_log" \
    bash "$rendered" >/dev/null

test "$(sed -n '1p' "$call_log")" = 'brew tap'
test "$(sed -n '2p' "$call_log")" = 'brew trust'
test "$(sed -n '3p' "$call_log")" = 'brew bundle full'
test -f "$bundle_state"
test ! -f "$outdated_state"
grep -Fq 'brew "pkgconf"' "$repo_dir/home/Brewfile"
if grep -Fq 'brew "pkg-config"' "$repo_dir/home/Brewfile"; then
    echo 'deprecated pkg-config formula remains in Brewfile' >&2
    exit 1
fi
grep -Fq 'cask "docker-desktop"' "$repo_dir/home/Brewfile"
