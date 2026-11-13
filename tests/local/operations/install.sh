#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
command_path="$repo_dir/install.sh"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

test_home="$test_root/home"
test_state="$test_root/state"
fake_bin="$test_root/bin"
host_os="$(uname -s)"
script_bin="$(command -v script)"
mkdir -p "$test_home" "$test_state" "$fake_bin"

cat > "$fake_bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'Darwin\n'
EOF
cat > "$fake_bin/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "$*" = 'init --apply kimchanhyung98'
test -t 0
printf 'fixture stdout\n'
printf 'fixture stderr\n' >&2
exit "$INSTALL_EXIT_CODE"
EOF
cat > "$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
echo 'Unexpected installer download' >&2
exit 99
EOF
cat > "$fake_bin/run-install" <<'EOF'
#!/usr/bin/env bash
status=0
/bin/bash "$INSTALL_COMMAND" < /dev/null || status=$?
printf '%s\n' "$status" > "$INSTALL_STATUS"
EOF
chmod +x "$fake_bin"/*

run_install() {
    local expected_status="$1" console_log="$2"
    local state_home="${3-$test_state}" runner_command
    local -a script_args
    if [ "$host_os" = Darwin ]; then
        script_args=(-q /dev/null "$fake_bin/run-install")
    else
        printf -v runner_command '%q' "$fake_bin/run-install"
        script_args=(-q -c "$runner_command" /dev/null)
    fi
    rm -f "$test_root/status"
    env -i HOME="$test_home" XDG_STATE_HOME="$state_home" \
        PATH="$fake_bin:/usr/bin:/bin" TERM=dumb \
        INSTALL_COMMAND="$command_path" INSTALL_STATUS="$test_root/status" \
        INSTALL_EXIT_CODE="$expected_status" \
        "$script_bin" "${script_args[@]}" < /dev/null > "$console_log" 2>&1
    test "$(cat "$test_root/status")" -eq "$expected_status"
}

assert_log() {
    local log_file="$1" console_log="$2" expected_status="$3" mode
    local timestamp='[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4}'
    grep -Eq '^install-[0-9]{8}-[0-9]{6}-[0-9]+\.log$' <<< "${log_file##*/}"
    grep -Eq "^\[install\]\[start\] $timestamp log=" "$log_file"
    grep -Eq "^\[install\]\[end\] $timestamp exit_code=$expected_status$" "$log_file"
    for output in 'fixture stdout' 'fixture stderr' '[install][start]' "exit_code=$expected_status"; do
        grep -Fq "$output" "$log_file"
        grep -Fq "$output" "$console_log"
    done
    case "$host_os" in
        Darwin) mode="$(stat -f '%Lp' "$log_file")" ;;
        Linux) mode="$(stat -c '%a' "$log_file")" ;;
    esac
    test "$mode" = 600
}

run_install 0 "$test_root/success.log"
shopt -s nullglob
logs=("$test_state"/dotfiles/logs/install-*.log)
test "${#logs[@]}" -eq 1
success_log="${logs[0]}"
assert_log "$success_log" "$test_root/success.log" 0
grep -Fq 'Dotfiles installation complete!' "$success_log"

run_install 37 "$test_root/failure.log"
logs=("$test_state"/dotfiles/logs/install-*.log)
test "${#logs[@]}" -eq 2
for log_file in "${logs[@]}"; do
    [ "$log_file" != "$success_log" ] || continue
    assert_log "$log_file" "$test_root/failure.log" 37
    grep -Fq '[install][error] Installation failed.' "$log_file"
    if grep -Fq 'Dotfiles installation complete!' "$log_file"; then
        echo 'Failed installation was reported as complete' >&2
        exit 1
    fi
done

run_install 0 "$test_root/default-state.log" ''
logs=("$test_home"/.local/state/dotfiles/logs/install-*.log)
test "${#logs[@]}" -eq 1
assert_log "${logs[0]}" "$test_root/default-state.log" 0
