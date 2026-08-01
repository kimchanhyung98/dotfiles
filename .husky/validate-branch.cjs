#!/usr/bin/env node

const fs = require('fs');
const {execSync} = require('child_process');

// 허용 패턴
const validPattern = '<type>/<description> 또는 <type>/<segment>/<segment>/...';
const protectedBranches = ['main', 'master', 'develop', 'staging'];
const branchPattern = /^[a-z]+\/[a-z0-9][a-z0-9._-]*(\/[a-z0-9][a-z0-9._-]*)*$/;

function validateBranch(branch) {
    if (protectedBranches.includes(branch)) {
        return;
    }

    if (!branchPattern.test(branch)) {
        console.error(`* 잘못된 형식 : ${branch}`);
        console.error(`* 올바른 형식 : ${validPattern}`);
        console.error('');
        process.exit(1);
    }
}

function currentBranch() {
    try {
        return execSync('git rev-parse --abbrev-ref HEAD', {encoding: 'utf8'}).trim();
    } catch (err) {
        console.error(`브랜치명 확인 오류: ${err.message}`);
        process.exit(1);
    }
}

const input = process.stdin.isTTY ? '' : fs.readFileSync(0, 'utf8').trim();
if (!input) {
    validateBranch(currentBranch());
    process.exit(0);
}

for (const line of input.split(/\r?\n/)) {
    const fields = line.trim().split(/\s+/);
    if (fields.length !== 4) {
        console.error(`push 참조 확인 오류: ${line}`);
        process.exit(1);
    }

    const [, localObject, remoteRef] = fields;
    if (/^0+$/.test(localObject) || !remoteRef.startsWith('refs/heads/')) {
        continue;
    }

    validateBranch(remoteRef.slice('refs/heads/'.length));
}

process.exit(0);
