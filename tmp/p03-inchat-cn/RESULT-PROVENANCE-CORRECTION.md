# Cn 정적 검사 요약의 출처 정정

독립 5b 중 attempt-02의 개별 실행 기록과 같은 폴더의 result.json이 서로 다른 판정을 담고 있음을 확인했다. attempt-02를 만든 명령은 `Copy-Item attempt-01/*.json attempt-02`로 입력 fixture와 변이 기록을 복사했다. 이 명령에는 첫 시도의 결과 요약도 포함됐다. 두 result.json은 SHA-256 `fa1ca3eeb7240ae90ea62b50b76331036e809e613f45fcfce7ed1ab6097c4e54`로 일치한다. 두 번째 명령은 새 result.json을 생성하지 않았다. 따라서 attempt-02/result.json은 첫 번째 실패 실행의 복사본이다. 두 원본과 실행 로그를 그대로 보존한다.

## 재대조 기록

복사 및 실행 명령 원문은 이 채팅의 `/root/cn_local` 실행 도구 호출 중 attempt-02를 생성한 `functions.exec`의 `exec_command` 인수에 있다. 명령은 `New-Item -ItemType Directory attempt-02` 다음에 `Copy-Item attempt-01/*.json attempt-02`를 실행했다. 이후 `foreach`에서 각 Python 실행 직후 `$LASTEXITCODE | Set-Content "attempt-02/$n.exit"`로 저장했다. 별도 집계 파일을 쓰는 명령은 없었다. 위 명령 원문과 첫 시도 집계의 동일 바이트가 복사 출처의 근거다.

개별 기록에서 파생한 두 번째 시도 결과는 normal/omit/promote/missing 순서로 `[0,1,1,2]`다. before/after 스냅샷 SHA-256은 양쪽 모두 `8f08554ec1b7809f5f5351fb7d39a86608b0381c838c7fea116272f73c287836`이다. 각각의 before.exit와 after.exit는 0이다. 같은 폴더의 result.json이 담은 `[2,2,2,2]`와 `stable=false`는 첫 시도의 값이며 두 번째 시도 집계로 사용할 수 없다.

## 독립 재대조 계획

- attempt-02 명령 원문에서 각 자식 프로세스 직후의 LASTEXITCODE가 해당 이름의 exit 파일에 저장됨을 확인한다.
- 실행 순서 normal, omit, promote, missing의 개별 stdout/stderr/exit와 before/after 스냅샷을 직접 비교한다. 입력 세 변이가 각각 독립 사본의 한 가지 변경인지 대조한다.
- 독립 Terra가 기존 요약의 출처와 개별 기록을 수용하는 경우에만 기존 attempt-02의 증거로 판정한다. 개별 자료에 문제가 있으면 기존 판정을 유지하고 잔여 1회 내 새 실행을 별도 심사한다.
- Godot 및 자연 경합은 미실행이다. 범위 밖 작업트리 무변이를 주장하지 않는다.
