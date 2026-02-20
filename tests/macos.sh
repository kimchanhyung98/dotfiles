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
while IFS= read -r -d '' script; do
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
done < <(find "$REPO_DIR/home/.chezmoiscripts/darwin" -name '*.sh.tmpl' -type f -print0 2>/dev/null)

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
