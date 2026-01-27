#!/bin/bash

# macOS terminal-notifier 알림 권한 확인 스크립트

set -e

# 플래그 파일
FLAG_FILE=".claude/hooks/.permissions-checked"

# 이미 확인 완료한 경우 건너뛰기
[[ -f "$FLAG_FILE" ]] && exit 0

# terminal-notifier 설치 확인
if ! command -v terminal-notifier &>/dev/null; then
    echo ""
    echo "Claude Code 알림에 terminal-notifier가 필요합니다."
    echo "설치하시겠습니까? (n: 건너뛰기, 그 외: 설치)"
    read -n 1 -r -t 10 || true
    echo ""

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        brew install terminal-notifier
    fi
fi

# 알림 권한 안내
echo ""
echo "Claude Code 알림을 받으려면 terminal-notifier 앱의 알림 권한이 필요합니다."
echo "알림 설정을 여시겠습니까? (n: 건너뛰기, 그 외: 열기)"
read -n 1 -r -t 10 || true
echo ""

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    open "x-apple.systempreferences:com.apple.preference.notifications"
    sleep 2
fi

# 플래그 파일 생성
mkdir -p "$(dirname "$FLAG_FILE")"
touch "$FLAG_FILE"

exit 0
