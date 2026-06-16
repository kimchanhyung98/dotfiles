#!/bin/bash
#
# macOS dotfiles 테스트 스크립트 (읽기 전용, 파일 변경 없음)
# 격리된 임시 HOME 디렉토리에서 실행하여 실제 사용자 설정에 영향 없음

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
ERRORS=""

# 테스트 결과 출력 헬퍼 함수
pass() {
    echo "  ✅ $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  ❌ $1"
    FAIL=$((FAIL + 1))
    ERRORS="${ERRORS}\n  - $1"
}

warn() {
    echo "  ⚠️  $1"
}

section() {
    echo ""
    echo "--- $1 ---"
}

# 격리된 chezmoi 환경 설정 (실제 사용자 설정에 영향 없음)
TMPHOME=$(mktemp -d)
trap 'rm -rf "$TMPHOME"' EXIT

mkdir -p "$TMPHOME/.config/chezmoi"
cat > "$TMPHOME/.config/chezmoi/chezmoi.toml" << 'EOF'
[data]
    name = "Test User"
    email = "test@example.com"
EOF

# 격리된 환경에서 chezmoi 실행하는 래퍼 함수
cz() {
    HOME="$TMPHOME" XDG_CONFIG_HOME="$TMPHOME/.config" chezmoi "$@"
}

# 프로젝트 소스로 chezmoi 초기화
if ! cz init --source "$REPO_DIR/home" 2>&1; then
    fail "chezmoi init failed"
fi

# --- 1. 템플릿 렌더링 검증 ---
section "Template validation"
TMPL_FAIL=0
while IFS= read -r target; do
    if ! cz cat "$TMPHOME/$target" > /dev/null 2>&1; then
        echo "    FAIL: $target"
        TMPL_FAIL=$((TMPL_FAIL + 1))
    fi
done < <(cz managed --include=files 2>/dev/null)

if [ "$TMPL_FAIL" -eq 0 ]; then
    pass "All templates render successfully"
else
    fail "$TMPL_FAIL template(s) failed to render"
fi

# --- 1.2. cmux 기본 자동화 설정 검증 ---
section "cmux automation defaults"
CMUX_SETTINGS_SOURCE="$REPO_DIR/home/dot_config/cmux/settings.json.tmpl"
rendered_cmux_settings="$(mktemp -p "$TMPHOME")"
cmux_settings_err="$(mktemp -p "$TMPHOME")"
if cz execute-template < "$CMUX_SETTINGS_SOURCE" > "$rendered_cmux_settings" 2>"$cmux_settings_err" \
   && grep -q '"socketControlMode": "automation"' "$rendered_cmux_settings"; then
    pass "cmux settings.json enables automation mode"
else
    fail "cmux settings.json did not render socketControlMode=automation (stderr: $(cat "$cmux_settings_err"))"
fi
rm -f "$rendered_cmux_settings" "$cmux_settings_err"

CMUX_SCRIPT_SOURCE="$REPO_DIR/home/.chezmoiscripts/darwin/run_onchange_after_04-cmux-settings.sh.tmpl"
rendered_cmux_script="$(mktemp -p "$TMPHOME")"
cmux_script_err="$(mktemp -p "$TMPHOME")"
if cz execute-template < "$CMUX_SCRIPT_SOURCE" > "$rendered_cmux_script" 2>"$cmux_script_err" \
   && grep -q 'defaults write com.cmuxterm.app socketControlMode -string automation' "$rendered_cmux_script"; then
    pass "cmux darwin script sets automation mode in defaults"
else
    fail "cmux darwin script missing defaults-write for socketControlMode (stderr: $(cat "$cmux_script_err"))"
fi
rm -f "$rendered_cmux_script" "$cmux_script_err"

# --- 1.3. macOS 앱 설정 자동 적용 검증 ---
section "macOS app settings automation"
RECTANGLE_CONFIG_SOURCE="$REPO_DIR/home/dot_config/rectangle/RectangleConfig.json"
STATS_CONFIG_SOURCE="$REPO_DIR/home/dot_config/stats/Stats.plist"
APP_SETTINGS_SCRIPT_SOURCE="$REPO_DIR/home/.chezmoiscripts/darwin/run_onchange_after_05-app-settings.sh.tmpl"
STATS_EXCLUDED_KEYS='NSOSPLastRootDirectory|remote_id|access_token|refresh_token'

if [ ! -f "$RECTANGLE_CONFIG_SOURCE" ]; then
    fail "Rectangle config source is missing"
elif ! command -v jq &>/dev/null; then
    warn "jq not installed, skipping Rectangle JSON validation"
elif jq empty "$RECTANGLE_CONFIG_SOURCE" >/dev/null 2>&1; then
    pass "Rectangle config JSON is valid"
else
    fail "Rectangle config JSON is invalid"
fi

if [ -f "$STATS_CONFIG_SOURCE" ] && plutil -lint "$STATS_CONFIG_SOURCE" >/dev/null 2>&1; then
    pass "Stats plist is valid"
else
    fail "Stats plist is missing or invalid"
fi

if [ -f "$STATS_CONFIG_SOURCE" ] \
   && ! plutil -p "$STATS_CONFIG_SOURCE" | grep -Eq "$STATS_EXCLUDED_KEYS"; then
    pass "Stats plist excludes file dialog state and remote credentials"
else
    fail "Stats plist contains file dialog state or remote credentials"
fi

rendered_app_script="$(mktemp -p "$TMPHOME")"
app_script_err="$(mktemp -p "$TMPHOME")"
if [ -f "$APP_SETTINGS_SCRIPT_SOURCE" ] \
   && cz execute-template < "$APP_SETTINGS_SCRIPT_SOURCE" > "$rendered_app_script" 2>"$app_script_err" \
   && bash -n "$rendered_app_script" \
   && grep -q 'Application Support/Rectangle/RectangleConfig.json' "$rendered_app_script" \
   && grep -q 'defaults import eu.exelban.Stats' "$rendered_app_script" \
   && grep -q 'PlistBuddy' "$rendered_app_script" \
   && grep -q 'remote_id' "$rendered_app_script" \
   && ! grep -q 'defaults write eu.exelban.Stats .*access_token' "$rendered_app_script" \
   && ! grep -q 'defaults write eu.exelban.Stats .*refresh_token' "$rendered_app_script"; then
    pass "app settings darwin script imports Rectangle and Stats settings"
else
    fail "app settings darwin script is missing or incomplete (stderr: $(cat "$app_script_err"))"
fi
rm -f "$rendered_app_script" "$app_script_err"

# --- 1.4. 공통 스킬 디렉토리 정리 검증 ---
section "Skills cleanup"
SKILLS_CLEANUP_SOURCE="$REPO_DIR/home/.chezmoiscripts/run_once_before_00-skills-ssot-migrate.sh.tmpl"
if bash "$REPO_DIR/tests/skills-migrate.sh" "$SKILLS_CLEANUP_SOURCE"; then
    pass "skills cleanup script removes legacy skills directories"
else
    fail "skills cleanup script"
fi

# --- 1.5. 공통 스킬 배포 경로 검증 ---
section "Skills deployment topology"
SKILLS_MANAGED_PATHS="$(cz managed --include=all 2>/dev/null || true)"
SKILLS_TOPOLOGY_FAIL=0
for target in \
    ".claude/skills" \
    ".agents/skills" \
    ".local/bin/mattpocock-skills-sync"; do
    if ! grep -Fxq "$target" <<< "$SKILLS_MANAGED_PATHS"; then
        echo "    FAIL: $target is not managed"
        SKILLS_TOPOLOGY_FAIL=$((SKILLS_TOPOLOGY_FAIL + 1))
    fi
done

if [ "$SKILLS_TOPOLOGY_FAIL" -eq 0 ]; then
    pass "shared skills source and tool symlinks are managed"
else
    fail "$SKILLS_TOPOLOGY_FAIL skills deployment path(s) missing"
fi

# --- 1.6. mattpocock 스킬 동기화 검증 ---
section "mattpocock skills sync"
MATTPOCOCK_SYNC_SOURCE="$REPO_DIR/home/dot_local/bin/executable_mattpocock-skills-sync"
MATTPOCOCK_SCRIPT_SOURCE="$REPO_DIR/home/.chezmoiscripts/run_onchange_after_06-mattpocock-skills.sh.tmpl"
rendered_mattpocock_script="$(mktemp -p "$TMPHOME")"
mattpocock_script_err="$(mktemp -p "$TMPHOME")"
if bash "$REPO_DIR/tests/mattpocock-skills-sync.sh" "$MATTPOCOCK_SYNC_SOURCE" \
   && cz execute-template < "$MATTPOCOCK_SCRIPT_SOURCE" > "$rendered_mattpocock_script" 2>"$mattpocock_script_err" \
   && bash -n "$rendered_mattpocock_script" \
   && grep -q 'mattpocock-skills-sync' "$rendered_mattpocock_script" \
   && grep -q 'Sync helper hash:' "$rendered_mattpocock_script"; then
    pass "mattpocock skills sync installs and refreshes runtime skills"
else
    fail "mattpocock skills sync (stderr: $(cat "$mattpocock_script_err"))"
fi
rm -f "$rendered_mattpocock_script" "$mattpocock_script_err"

# --- 1.7. Brew 패키지 동기화 검증 ---
section "Brew package sync"
BREWFILE_SOURCE="$REPO_DIR/home/Brewfile"
BREW_SCRIPT_SOURCE="$REPO_DIR/home/.chezmoiscripts/darwin/run_onchange_03-brew-packages.sh.tmpl"
rendered_brew_script="$(mktemp -p "$TMPHOME")"
brew_script_err="$(mktemp -p "$TMPHOME")"
if grep -q 'brew "pkgconf"' "$BREWFILE_SOURCE" \
   && ! grep -q 'brew "pkg-config"' "$BREWFILE_SOURCE" \
   && grep -q 'cask "docker-desktop"' "$BREWFILE_SOURCE" \
   && cz execute-template < "$BREW_SCRIPT_SOURCE" > "$rendered_brew_script" 2>"$brew_script_err" \
   && bash -n "$rendered_brew_script" \
   && grep -q 'zb bundle install --auto-init -f "$BREWFILE"' "$rendered_brew_script" \
   && grep -q 'brew bundle --file="$BREWFILE"' "$rendered_brew_script" \
   && grep -q 'HOMEBREW_BUNDLE_BREW_SKIP' "$rendered_brew_script" \
   && grep -q 'brew trust --formula dopplerhq/cli/doppler' "$rendered_brew_script" \
   && grep -q 'falling back to Homebrew' "$rendered_brew_script"; then
    pass "Brewfile uses current tokens and zerobrew-first bundle with Homebrew fallback"
else
    fail "Brew package sync regression (stderr: $(cat "$brew_script_err"))"
fi
rm -f "$rendered_brew_script" "$brew_script_err"

# --- 1.8. Zsh 설정 회귀 검증 ---
section "Zsh config regression"
if bash "$REPO_DIR/tests/zsh-config.sh"; then
    pass "Zsh config regression checks"
else
    fail "Zsh config regression checks"
fi

# --- 2. chezmoi diff (소스와 대상 차이 확인) ---
section "chezmoi diff"
if cz diff > /dev/null 2>&1; then
    pass "chezmoi diff (no differences)"
else
    warn "chezmoi diff (differences found, expected for fresh init)"
fi

# --- 3. chezmoi apply 드라이런 (실제 적용 없이 시뮬레이션) ---
section "chezmoi apply (dry-run)"
if cz apply --dry-run --verbose > /dev/null 2>&1; then
    pass "chezmoi apply --dry-run"
else
    warn "chezmoi apply --dry-run (changes pending)"
fi

# --- 4. chezmoi verify (파일 일치 확인) ---
section "chezmoi verify"
if cz verify > /dev/null 2>&1; then
    pass "chezmoi verify (all files match)"
else
    warn "chezmoi verify (differences found, expected for isolated environment)"
fi

# --- 5. chezmoi doctor (환경 진단) ---
section "chezmoi doctor"
if doctor_output="$(cz doctor 2>&1)"; then
    echo "$doctor_output" | tail -5
    pass "chezmoi doctor"
else
    echo "$doctor_output" | tail -5
    warn "chezmoi doctor (non-zero exit, may include errors)"
fi

# --- 6. ShellCheck (darwin 스크립트 렌더링 후 린트 검사) ---
section "ShellCheck (darwin scripts)"
if ! command -v shellcheck &>/dev/null; then
    warn "shellcheck not installed, skipping (brew install shellcheck)"
else
SC_FAIL=0
for script in \
    "$REPO_DIR"/home/.chezmoiscripts/*.sh.tmpl \
    "$REPO_DIR"/home/.chezmoiscripts/darwin/*.sh.tmpl; do
    [ -e "$script" ] || continue

    rendered=$(mktemp -p "$TMPHOME")
    if cz execute-template < "$script" > "$rendered" 2>/dev/null; then
        if ! shellcheck -s bash -S warning "$rendered" > /dev/null 2>&1; then
            echo "    WARN: $(basename "$script")"
            shellcheck -s bash -S warning "$rendered" 2>&1 | head -10 || true
            SC_FAIL=$((SC_FAIL + 1))
        fi
    else
        echo "    SKIP: $(basename "$script") (template render failed)"
    fi
    rm -f "$rendered"
done

if [ "$SC_FAIL" -eq 0 ]; then
    pass "ShellCheck passed for all darwin scripts"
else
    fail "ShellCheck found issues in $SC_FAIL script(s)"
fi
fi # end shellcheck available check

# --- 결과 요약 ---
echo ""
echo "=============================="
echo "  Results: $PASS passed, $FAIL failed"
echo "=============================="

if [ "$FAIL" -gt 0 ]; then
    echo -e "\nFailed tests:$ERRORS"
    exit 1
fi

echo ""
echo "All macOS tests passed!"
