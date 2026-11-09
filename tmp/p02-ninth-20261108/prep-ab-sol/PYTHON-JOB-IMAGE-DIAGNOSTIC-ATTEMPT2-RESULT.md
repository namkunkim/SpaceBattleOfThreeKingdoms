# 승인 Python normal 이미지 진단 2회차 결과

독립 승인 manifest SHA a7647cca76be8cd5f46681b817765d4816ae1c94f3b7676244cfb949d8fdb375의 exact argv를 기본 managed sandbox에서 한 번 실행했다. 2026-11-08 16:19:10~16:19:11 UTC, 실행 도구 경과 2.29초, exit 1이다. 이전 one-shot과 분리된 비제품 진단 예산 K=3의 2회차이며, 재실행하지 않았다.

- 직전 승인 입력 21개, 보호 파일 6개, resolved HEAD 0be09755b70378286105972f35ac5b7031715664와 symbolic ref가 일치했다. 새 scratch, guard journal 및 diagnostics 경로와 launcher stdout/stderr는 존재하지 않았다. 종료 직후 같은 입력·보호·HEAD/ref 확인도 일치했다.
- Normal outer Job에서 예상 밖 owned image가 다시 관측됐다. PID 6540, creation time 134386283511151152 및 image 조회 전후 Job membership true를 기록했다. Raw, lexical, resolved 경로와 기존 허용 목록 비교 결과가 전용 로컬 stderr 원문에 존재한다. 원래 resolver 기준 불일치다. 실행 이미지 파일의 바이트 동일성이나 이전 시도의 원인을 소급해서 증명하는 자료는 아니다.
- Primary는 unexpected-owned-image, cleanup은 별도 ValueError로 보존했다. Normal outer journal의 owned cleanup은 drained=true, controller broker exit 125이고 보유 broker PID 12464는 signalled=true다. Inner receipt/payload marker가 없어 실제 payload spawn 또는 정상 종료는 미입증이다. 실패 이미지의 HANDLE 종료 신호를 별도 보유하지 않았으므로 그 HANDLE에 대해 종료 실측을 주장하지 않는다.
- 외부 watchdog은 owned_drained=true, output_complete=true 및 supervisor exit 1을 기록했다. 별도 소유 sentinel PID 38668은 정상 exit 0이다. Normal 통과 0/1이며 다른 Job 케이스는 승인된 범위에 없었다.
- 원시 이미지 경로는 로컬 증거 파일에만 남겼다. 허용 목록을 수정하지 않았다. 독립 결과 심사 전에는 다음 진단, ABI/Godot·GUI·제품 검증을 시작하지 않는다. K6은 한 회 남아 있다.

아래 evidence JSON에 승인 manifest 및 원본 stdout/stderr, outer/sentinel/watchdog journal의 길이와 SHA를 기록했다. 원본 파일을 변경하지 않았다.
