#!/usr/bin/env node

const fs = require('fs');

// 허용 패턴
const validPattern = '<type>(scope): <subject> or <type>: <subject> (English subject starts lowercase)';

// 커밋 메시지 파일 확인
const commitMsgFile = process.argv[2];
if (!commitMsgFile) {
    console.error('커밋 메시지 파일 오류');
    process.exit(1);
}

// 커밋 메시지 확인
let commitMsg;
try {
    commitMsg = fs.readFileSync(commitMsgFile, 'utf8').trim();
} catch (err) {
    console.error(`커밋 메시지 확인 오류: ${err.message}`);
    process.exit(1);
}

// merge/revert 커밋은 제외
const commitHeader = commitMsg.split(/\r?\n/, 1)[0];
if (/^Merge /.test(commitHeader) || /^Revert "/.test(commitHeader)) {
    process.exit(0);
}

// 패턴: `type(scope): subject` or `type: subject` (scope는 선택 사항, 소문자만 허용)
const commitPattern = /^[a-z]+(?:\([a-z0-9_-]+\))?:[ \t]+(\S.*)$/;
const commitMatch = commitHeader.match(commitPattern);

if (!commitMatch) {
    console.error(`* 잘못된 형식 : ${commitHeader}`);
    console.error(`* 올바른 형식 : ${validPattern}`);
    console.error('');
    process.exit(1);
}

const subject = commitMatch[1];
if (/^[A-Z]/.test(subject)) {
    console.error(`* 잘못된 subject : ${subject}`);
    console.error('* 영문 subject는 소문자로 시작해야 합니다.');
    console.error('');
    process.exit(1);
}

process.exit(0);
