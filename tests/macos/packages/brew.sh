#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
homebrew_prefix="$test_home/homebrew"
fake_bin="$test_home/bin"
call_log="$test_home/calls.log"
bundle_state="$test_home/bundle-satisfied"
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
        else
            printf 'brew bundle\n' >> "$CALL_LOG"
            touch "$BUNDLE_STATE"
        fi
        ;;
    *) exit 1 ;;
esac
EOF
cat > "$fake_bin/zb" <<'EOF'
#!/usr/bin/env sh
printf 'zb bundle\n' >> "$CALL_LOG"
exit 0
EOF
chmod +x "$homebrew_prefix/bin/brew" "$fake_bin/zb"

rendered="$test_home/brew-packages.sh"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_03-brew-packages.sh.tmpl" \
    > "$rendered"

PATH="$fake_bin:$PATH" \
HOMEBREW_PREFIX="$homebrew_prefix" \
BUNDLE_STATE="$bundle_state" \
CALL_LOG="$call_log" \
    bash "$rendered" >/dev/null

test "$(sed -n '1p' "$call_log")" = 'zb bundle'
test "$(sed -n '2p' "$call_log")" = 'brew bundle'
test -f "$bundle_state"
grep -Fq 'brew "pkgconf"' "$repo_dir/home/Brewfile"
if grep -Fq 'brew "pkg-config"' "$repo_dir/home/Brewfile"; then
    echo 'deprecated pkg-config formula remains in Brewfile' >&2
    exit 1
fi
grep -Fq 'cask "docker-desktop"' "$repo_dir/home/Brewfile"
