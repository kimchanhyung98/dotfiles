# 전역 환경 변수

if [ -z "${LANG:-}" ]; then
    if locale -a 2>/dev/null | grep -qi '^en_US\\.utf-\\?8$'; then
        export LANG="en_US.UTF-8"
    elif locale -a 2>/dev/null | grep -qi '^C\\.utf-\\?8$'; then
        export LANG="C.UTF-8"
    fi
fi

: "${EDITOR:=vim}"
export EDITOR

: "${VISUAL:=$EDITOR}"
export VISUAL
