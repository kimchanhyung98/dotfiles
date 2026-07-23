#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"
# shellcheck source=tests/lib/zsh-config.sh
source "$tests_root/lib/zsh-config.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
test_zsh_config "$test_home" "$repo_dir/home"

homebrew_prefix="$test_home/homebrew"
brew_count="$test_home/brew-shellenv-count"
mkdir -p "$homebrew_prefix/bin"
cat > "$homebrew_prefix/bin/brew" <<'EOF'
#!/usr/bin/env sh

if [ "${1:-}" != "shellenv" ]; then
    exit 1
fi
count=0
if [ -f "$HOME/brew-shellenv-count" ]; then
    count="$(cat "$HOME/brew-shellenv-count")"
fi
printf '%s\n' "$((count + 1))" > "$HOME/brew-shellenv-count"
printf 'export PATH="%s/homebrew/bin:$PATH"\n' "$HOME"
EOF
chmod +x "$homebrew_prefix/bin/brew"

zerobrew_prefix="$test_home/zerobrew"
mkdir -p "$zerobrew_prefix/bin"

path_value="$(
    env -i HOME="$test_home" ZEROBREW_PREFIX="$zerobrew_prefix" PATH="/usr/bin:/bin:$zerobrew_prefix/bin" zsh -fc '
        source "$HOME/.config/zsh/20-path.zsh"
        source "$HOME/.config/zsh/20-path.zsh"
        print -r -- "$PATH"
    '
)"
test "$(cat "$brew_count")" = "1"

# zerobrew는 중복 없이 한 번만, Homebrew보다 앞에 놓여야 한다.
path_entries="$(printf '%s\n' "$path_value" | tr ':' '\n')"
test "$(printf '%s\n' "$path_entries" | grep -cxF "$zerobrew_prefix/bin")" = "1"
zerobrew_line="$(printf '%s\n' "$path_entries" | grep -nxF "$zerobrew_prefix/bin" | cut -d: -f1)"
homebrew_line="$(printf '%s\n' "$path_entries" | grep -nxF "$homebrew_prefix/bin" | head -1 | cut -d: -f1)"
test "$zerobrew_line" -lt "$homebrew_line"

# zerobrew가 설치되지 않은 머신에서는 PATH를 건드리지 않는다.
absent_path="$(
    env -i HOME="$test_home" ZEROBREW_PREFIX="$test_home/absent" PATH="/usr/bin:/bin" zsh -fc '
        source "$HOME/.config/zsh/20-path.zsh"
        print -r -- "$PATH"
    '
)"
case ":$absent_path:" in
    *":$test_home/absent/bin:"*)
        echo 'missing zerobrew prefix must not be added to PATH' >&2
        exit 1
        ;;
esac

rm -f "$homebrew_prefix/bin/brew"
missing_brew_stderr="$test_home/missing-brew.stderr"
env -i HOME="$test_home" PATH="/usr/bin:/bin" \
    zsh -fc 'source "$HOME/.config/zsh/20-path.zsh"' \
    >/dev/null 2>"$missing_brew_stderr"
test ! -s "$missing_brew_stderr"

# 전체 update/upgrade는 두 관리자를 순서대로 처리하고, 대상 formula의 upgrade는
# zerobrew 실패 시에만 폴백한다. cask와 나머지 호출은 Homebrew로 전달된다.
routing_bin="$test_home/bin"
routing_log="$test_home/routing.log"
cat > "$routing_bin/zb" <<'EOF'
#!/usr/bin/env sh
printf 'zb %s\n' "$*" >> "$ROUTING_LOG"
if [ "${ZB_FAIL:-0}" = "1" ]; then
    exit 1
fi
EOF
cat > "$routing_bin/brew" <<'EOF'
#!/usr/bin/env sh
printf 'brew %s\n' "$*" >> "$ROUTING_LOG"
EOF
chmod +x "$routing_bin/zb" "$routing_bin/brew"

env -i HOME="$test_home" PATH="$routing_bin:/usr/bin:/bin" ROUTING_LOG="$routing_log" zsh -fc '
    source "$HOME/.config/zsh/30-functions.zsh"
    brew update
    brew upgrade
    brew upgrade jq
    brew upgrade --cask ghostty
    brew list
'
test "$(sed -n '1p' "$routing_log")" = 'zb update'
test "$(sed -n '2p' "$routing_log")" = 'brew update'
test "$(sed -n '3p' "$routing_log")" = 'zb upgrade'
test "$(sed -n '4p' "$routing_log")" = 'brew upgrade'
test "$(sed -n '5p' "$routing_log")" = 'zb upgrade jq'
test "$(sed -n '6p' "$routing_log")" = 'brew upgrade --cask ghostty'
test "$(sed -n '7p' "$routing_log")" = 'brew list'

env -i HOME="$test_home" PATH="$routing_bin:/usr/bin:/bin" ROUTING_LOG="$routing_log" ZB_FAIL=1 zsh -fc '
    source "$HOME/.config/zsh/30-functions.zsh"
    brew update
    brew upgrade
    brew upgrade jq
' >/dev/null 2>&1
test "$(sed -n '8p' "$routing_log")" = 'zb update'
test "$(sed -n '9p' "$routing_log")" = 'brew update'
test "$(sed -n '10p' "$routing_log")" = 'zb upgrade'
test "$(sed -n '11p' "$routing_log")" = 'brew upgrade'
test "$(sed -n '12p' "$routing_log")" = 'zb upgrade jq'
test "$(sed -n '13p' "$routing_log")" = 'brew upgrade jq'

chmod -x "$routing_bin/zb"
env -i HOME="$test_home" PATH="$routing_bin:/usr/bin:/bin" ROUTING_LOG="$routing_log" zsh -fc '
    source "$HOME/.config/zsh/30-functions.zsh"
    brew update
'
test "$(sed -n '14p' "$routing_log")" = 'brew update'
