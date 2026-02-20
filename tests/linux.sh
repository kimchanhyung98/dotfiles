#!/bin/bash
#
# Linux dotfiles 테스트 스크립트 (CI 환경에서 실행)
# chezmoi 템플릿 렌더링, apply, verify, ShellCheck 검증

set -euo pipefail

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

section() {
    echo ""
    echo "=== $1 ==="
}

# --- 1. 버전 확인 ---
section "chezmoi version"
chezmoi --version && pass "chezmoi version" || fail "chezmoi version"

# --- 2. 템플릿 렌더링 검증 (chezmoi cat으로 전체 데이터 컨텍스트 확인) ---
section "Template validation"
TMPL_FAIL=0
while IFS= read -r target; do
    if ! chezmoi cat "$HOME/$target" > /dev/null 2>&1; then
        echo "    FAIL: $target"
        TMPL_FAIL=$((TMPL_FAIL + 1))
    fi
done < <(chezmoi managed --include=files 2>/dev/null)

if [ "$TMPL_FAIL" -eq 0 ]; then
    pass "All templates render successfully"
else
    fail "$TMPL_FAIL template(s) failed to render"
fi

# --- 3. chezmoi doctor (환경 진단) ---
section "chezmoi doctor"
chezmoi doctor --no-network > /tmp/chezmoi-doctor.log 2>&1 || true
tail -5 /tmp/chezmoi-doctor.log
if grep -q "^error" /tmp/chezmoi-doctor.log; then
    fail "chezmoi doctor reported errors"
else
    pass "chezmoi doctor"
fi

# --- 4. 드라이런 apply (실제 적용 없이 시뮬레이션) ---
section "chezmoi apply (dry-run)"
if chezmoi apply --dry-run > /tmp/chezmoi-dryrun.log 2>&1; then
    pass "chezmoi apply --dry-run"
else
    fail "chezmoi apply --dry-run"
fi

# --- 5. 실제 apply (로그를 파일로 저장하여 과도한 출력 방지) ---
section "chezmoi apply (actual)"
if chezmoi apply --force --verbose > /tmp/chezmoi-apply.log 2>&1; then
    pass "chezmoi apply --force"
else
    echo "  Last 20 lines of apply log:"
    tail -20 /tmp/chezmoi-apply.log
    fail "chezmoi apply --force"
fi

# --- 6. 배포 검증 (관리 파일 수 확인, verify 일치 여부) ---
section "Deployment verification"
MANAGED_LIST=$(chezmoi managed 2>/dev/null || true)
if [ -z "$MANAGED_LIST" ]; then
    MANAGED_COUNT=0
else
    MANAGED_COUNT=$(echo "$MANAGED_LIST" | wc -l | tr -d ' ')
fi
echo "  $MANAGED_COUNT managed files"

if chezmoi verify > /dev/null 2>&1; then
    pass "chezmoi verify (all files match)"
else
    fail "chezmoi verify (files differ from source)"
fi

# --- 7. ShellCheck (linux 스크립트 렌더링 후 린트 검사) ---
section "ShellCheck (linux scripts)"
SC_FAIL=0
CHEZMOI_SOURCE="${HOME}/.local/share/chezmoi"
while IFS= read -r -d '' script; do
    rendered=$(mktemp)
    if chezmoi execute-template < "$script" > "$rendered" 2>/dev/null; then
        if ! shellcheck -s bash -S warning "$rendered" > /dev/null 2>&1; then
            basename_script=$(basename "$script")
            echo "    WARN: ShellCheck issues in $basename_script"
            shellcheck -s bash -S warning "$rendered" 2>&1 | head -10 || true
            SC_FAIL=$((SC_FAIL + 1))
        fi
    fi
    rm -f "$rendered"
done < <(find "$CHEZMOI_SOURCE/.chezmoiscripts/linux" -name '*.sh.tmpl' -print0 2>/dev/null)

if [ "$SC_FAIL" -eq 0 ]; then
    pass "ShellCheck passed for all linux scripts"
else
    fail "ShellCheck found issues in $SC_FAIL script(s)"
fi

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
echo "All tests passed!"
