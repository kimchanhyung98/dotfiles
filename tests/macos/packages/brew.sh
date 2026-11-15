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
            test "${BREW_FAIL:-}" != "check"
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
                echo 'brew bundle must preserve normal upgrades' >&2
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
            grep -q '^cask "stablyai/orca/orca"' "$bundle_file"
            test -f "${TAP_STATE}.orca"
            test -f "${TRUST_STATE}.orca"
            grep -q '^brew "git"' "$bundle_file"
            grep -q '^brew "dopplerhq/cli/doppler"' "$bundle_file"
            test -f "$TRUST_STATE"
            printf 'brew bundle full\n' >> "$CALL_LOG"
            test "${BREW_FAIL:-}" != "bundle"
            rm -f "$OUTDATED_STATE"
            touch "$BUNDLE_STATE"
        fi
        ;;
    list)
        test "${2:-}" = "--formula"
        test "${3:-}" = "--versions"
        test "${4:-}" = "xcodes"
        test "${XCODES_INSTALLED:-1}" = "1"
        ;;
    tap)
        case "${2:-}" in
            dopplerhq/cli)
                printf 'brew tap\n' >> "$CALL_LOG"
                test "${BREW_FAIL:-}" != "doppler-tap"
                if [ ! -f "$TAP_STATE" ]; then
                    rm -f "$TRUST_STATE"
                    touch "$TAP_STATE"
                fi
                ;;
            stablyai/orca)
                printf 'brew tap orca\n' >> "$CALL_LOG"
                test "${ORCA_FAIL:-}" != "tap"
                touch "${TAP_STATE}.orca"
                ;;
            *) exit 1 ;;
        esac
        ;;
    trust)
        case "${3:-}" in
            dopplerhq/cli/doppler)
                test "${2:-}" = "--formula"
                printf 'brew trust\n' >> "$CALL_LOG"
                test "${BREW_FAIL:-}" != "doppler-trust"
                touch "$TRUST_STATE"
                ;;
            stablyai/orca/orca)
                test "${2:-}" = "--cask"
                test -f "${TAP_STATE}.orca"
                printf 'brew trust orca\n' >> "$CALL_LOG"
                test "${ORCA_FAIL:-}" != "trust"
                touch "${TRUST_STATE}.orca"
                ;;
            *) exit 1 ;;
        esac
        ;;
    *) exit 1 ;;
esac
EOF
cat > "$fake_bin/zb" <<'EOF'
#!/usr/bin/env sh
printf 'unexpected zb %s\n' "$*" >> "$CALL_LOG"
exit 1
EOF
chmod +x "$homebrew_prefix/bin/brew" "$fake_bin/zb"

rendered="$test_home/brew-packages.sh"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_03-brew-packages.sh.tmpl" \
    > "$rendered"

run_sync() {
    HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin" \
        HOMEBREW_PREFIX="$homebrew_prefix" \
        BUNDLE_STATE="$bundle_state" TAP_STATE="$tap_state" \
        TRUST_STATE="$trust_state" OUTDATED_STATE="$outdated_state" \
        CALL_LOG="$call_log" bash "$rendered"
}

# 기존 xcodes는 유지하고, 새 설치에서는 전체 Brewfile에 포함한다.
for xcodes_installed in 0 1; do
    : > "$call_log"
    rm -f "$bundle_state" "$tap_state" "$trust_state" \
        "${tap_state}.orca" "${trust_state}.orca"
    touch "$outdated_state"
    XCODES_INSTALLED="$xcodes_installed" run_sync >/dev/null
    test "$(sed -n '1p' "$call_log")" = 'brew tap'
    test "$(sed -n '2p' "$call_log")" = 'brew trust'
    test "$(sed -n '3p' "$call_log")" = 'brew tap orca'
    test "$(sed -n '4p' "$call_log")" = 'brew trust orca'
    test "$(sed -n '5p' "$call_log")" = 'brew bundle full'
    test "$(wc -l < "$call_log" | tr -d ' ')" = "5"
    test -f "$bundle_state"
    test ! -f "$outdated_state"
done

# Doppler 준비, bundle 실행 또는 최종 설치 검사가 실패하면 적용도 실패한다.
for brew_fail in doppler-tap doppler-trust bundle check; do
    : > "$call_log"
    rm -f "$bundle_state" "$tap_state" "$trust_state" \
        "${tap_state}.orca" "${trust_state}.orca"
    if BREW_FAIL="$brew_fail" run_sync >/dev/null 2>&1; then
        echo "Homebrew $brew_fail failure did not stop package synchronization" >&2
        exit 1
    fi
done

# Orca tap 또는 trust가 실패하면 bundle 전에 중단한다.
for orca_fail in tap trust; do
    : > "$call_log"
    rm -f "$bundle_state" "$tap_state" "$trust_state" \
        "${tap_state}.orca" "${trust_state}.orca"
    if ORCA_FAIL="$orca_fail" run_sync >/dev/null 2>&1; then
        echo "Orca $orca_fail failure did not stop package synchronization" >&2
        exit 1
    fi
    grep -Fxq 'brew tap orca' "$call_log"
    if [ "$orca_fail" = "trust" ]; then
        grep -Fxq 'brew trust orca' "$call_log"
    elif grep -Fxq 'brew trust orca' "$call_log"; then
        echo 'Orca trust ran after tap failed' >&2
        exit 1
    fi
    if grep -q '^brew bundle ' "$call_log"; then
        echo 'Homebrew bundle ran after Orca setup failed' >&2
        exit 1
    fi
    test ! -f "$bundle_state"
done

grep -Fq 'brew "pkgconf"' "$repo_dir/home/Brewfile"
if grep -Fq 'brew "pkg-config"' "$repo_dir/home/Brewfile"; then
    echo 'deprecated pkg-config formula remains in Brewfile' >&2
    exit 1
fi
grep -Fq 'cask "docker-desktop"' "$repo_dir/home/Brewfile"
