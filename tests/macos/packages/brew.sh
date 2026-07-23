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
            if [[ " $* " == *" --no-upgrade "* ]]; then
                echo 'brew bundle fallback must preserve normal upgrades' >&2
                exit 1
            fi
            test "${HOMEBREW_BUNDLE_BREW_SKIP:-}" = 'xcodes'
            if [ ! -f "$TAP_STATE" ]; then
                rm -f "$TRUST_STATE"
                touch "$TAP_STATE"
            fi
            test -f "$TRUST_STATE"
            printf 'brew bundle\n' >> "$CALL_LOG"
            rm -f "$OUTDATED_STATE"
            touch "$BUNDLE_STATE"
        fi
        ;;
    list)
        test "${2:-}" = "--formula"
        test "${3:-}" = "--versions"
        test "${4:-}" = "xcodes"
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
    bundle)
        test "${2:-}" = "install"
        test "${3:-}" = "-f"
        test -f "${4:-}"
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
TAP_STATE="$tap_state" \
TRUST_STATE="$trust_state" \
OUTDATED_STATE="$outdated_state" \
CALL_LOG="$call_log" \
    bash "$rendered" >/dev/null

test "$(sed -n '1p' "$call_log")" = 'zb init'
test "$(sed -n '2p' "$call_log")" = 'zb bundle'
test "$(wc -l < "$call_log" | tr -d ' ')" = "2"
test ! -f "$bundle_state"
test -f "$outdated_state"

: > "$call_log"
custom_zerobrew_prefix="$test_home/custom-zerobrew"
mkdir -p "$custom_zerobrew_prefix/bin"
cp "$fake_bin/zb" "$custom_zerobrew_prefix/bin/zb"
PATH="/usr/bin:/bin" \
HOME="$test_home" \
ZEROBREW_PREFIX="$custom_zerobrew_prefix" \
HOMEBREW_PREFIX="$homebrew_prefix" \
BUNDLE_STATE="$bundle_state" \
TAP_STATE="$tap_state" \
TRUST_STATE="$trust_state" \
OUTDATED_STATE="$outdated_state" \
CALL_LOG="$call_log" \
    bash "$rendered" >/dev/null

test "$(sed -n '1p' "$call_log")" = 'zb init'
test "$(sed -n '2p' "$call_log")" = 'zb bundle'
test "$(wc -l < "$call_log" | tr -d ' ')" = "2"

: > "$call_log"
PATH="/usr/bin:/bin" \
HOME="$test_home" \
ZEROBREW_PREFIX="$test_home/absent-zerobrew" \
HOMEBREW_PREFIX="$homebrew_prefix" \
BUNDLE_STATE="$bundle_state" \
TAP_STATE="$tap_state" \
TRUST_STATE="$trust_state" \
OUTDATED_STATE="$outdated_state" \
CALL_LOG="$call_log" \
ZB_FAIL=1 \
    bash "$rendered" >/dev/null 2>&1

test "$(sed -n '1p' "$call_log")" = 'zb init'
test "$(sed -n '2p' "$call_log")" = 'zb bundle'
test "$(sed -n '3p' "$call_log")" = 'brew tap'
test "$(sed -n '4p' "$call_log")" = 'brew trust'
test "$(sed -n '5p' "$call_log")" = 'brew bundle'
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
TAP_STATE="$tap_state" \
TRUST_STATE="$trust_state" \
OUTDATED_STATE="$outdated_state" \
CALL_LOG="$call_log" \
    bash "$rendered" >/dev/null

test "$(sed -n '1p' "$call_log")" = 'brew tap'
test "$(sed -n '2p' "$call_log")" = 'brew trust'
test "$(sed -n '3p' "$call_log")" = 'brew bundle'
test -f "$bundle_state"
test ! -f "$outdated_state"
grep -Fq 'brew "pkgconf"' "$repo_dir/home/Brewfile"
if grep -Fq 'brew "pkg-config"' "$repo_dir/home/Brewfile"; then
    echo 'deprecated pkg-config formula remains in Brewfile' >&2
    exit 1
fi
grep -Fq 'cask "docker-desktop"' "$repo_dir/home/Brewfile"
