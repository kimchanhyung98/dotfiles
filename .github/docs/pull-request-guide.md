# Pull Request 작성 가이드

제목 형식 : `<type>: <description>` 또는 `<type>(<scope>): <description>`

## 자동 검증

- `type`은 소문자 영문이며 고정 목록을 강제하지 않습니다.
- `scope`는 선택사항이며 소문자 영문, 숫자, 하이픈, 언더바를 허용합니다.
- 영문 description은 대문자로 시작할 수 없습니다.
- `feat!:`와 같은 breaking-change 표기는 현재 허용하지 않습니다.

## 작성 권장

- **명령형 현재 시제** 사용 (add, 과거형 added가 아님)
- 끝에 마침표를 사용하지 않음
- **50자 이내** 권장

## 예시

```
feat: add email verification
feat(user): add email verification
fix(payment): resolve timeout error
refactor(order): extract calculation logic
docs: add OpenAPI specification
chore(deps): upgrade Laravel to 12.1
```
