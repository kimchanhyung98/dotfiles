#!/usr/bin/env bash

set -euo pipefail

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
test_home="$test_root/home"
fake_bin="$test_root/bin"
args_file="$test_root/chezmoi-args"
install_script="${CHEZMOI_TEST_INSTALL_SCRIPT:-/home/testuser/install.sh}"
mkdir -p "$test_home" "$fake_bin"

cat > "$fake_bin/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$CHEZMOI_ARGS"
EOF
chmod +x "$fake_bin/chezmoi"

HOME="$test_home" \
PATH="$fake_bin:$PATH" \
CHEZMOI_ARGS="$args_file" \
CODESPACES=true \
GITHUB_USER=TestUser \
GIT_COMMITTER_EMAIL=test@example.com \
CODESPACE_NAME=test-codespace \
    bash "$install_script" >/dev/null

test "$(cat "$args_file")" = 'init --apply --no-tty kimchanhyung98'
