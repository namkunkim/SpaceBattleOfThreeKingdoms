# PC0 owned-v2 실행 준비물 독립 심사

판정: **최종 실행 반려. 미확인 member image의 동기 hash가 감독 deadline을 우회할 수 있으므로 수정·재심한다.** `REVIEW-MANIFEST.json` SHA `77cb8d3ffc28b5190ce2023cd99343a8d74b83c1f9bb23438a602e8b3366eb4c` 및 모든 part SHA 일치, source 1,470/unresolved 0, HEAD `0be09755b70378286105972f35ac5b7031715664`, run-02 부재를 확인했다. 심사 모델 gpt-6.1-terra. 실제 제품/Godot/GUI/Job은 실행하지 않았다.

`Pc0Job.Snapshot`은 Job의 새 member를 관측할 때 `HashImage(image)`로 그 image 경로를 같은 감독 스레드에서 동기 `File.OpenRead` 및 전체 SHA를 계산한다. `Run`의 100ms loop에서 wall deadline과 abort는 이 호출이 반환된 뒤에만 검사된다. 예상하지 못한 member 경로가 크거나 느리거나 접근이 붙잡히면, 계획한 단계별 300/1920초·abort와 10초 cleanup 경계가 보장되지 않고 신선한 foreground 표본도 중단될 수 있다. PowerShell supervisor는 같은 동기 호출을 기다리므로 별도 외부 watchdog이 이 구간을 강제하지 않는다. Job kill-on-close는 감독 process가 실제 종료돼야 작동하며 임의 블로킹 자체의 시간 제한은 아니다.

최소 수정은 **미확인 child의 image SHA를 동기 계산하지 않고 `unavailable/not-collected`로 두고**, 이미 보유한 정확 HANDLE의 Job membership·PID/creation·image 경로 및 종료를 기록하는 것이다. 해당 SHA는 계획상 가능할 때의 보조 자료이며 미확인 image를 GUI 대상으로 신뢰하지 않는다. 또는 실제 독립 watchdog과 bounded hash를 구현해 deadline/owned cleanup의 합성 및 독립 심사를 받는다. 고정된 root executable hash는 실행 직전에 확인하되 메모리 image와 완전 동일하다고 주장하지 않는다. Snapshot/로그/종료 실패는 성공으로 바꾸지 않는다. 이 수정은 user 파일이나 임의 PID에 대한 검색/종료를 허가하지 않는다.

그 외 정적 범위는 유용하다. 이전 1회 실패를 산입해 남은 단일 run02만 허용하고, 정확 suspended root의 assign/membership 후 resume, Job의 다중 member와 image 신뢰를 분리하며 root exit·Job active 0·retained signal을 별도 기록한다. GUI 입력은 root 소유 HWND와 foreground에만 제한된다. 기존 oracle·overlay·trace-reader는 전 수용본과 byte-identical이고 자연 종결·결과 1회와 실제 화면/명령의 별도 5-b가 필요하다. `test_job_receipts.py` 1 양성·10 거부와 terminal 2 양성·8 거부를 독립 실행했으나 이는 합성/정적 자료이지 Windows syscall timing, 실제 image 관측, GUI 또는 32분 플레이의 증거가 아니다.

새 수정본은 exact manifest/part SHA·argv/env, HEAD/index/P03/worker 및 run01 lock/원본 user/cache 보호와 run02 fresh 경로, import 결과·stage deadline·로그 증거를 다시 고정해 재심한다. fast exit/접근 거부의 개별 identity는 미확인으로 남기고 active 0과 혼동하지 않는다. 강제 read-deny 같은 새 보편 조건을 추가하지 않는다. K=2 중 run01 1회 및 여덟째 K6 별도 이력은 유지하며 승인 전 남은 한 회를 쓰지 않는다.
