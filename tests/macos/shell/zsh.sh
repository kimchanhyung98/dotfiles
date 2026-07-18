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
printf '%s\n' ':'
EOF
chmod +x "$homebrew_prefix/bin/brew"

env -i HOME="$test_home" PATH="/usr/bin:/bin" zsh -fc '
    source "$HOME/.config/zsh/20-path.zsh"
    source "$HOME/.config/zsh/20-path.zsh"
'
test "$(cat "$brew_count")" = "1"

rm -f "$homebrew_prefix/bin/brew"
missing_brew_stderr="$test_home/missing-brew.stderr"
env -i HOME="$test_home" PATH="/usr/bin:/bin" \
    zsh -fc 'source "$HOME/.config/zsh/20-path.zsh"' \
    >/dev/null 2>"$missing_brew_stderr"
test ! -s "$missing_brew_stderr"
