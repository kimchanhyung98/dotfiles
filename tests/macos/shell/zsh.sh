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

path_value="$(
    env -i HOME="$test_home" PATH="/usr/bin:/bin" zsh -fc '
        source "$HOME/.config/zsh/20-path.zsh"
        source "$HOME/.config/zsh/20-path.zsh"
        print -r -- "$PATH"
    '
)"
test "$(cat "$brew_count")" = "1"
path_entries="$(printf '%s\n' "$path_value" | tr ':' '\n')"
test "$(printf '%s\n' "$path_entries" | grep -cxF "$homebrew_prefix/bin")" = "1"
test "$(printf '%s\n' "$path_entries" | grep -cxF "$test_home/.local/bin")" = "1"

# shellenv를 건너뛰는 중첩 로그인 셸에서도 Homebrew가 시스템 경로보다 앞에 온다.
nested_path="$(
    env -i HOME="$test_home" HOMEBREW_SHELLENV_LOADED=1 \
        PATH="/usr/bin:/bin:$homebrew_prefix/bin" zsh -fc '
            source "$HOME/.config/zsh/20-path.zsh"
            print -r -- "$PATH"
        '
)"
test "$(cat "$brew_count")" = "1"
nested_entries="$(printf '%s\n' "$nested_path" | tr ':' '\n')"
test "$(printf '%s\n' "$nested_entries" | grep -cxF "$homebrew_prefix/bin")" = "1"
homebrew_line="$(printf '%s\n' "$nested_entries" | grep -nxF "$homebrew_prefix/bin" | cut -d: -f1)"
system_line="$(printf '%s\n' "$nested_entries" | grep -nxF "/usr/bin" | cut -d: -f1)"
test "$homebrew_line" -lt "$system_line"

rm -f "$homebrew_prefix/bin/brew"
missing_brew_stderr="$test_home/missing-brew.stderr"
env -i HOME="$test_home" PATH="/usr/bin:/bin" \
    zsh -fc 'source "$HOME/.config/zsh/20-path.zsh"' \
    >/dev/null 2>"$missing_brew_stderr"
test ! -s "$missing_brew_stderr"

# 기존 래퍼 파일이 남아 있어도 새 셸은 Homebrew 명령을 직접 사용한다.
routing_bin="$test_home/bin"
cat > "$test_home/.config/zsh/30-functions.zsh" <<'EOF'
brew() { return 99; }
EOF
cat > "$routing_bin/brew" <<'EOF'
#!/usr/bin/env sh
printf 'brew %s\n' "$*"
EOF
chmod +x "$routing_bin/brew"
routing_output="$(
    env -i HOME="$test_home" ZDOTDIR="$test_home" PATH="$routing_bin:/usr/bin:/bin" \
        HOMEBREW_SHELLENV_LOADED=1 zsh -ic '
            (( ! $+functions[brew] )) || exit 1
            brew update
            brew upgrade jq
        ' 2>/dev/null
)"
test "$routing_output" = "$(printf 'brew update\nbrew upgrade jq')"

run_chezmoi "$test_home" apply --include=remove
test ! -e "$test_home/.config/zsh/30-functions.zsh"
