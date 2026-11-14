#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
export STATS_TEST_DOMAIN="$test_home/preferences"
trap '/usr/bin/defaults delete "$STATS_TEST_DOMAIN" >/dev/null 2>&1 || true; rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
fake_bin="$test_home/bin"
rendered="$test_home/app-settings.sh"
mkdir -p "$fake_bin" "$test_home/.config/stats"
cp "$repo_dir/home/dot_config/stats/Stats.plist" "$test_home/.config/stats/Stats.plist"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/darwin/run_onchange_after_05-app-settings.sh.tmpl" \
    > "$rendered"

# 실제 defaults의 병합 동작을 임시 경로에서 검사하고 Stats 종료는 대체한다.
cat > "$fake_bin/defaults" <<'EOF'
#!/bin/bash
set -euo pipefail
operation="$1"
case "$operation" in export | import) ;; *) exit 1 ;; esac
test "$2" = eu.exelban.Stats
shift 2
exec /usr/bin/defaults "$operation" "$STATS_TEST_DOMAIN" "$@"
EOF
cat > "$fake_bin/killall" <<'EOF'
#!/bin/bash
set -euo pipefail
test "$#" -eq 1 && test "$1" = Stats
EOF
chmod +x "$fake_bin/defaults" "$fake_bin/killall"

cat > "$test_home/current.json" <<'EOF'
{
  "version": "3.0.23",
  "updater_check_ts": 1793019301,
  "updater_install_ts": 1793019306,
  "support_ts": 1791684263,
  "support_pending": true,
  "support_pending_ts": 1794550000,
  "remote_tokens_migrated_to_keychain": true,
  "remote_id": "fixture-remote-id",
  "access_token": "fixture-access-token",
  "refresh_token": "fixture-refresh-token",
  "RAM_updateInterval": 1,
  "fixture_local_state": {"enabled": true, "count": 7}
}
EOF
plutil -convert xml1 -o "$test_home/current.plist" "$test_home/current.json"
/usr/bin/defaults import "$STATS_TEST_DOMAIN" "$test_home/current.plist"
HOME="$test_home" PATH="$fake_bin:$PATH" bash "$rendered" > "$test_home/apply.log"
/usr/bin/defaults export "$STATS_TEST_DOMAIN" "$test_home/result.plist"
plutil -convert json -o "$test_home/result.json" "$test_home/result.plist"
jq -e '
    .version == "3.0.23"
    and .updater_check_ts == 1793019301
    and .updater_install_ts == 1793019306
    and .support_ts == 1791684263
    and .support_pending == true
    and .support_pending_ts == 1794550000
    and .remote_tokens_migrated_to_keychain == true
    and .remote_id == "fixture-remote-id"
    and .access_token == "fixture-access-token"
    and .refresh_token == "fixture-refresh-token"
    and .RAM_updateInterval == 10
    and .fixture_local_state == {"enabled": true, "count": 7}
' "$test_home/result.json" >/dev/null

# 신규 설치에는 과거 실행 기록을 만들지 않고 선언한 설정만 적용한다.
/usr/bin/defaults delete "$STATS_TEST_DOMAIN"
HOME="$test_home" PATH="$fake_bin:$PATH" bash "$rendered" > "$test_home/apply.log"
/usr/bin/defaults export "$STATS_TEST_DOMAIN" "$test_home/fresh.plist"
plutil -convert json -o "$test_home/fresh.json" "$test_home/fresh.plist"
jq -e '
    (has("version") or has("updater_check_ts") or has("support_ts")
        or has("remote_id") or has("access_token") or has("refresh_token") | not)
    and .RAM_updateInterval == 10
    and .Sensors_state == true
' "$test_home/fresh.json" >/dev/null
