# 비초기 Cn busy·비지원 거부 결과

[attempt-01](attempt-01/suite.json) suite actual exit 0. Godot 본시험 실제 exit 0, 3명명·37 확인. Variant int/float 강제 실패 실제 exit 1, 1확인 및 정확 실패 marker. 각 전용 Windows Job 총 2/active 0, SCRIPT ERROR/ERROR/WARNING/ObjectDB·리소스 종료 진단 0.

- busy_precedes_unsupported_cn. tick 1에서 pending stop과 두 미소비 spawn을 보존한 packet의 reinf_ms만 -1→0으로 바꿨다. 구조 검사를 통과했다. 테스트가 직접 busy를 설정한 동안 같은 후보를 공개 restore하자 정확 busy를 반환했고 ready와 busy=true, 활성 객체·캐시·queue/log/events, 입력이 보존됐다. busy 해제 직후의 capture는 원본과 exact였다.
- unbusy_rejects_same_candidate. 같은 owner와 같은 M을 다시 시도하자 정확 unsupported_reinforcement를 반환했다. 기존 sim/state/fleet 및 warm cache, busy=false, ready=true, 패킷·입력·대기·사건이 보존됐다.
- progresses_after_both_rejections. A와 무처리 B는 각각 다음 한 틱 2/200ms, sub 50, AI 350, next_event_id 2에서 일치했다. stop@1 한 건만 log에 추가됐고 pending이 소진됐다. 두 spawn 뒤 tick 1의 say(stop)만 추가됐으며 전체 capture 및 P/M 보존이 exact였다.

실행 manifest SHA256 d4bd7f17e51d10da1187c0cc57657b081e5e0e8d13d559ba98227f52ff5bdc66. 현 HEAD 0be09755b70378286105972f35ac5b7031715664 및 47개 동결 입력 전후 일치. 현 owner SHA 46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3는 기존 reinf-ms의 ac59a7547469c705d33854742e9503b08422770b01956a47861b45735ab8c1c6와 다르다. 기존 양성 복원은 역사 근거이며 이번 runner에서는 양성 재실행을 하지 않았다. Git 상태 차이 8행은 전용 폴더에 한정됐으며 P02/동시 외부 경로 차이 0이었다. 상태 비교는 전체 dirty 파일 바이트 감사와 별개다. [manifest](manifest.json) · [Git 대조](attempt-01/git-comparison.json) · [실행 원문](attempt-01/fixture/stdout.bin)

busy는 강제로 설정했다. 실제 thread/callback 경합·제품 host·외부 저장 및 운영 오류 정책은 미검증이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 독립 사후 5b 대기.
