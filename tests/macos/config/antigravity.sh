#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"
rendered="$test_home/settings.json"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/dot_gemini/antigravity-cli/private_settings.json.tmpl" > "$rendered"

jq empty "$rendered"
jq -e '.model == "gemini-3.8-flash-high"' "$rendered" >/dev/null
jq -e '.toolPermission == "always-proceed"' "$rendered" >/dev/null
jq -e '.artifactReviewPolicy == "always-proceed"' "$rendered" >/dev/null
jq -e '
    .permissions.allow
    | index("command(*)") != null
      and index("read_file(*)") != null
      and index("write_file(*)") != null
      and index("read_url(*)") != null
      and index("execute_url(*)") != null
      and index("mcp(*)") != null
' "$rendered" >/dev/null
jq -e '.showFeedbackSurvey == false' "$rendered" >/dev/null

# 0600 권한 보존 검증
mkdir -p "$test_home/.gemini/antigravity-cli"
run_chezmoi "$test_home" apply "$test_home/.gemini/antigravity-cli/settings.json"
[ "$(stat -f '%Lp' "$test_home/.gemini/antigravity-cli/settings.json")" = "600" ]

managed="$(run_chezmoi "$test_home" managed --include=all)"
grep -Fxq ".gemini/antigravity-cli/settings.json" <<<"$managed"
grep -Fxq ".gemini/config/mcp_config.json" <<<"$managed"
grep -Fxq ".gemini/config/skills.json" <<<"$managed"
grep -Fxq ".gemini/GEMINI.md" <<<"$managed"

# GEMINI.md 심링크 배포 검증
mkdir -p "$test_home/.gemini"
run_chezmoi "$test_home" apply "$test_home/.gemini/GEMINI.md"
[ -L "$test_home/.gemini/GEMINI.md" ]
[ "$(readlink "$test_home/.gemini/GEMINI.md")" = "../AGENTS.md" ]

# dangerous alias 대신 persistent 설정을 사용하므로 agy alias가 등록되지 않아야 함
! grep -Fq "alias agy=" "$repo_dir/home/dot_config/zsh/70-aliases.zsh"

# 전역 MCP 설정 검증
mcp_rendered="$test_home/mcp_config.json"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/dot_gemini/config/mcp_config.json.tmpl" > "$mcp_rendered"
jq empty "$mcp_rendered"
jq -e '
    .mcpServers
    | has("codegraph")
      and has("context7")
      and has("playwright")
      and has("sequential-thinking")
' "$mcp_rendered" >/dev/null

# 전역 skills 설정 검증
skills_rendered="$test_home/skills.json"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/dot_gemini/config/skills.json.tmpl" > "$skills_rendered"
jq empty "$skills_rendered"
jq -e '.entries[0].path == "~/.skills"' "$skills_rendered" >/dev/null

# agy CLI 가 설치되어 있으면 mcp list 파싱 검증
if command -v agy >/dev/null 2>&1; then
    mkdir -p "$test_home/.gemini/config"
    cp "$mcp_rendered" "$test_home/.gemini/config/mcp_config.json"
    mcp_list="$(HOME="$test_home" agy mcp list 2>&1)"
    grep -Fq "codegraph" <<<"$mcp_list"
    grep -Fq "context7" <<<"$mcp_list"
    grep -Fq "playwright" <<<"$mcp_list"
    grep -Fq "sequential-thinking" <<<"$mcp_list"
fi
