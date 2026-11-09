# 승인 Python no-window 3회차 결과

판정은 실패다. 승인 manifest SHA fc61b561d7e9f4740497c77d9dbacb1ea603dfd5d0cf584f0acd692655bc603f의 exact argv를 기본 managed sandbox에서 한 번 실행했다. 2026-11-08 16:25:42~16:25:43 UTC, 실행 도구 경과 1.45초, exit 1이다. 별도 Python 비제품 진단 K=3의 마지막 시도이며 이후 재실행하지 않았다.

- 직전과 직후 승인 입력 29개, 보호 파일 6개 SHA, resolved HEAD 0be09755b70378286105972f35ac5b7031715664 및 symbolic ref가 일치했다. 새 scratch, guard journal, diagnostics 및 launcher stdout/stderr가 직전에는 없었다.
- Broker의 Python child에 CREATE_NO_WINDOW를 추가한 이번 정상 케이스에서도 normal/outer Job에 예상 밖 Windows console-host 이미지가 관측됐다. PID 35984, creation time 134386287431639892, image 조회 전후 membership true를 기록했다. 경로 원문은 전용 로컬 stderr에만 보존했다. 이 조건에서 console host 생성이 억제됐다고 볼 수 없다. 실제 실행 이미지의 bytes·서명·부모 또는 과거 실패의 동일 원인은 입증되지 않았다.
- 첫 오류 unexpected-owned-image와 뒤 cleanup ValueError가 분리됐다. Case 외부 기록은 owned-cleanup drained=false와 controller broker exit 125다. Inner receipt와 case retained-handle signalled 기록이 없다. 이 mismatch HANDLE의 종료나 payload spawn을 확인했다고 판정하지 않는다.
- Global watchdog은 별도로 owned_drained=true, output_complete=true, supervisor exit 1을 기록했다. 별도 소유 sentinel PID 26780은 정상 exit 0이다. Global cleanup 기록을 case 단위 또는 해당 retained HANDLE의 종료 증거로 대체하지 않는다. 정상 통과 0/1이다.

허용 목록과 기존 1·2회차 원문은 유지했다. Python 비제품 K=3은 소진됐다. 제품/Godot/GUI/ABI를 실행하지 않았고 K6은 한 회 남아 있다. 독립 결과 심사용 원본 파일의 SHA와 길이는 python-job-nowindow-attempt3-evidence.json에 있다.
