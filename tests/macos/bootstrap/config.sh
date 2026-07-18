#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

interactive_home="$test_root/interactive-home"
fake_bin="$interactive_home/bin"
mkdir -p "$fake_bin" "$interactive_home/.config"
cat > "$fake_bin/scutil" <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
cat > "$fake_bin/brew" <<'EOF'
#!/usr/bin/env sh
if [ "${1:-}" = "--prefix" ]; then
    printf '%s\n' '/test/homebrew'
    exit 0
fi
exit 1
EOF
chmod +x "$fake_bin/scutil" "$fake_bin/brew"

HOME="$interactive_home" \
XDG_CONFIG_HOME="$interactive_home/.config" \
PATH="$fake_bin:$PATH" \
REPO_DIR="$repo_dir" \
CHEZMOI_BIN="$(command -v chezmoi)" \
    /usr/bin/expect -c '
        log_user 0
        set timeout 20
        spawn env HOME=$env(HOME) XDG_CONFIG_HOME=$env(XDG_CONFIG_HOME) PATH=$env(PATH) \
            $env(CHEZMOI_BIN) init --source $env(REPO_DIR)/home
        expect "Name (GitHub username and Git author)?"
        expect -re {> }
        send "Test User\r"
        expect "Email address?"
        expect -re {> }
        send "test@example.com\r"
        expect "Device name"
        expect -re {> }
        send "test-device\r"
        expect eof
        set result [wait]
        exit [lindex $result 3]
    '

config="$interactive_home/.config/chezmoi/chezmoi.toml"
grep -Fq 'name = "Test User"' "$config"
grep -Fq 'email = "test@example.com"' "$config"
grep -Fq 'deviceName = "test-device"' "$config"
grep -Fq 'homebrewPrefix = "/test/homebrew"' "$config"
grep -Eq '^    hostname = "[^"]+"$' "$config"

headless_home="$test_root/headless-home"
headless_log="$test_root/headless.log"
mkdir -p "$headless_home/.config"
if HOME="$headless_home" XDG_CONFIG_HOME="$headless_home/.config" \
    chezmoi init --no-tty --source "$repo_dir/home" >"$headless_log" 2>&1; then
    echo 'initial config accepted non-interactive input' >&2
    exit 1
fi
grep -Fq 'Initial configuration requires an interactive terminal' "$headless_log"
if grep -Eq 'YOUR_NAME|YOUR_EMAIL' "$repo_dir/home/.chezmoi.toml.tmpl"; then
    echo 'chezmoi config template contains placeholder identity values' >&2
    exit 1
fi
