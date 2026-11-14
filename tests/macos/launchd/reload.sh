#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
updater_pid=""
worker_pid=""
cleanup() {
    if [ -n "$worker_pid" ]; then
        kill "$worker_pid" 2>/dev/null || true
        wait "$worker_pid" 2>/dev/null || true
    fi
    if [ -n "$updater_pid" ]; then
        kill "$updater_pid" 2>/dev/null || true
        wait "$updater_pid" 2>/dev/null || true
    fi
    if [ -f "$test_home/reload-script-path" ]; then
        rm -f "$(cat "$test_home/reload-script-path")"
    fi
    rm -rf "$test_home"
}
trap cleanup EXIT
configure_chezmoi_test_home "$test_home"
fake_bin="$test_home/bin"
call_log="$test_home/launchd-calls.log"
registrar="$test_home/register.sh"
mkdir -p "$fake_bin" "$test_home/Library/LaunchAgents" "$test_home/.local/bin"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/Library/LaunchAgents/dev.dotfiles.update.plist.tmpl" \
    > "$test_home/Library/LaunchAgents/dev.dotfiles.update.plist"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_after_08-dotfiles-update-launchd.sh.tmpl" \
    > "$registrar"
printf '#!/bin/bash\nexit 0\n' > "$test_home/.local/bin/dotfiles-update"
chmod +x "$test_home/.local/bin/dotfiles-update"

cat > "$fake_bin/mock" <<'EOF'
#!/bin/bash
set -euo pipefail
case "${0##*/}" in
    ps)
        if [ -f "$HOME/update.pid" ]; then cat "$HOME/update.pid"; else echo 1; fi
        ;;
    sleep)
        touch "$HOME/reload-waiting"
        /bin/sleep 0.02
        ;;
    launchctl)
        printf '%s\n' "$1" >> "$HOME/launchd-calls.log"
        case "$1" in
            list)
                if [ -f "$HOME/update.pid" ]; then
                    printf '%s\t0\tdev.dotfiles.update\n' "$(cat "$HOME/update.pid")"
                else
                    printf '%s\t0\tdev.dotfiles.update\n' '-'
                fi
                ;;
            submit)
                test "$2" = -l && test "$4" = -o && test "$6" = -e && test "$8" = --
                test "$5" = "$7"
                printf '%s\n' "$5" > "$HOME/reload-log-path"
                shift 8
                args=("$@")
                printf '%s\n' "${args[${#args[@]}-2]}" > "$HOME/reload-script-path"
                if [ -f "$HOME/submit-fails" ]; then exit 23; fi
                printf '%q ' "$@" > "$HOME/submitted.sh"
                ;;
            bootout)
                test ! -f "$HOME/update.pid"
                ;;
            bootstrap)
                test "$3" = "$HOME/Library/LaunchAgents/dev.dotfiles.update.plist"
                test ! -f "$HOME/bootstrap-fails"
                ;;
            enable | remove) ;;
            *) exit 1 ;;
        esac
        ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$fake_bin/mock"
for command_name in launchctl ps sleep; do ln -s mock "$fake_bin/$command_name"; done

run_registrar() {
    HOME="$test_home" XDG_STATE_HOME="$test_home/state" PATH="$fake_bin:$PATH" \
        bash "$registrar" > "$test_home/registrar.log" 2>&1
}

# 수동 적용은 즉시 재등록하고 독립 작업을 만들지 않는다.
run_registrar
test "$(grep -c '^bootstrap$' "$call_log")" -eq 1
test "$(grep -c '^enable$' "$call_log")" -eq 1
test ! -f "$test_home/submitted.sh"

for scenario in success bootstrap-failure; do
    : > "$call_log"
    rm -f "$test_home/reload-waiting"
    if [ "$scenario" = bootstrap-failure ]; then touch "$test_home/bootstrap-fails"; fi
    /bin/sleep 30 &
    updater_pid=$!
    printf '%s\n' "$updater_pid" > "$test_home/update.pid"
    run_registrar
    test "$(grep -c '^submit$' "$call_log")" -eq 1
    if grep -q '^bootout$' "$call_log"; then exit 1; fi
    reload_log="$(cat "$test_home/reload-log-path")"
    reload_script="$(cat "$test_home/reload-script-path")"
    test "$(stat -f '%Lp' "$reload_log")" = 600
    cmp "$registrar" "$reload_script"
    bash "$test_home/submitted.sh" >> "$reload_log" 2>&1 &
    worker_pid=$!
    for _ in {1..100}; do
        [ ! -f "$test_home/reload-waiting" ] || break
        /bin/sleep 0.01
    done
    test -f "$test_home/reload-waiting"
    if grep -q '^bootout$' "$call_log"; then exit 1; fi
    rm "$test_home/update.pid"
    kill "$updater_pid"
    wait "$updater_pid" 2>/dev/null || true
    updater_pid=""
    status=0
    wait "$worker_pid" || status=$?
    worker_pid=""
    test ! -e "$reload_script"
    test "$(grep -c '^bootout$' "$call_log")" -eq 1
    test "$(grep -c '^bootstrap$' "$call_log")" -eq 1
    test "$(grep -c '^remove$' "$call_log")" -eq 1
    if [ "$scenario" = success ]; then
        test "$status" -eq 0
        grep -Fq '[dotfiles-update-launchd][done]' "$reload_log"
    else
        test "$status" -eq 1
        grep -Fq '[dotfiles-update-launchd][error] bootstrap failed' "$reload_log"
        if grep -q '^enable$' "$call_log"; then exit 1; fi
    fi
done

# 독립 작업 등록에 실패하면 원래 예약을 유지하고 임시 스크립트를 정리한다.
: > "$call_log"
touch "$test_home/submit-fails"
/bin/sleep 30 &
updater_pid=$!
printf '%s\n' "$updater_pid" > "$test_home/update.pid"
status=0
run_registrar || status=$?
test "$status" -eq 1
test ! -e "$(cat "$test_home/reload-script-path")"
grep -Fq '[dotfiles-update-launchd][error] could not schedule reload' "$test_home/registrar.log"
if grep -q '^bootout$' "$call_log"; then exit 1; fi
