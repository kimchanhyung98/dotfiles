#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
command_path="$repo_dir/home/dot_local/bin/executable_dotfiles-update"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
export HOME="$test_root/home"
export XDG_CONFIG_HOME="$test_root/config"
export XDG_STATE_HOME="$test_root/state"
log_dir="$XDG_STATE_HOME/dotfiles/logs"

source_repo="$test_root/source"
fake_bin="$test_root/bin"
call_log="$test_root/chezmoi-calls.log"
console_log="$test_root/console.log"
mkdir -p "$source_repo" "$fake_bin" "$HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME"
git -C "$source_repo" init --quiet
printf 'tracked\n' > "$source_repo/tracked.txt"
git -C "$source_repo" add tracked.txt
git -C "$source_repo" \
    -c user.name='dotfiles tests' \
    -c user.email='dotfiles-tests@example.invalid' \
    commit --quiet -m initial

cat > "$fake_bin/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    source-path) printf '%s\n' "$SOURCE_REPO" ;;
    update | verify)
        printf '%s\n' "$*" >> "$CALL_LOG"
        printf 'fixture:%s:stdout\n' "$1"
        printf 'fixture:%s:stderr\n' "$1" >&2
        case "$UPDATE_SCENARIO:$1" in
            update-failure:update) exit 23 ;;
            update-signal-*:update)
                signal="${UPDATE_SCENARIO#update-signal-}"
                kill -0 -- "-$PPID"
                trap '' "$signal"
                kill "-$signal" -- "-$PPID"
                exit 0
                ;;
            verify-failure:verify) exit 37 ;;
        esac
        ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$fake_bin/chezmoi"

attempts=0
run_update() {
    local expected_status="$1" scenario="${2:-success}" actual_status=0
    local log_file mode
    : > "$call_log"
    attempts=$((attempts + 1))
    set -m
    PATH="$fake_bin:$PATH" SOURCE_REPO="$source_repo" CALL_LOG="$call_log" UPDATE_SCENARIO="$scenario" \
        /bin/bash "$command_path" > "$console_log" 2>&1 || actual_status=$?
    set +m
    test "$actual_status" -eq "$expected_status"
    test -d "$log_dir"
    logs=("$log_dir"/update-*.log)
    test "${#logs[@]}" -eq "$attempts"
    log_file="$(sed -n 's/^\[dotfiles-update\]\[start\] .* log=//p' "$console_log")"
    test "${log_file%/*}" = "$log_dir"
    test -f "$log_file"
    printf '%s\n' "${log_file##*/}" | grep -Eq '^update-[0-9]{8}-[0-9]{6}-[0-9]+\.log$'
    grep -Eq '^\[dotfiles-update\]\[start\] [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4} log=' "$log_file"
    grep -Eq "^\[dotfiles-update\]\[end\] [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4} exit_code=$expected_status\$" "$log_file"
    cmp "$console_log" "$log_file"
    case "$(uname -s)" in
        Darwin) mode="$(stat -f '%Lp' "$log_file")" ;;
        Linux) mode="$(stat -c '%a' "$log_file")" ;;
    esac
    test "$mode" = 600
}

for _ in 1 2; do
    run_update 0
    test "$(grep -Fc 'update --no-tty' "$call_log")" -eq 1
    test "$(grep -Fxc 'verify' "$call_log")" -eq 1
    for output in update:stdout update:stderr verify:stdout verify:stderr; do
        grep -Fxq "fixture:$output" "$console_log"
    done
done

run_update 23 update-failure
test "$(wc -l < "$call_log" | tr -d ' ')" -eq 1
grep -Fxq 'update --no-tty --force' "$call_log"
grep -Fxq 'fixture:update:stdout' "$console_log"
grep -Fxq 'fixture:update:stderr' "$console_log"

for signal_case in HUP:129 INT:130 TERM:143; do
    run_update "${signal_case#*:}" "update-signal-${signal_case%:*}"
    test "$(wc -l < "$call_log" | tr -d ' ')" -eq 1
    grep -Fxq 'update --no-tty --force' "$call_log"
done

run_update 37 verify-failure
test "$(wc -l < "$call_log" | tr -d ' ')" -eq 2
grep -Fxq 'update --no-tty --force' "$call_log"
grep -Fxq 'verify' "$call_log"
grep -Fxq 'fixture:verify:stdout' "$console_log"
grep -Fxq 'fixture:verify:stderr' "$console_log"
if grep -Fq '[dotfiles-update] complete' "$console_log"; then
    echo 'failed verification was reported as complete' >&2
    exit 1
fi

printf 'dirty\n' > "$source_repo/untracked.txt"
run_update 1
grep -Fq 'source repository has local changes' "$console_log"
test ! -s "$call_log"
