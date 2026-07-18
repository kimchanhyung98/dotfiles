#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

test_home="$test_root/home"
fake_bin="$test_home/bin"
invoked="$test_root/chezmoi-invoked"
args_file="$test_root/chezmoi-args"
headless_log="$test_root/headless.log"
mkdir -p "$fake_bin"

cat > "$fake_bin/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'invoked\n' > "$CHEZMOI_INVOKED"
if [ ! -t 0 ]; then
    echo 'chezmoi stdin is not a terminal' >&2
    exit 1
fi
printf '%s\n' "$*" > "$CHEZMOI_ARGS"
EOF
chmod +x "$fake_bin/chezmoi"

if HOME="$test_home" \
    PATH="$fake_bin:$PATH" \
    CHEZMOI_INVOKED="$invoked" \
    CHEZMOI_ARGS="$args_file" \
    /usr/bin/perl -MPOSIX=setsid -e '
        $pid = fork();
        defined $pid or die "fork: $!\n";
        if ($pid) {
            waitpid($pid, 0);
            exit($? >> 8);
        }
        setsid() >= 0 or die "setsid: $!\n";
        open(STDIN, "<", "/dev/null") or die "stdin: $!\n";
        exec { $ARGV[0] } @ARGV or die "exec: $!\n";
    ' /bin/bash "$repo_dir/install.sh" >"$headless_log" 2>&1; then
    echo 'installer accepted a session without a controlling terminal' >&2
    exit 1
fi
test ! -e "$invoked"
grep -Fq 'This installer requires an interactive terminal' "$headless_log"

CHEZMOI_INVOKED="$invoked" \
CHEZMOI_ARGS="$args_file" \
TEST_HOME="$test_home" \
FAKE_BIN="$fake_bin" \
INSTALL_SCRIPT="$repo_dir/install.sh" \
    /usr/bin/expect -c '
        log_user 0
        set timeout 20
        set child_path "$env(FAKE_BIN):$env(PATH)"
        set command [format {cat "%s" | /bin/bash} $env(INSTALL_SCRIPT)]
        spawn env HOME=$env(TEST_HOME) PATH=$child_path \
            CHEZMOI_INVOKED=$env(CHEZMOI_INVOKED) \
            CHEZMOI_ARGS=$env(CHEZMOI_ARGS) \
            /bin/sh -c $command
        expect eof
        set result [wait]
        exit [lindex $result 3]
    '

test -f "$invoked"
test "$(cat "$args_file")" = 'init --apply kimchanhyung98'
