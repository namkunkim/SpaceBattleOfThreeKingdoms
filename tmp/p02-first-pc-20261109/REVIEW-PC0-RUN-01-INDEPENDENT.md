# PC0 승인 실행 01 독립 결과 심사

판정: **PC0 미완료. 승인된 한 회는 import 중 감독기 가드에서 종료됐고, 제품 GUI·입력·자연 종결·5-a는 미실행이다.** `PC0-TERMINAL-RUN-01-RESULT.md` SHA `be1ce70cd580a6227d19a10dc68e7f01498686362e43b1204c3275d7d725d30f` 확인. 심사 모델 gpt-6.1-terra. 이 심사에서 재실행하지 않았다.

격리 probe의 `isolation.os.tsv` SHA `7e844356daa5e9184c375cbcb4a0b94ecbedd6e6e58de69ecff5fe8326157d8d`는 GUI Godot PID 34472, exit 0, Job cleanup active 0을 기록한다. `isolation.log` SHA `97dd6468f3e9dfd3993df21026ea3890dd9c5b42449ed8c20581b5651e639b33`은 전용 project와 run-01 아래 user://를 보여 준다. 이는 격리 probe 결과에 한정되며 제품 화면이나 입력 증거가 아니다.

`import.os.tsv` SHA `db64a2abadd77cd4e547341dbdb67d876067e296fad34949bd2393db3a26f30d`에는 PID 24456과 cleanup active 0이 있으나 import exit 행은 없다. `import.log` SHA `6d1c065383a27c36804949ba8e84b09714470b112e5dacc0bd5aeb7b9c147c4e`는 engine banner만 남았다. 감독기 `Pc0Job.Run`은 Job active count가 1이 아니면 `Unexpected child in Job`을 내지만 추가 member의 PID·image·부모 관계를 기록하지 않는다. 추가 member가 무엇인지, 이전 console host와 같은지, import가 정상 완료될 수 있었는지는 특정할 수 없다. source상 cleanup은 소유 root HANDLE 종료와 Job active 0을 검사하지만 추가 member의 개별 retained HANDLE signal은 기록하지 않았다. 감독기 중단을 게임 로직 실패나 import 성공으로 바꾸어 말하지 않는다.

원본 user/cache inventory의 before/after SHA는 모두 `c6e095a2ca413a2d61c419d7e19ec64ed2c78ca0775370cfb479747b5605a976`이며 전달된 Git/P03/worker 사후 보호 확인도 일치한다. 이는 지정 범위의 두 시점 관측에 한정된다. 격리 user의 `.recovery_mode_lock`과 부분 import/cache는 진단 증거로 보존하며 수동 삭제·덮어쓰지 않는다. product.log, battle trace, screenshot 및 UI 조작은 없어 PC0 move, clock, 자연 종결 및 결과 1회 전달은 미측정이다.

해당 PC0 승인 one-shot은 소진됐으므로 자동 재시도하지 않는다. 이전 Python-only ownership K=3 실패도 별도 이력으로 유지한다. 두 시험은 launcher와 대상은 다르지만 미확인 member와 cleanup 증거의 공백이라는 관련 위험을 공유한다. 경로나 예산 이름을 바꿔 과거 시도를 지우지 않고, 스펙으로 돌아가 전용 Job의 소유·안전한 정리와 image 신뢰 허용 판단을 분리해 실제 필요·증거·유한 상한을 독립 심사한다. 미확인 member를 이름만으로 허용하거나 기존 사용자 프로세스를 검색·종료하지 않는다. 현재 정적 분석과 독립적인 P02 작업은 계속할 수 있으나, 다른 실행은 새 구체 명세·잔여 범위·독립 판정 전 하지 않는다.

이번 HEAD legacy 기준선은 미수용 여덟째 후보를 적용하지 않았다. K1~K5와 여덟째 후보의 K6 한 회·21행을 유지하고 PC0 실패를 그 K6 결과로 합산하지 않는다. P02/P03은 NOT_READY다.
