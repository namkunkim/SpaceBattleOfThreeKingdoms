# DecisionBoard 단독 가드 독립 5-b

2026-11-08. **승인된 제한 변경과 관측 수용.** 심사자는 구현에 참여하지 않았다. 세션 `01a1ba45-75d3-7dc3-980c-1d24d6111709`의 이번 turn 로컬 rollout 최신 turn_context는 2026-11-08T10:25:17Z `gpt-6.1-terra`다. 작업자 모델은 실행 기록의 확인에 따른다.

원본 snapshot SHA `ac59a7547469c705d33854742e9503b08422770b01956a47861b45735ab8c1c6`과 현재 SHA `46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3`를 재계산하고 diff를 대조했다. 변경은 `_guard()` 성공 직후 busy 설정과 prepare 전에 `decisions` 존재를 검사해 `unsupported_active_decisions`를 반환하는 승인된 두 줄 한 hunk다. 다른 비지원 모듈이나 전체 bindings 검사를 추가하지 않았다.

guard probe는 24개 단언 true, actual exit 0, 진단 0이다. 강제 주입된 정본 모듈의 유효 packet 거부에서 owner/sim/모듈 identity, 역참조·marker, tick/clock·pending·events와 ready/idle 및 packet을 확인했다. busy, unprepared, 활성 모듈, 잘못된 packet의 순서를 대조하고 fixture 정리 후 무개입 owner와 후속 명령·사건을 비교했다. 기존 scenario 거부와 정상 교체, 이전 owner 지문의 `code_mismatch`도 검증했다. 이는 강제 fixture의 제한 결과다.

I01b 복제본은 20 cases·20099 checks·8 rejections, P02 headless adapter 복제본은 8 cases·13417 checks·32 rejections이며 각각 actual exit 0, 진단 0이다. 두 복제본은 각 정본과 출력 경로 상수 한 줄만 다르다. P02 결과는 worker adapter 시험이 아니라 headless adapter 회귀다. 두 회귀의 `engine_identity_matches:false`는 해당 출력에 엔진 PID payload가 없기 때문이며, Job 총 2·active 0과 실제 console 종료는 기록돼 있으나 본체 PID/path의 독립 일치 확인은 주장하지 않는다.

세 실행 각각 117 입력의 전후 및 현재 SHA 차이 0, HEAD 불변이다. 시작 108 입력의 현재 차이는 승인된 owner 파일 1개뿐이다. 제품 경로 도달, 다른 활성 모듈, 외부 스키마 및 UI·외부 효과 원자성은 미검증이다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
