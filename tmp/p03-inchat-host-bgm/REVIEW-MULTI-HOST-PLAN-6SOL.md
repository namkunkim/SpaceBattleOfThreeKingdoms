# 다중 호스트 BGM 종료 대조 독립 계획 심사 — GPT-6 Sol

판정: **조건부 수용**. `PLAN-MULTI-HOST-LIFETIME.md` SHA-256 `39642c5e2fbd600549dc8ed76eef33244f9154e7b481ff5fc072920b70c3a127` 기준이다. 신규 K6은 4/6 사용했다. 최소 01/02와 단일 호스트 04는 유효 CLEAN이고, 단일 03은 playback 관측 실패로 FAIL이다. 앞선 호스트 시계 attempt-05의 4인스턴스 fixture는 SHA-256 `8d77a8c65dccdd70212f0b02254f8dc112405bcd4fd9f96c67c9b4f782b34273`이며 verbose Ogg 객체 4·resource 2 누수를 보존한다.

05 multi-legacy 1회는 기존 네 호스트 구성, 두 phase별 오류 후보와 정상 게시 대조, 동일 seed·수동 프레임·retire 순서를 회복하는 진단으로 수용한다. 각 `add_child` 직후 disable 전 실제 canonical Ogg·`playing`·playback을 4/4 확인하고, 원래 네 호스트 시계·게시 단언을 유지한다. 이전 fixture와 달라지는 관측 hook을 명시하고 stream 재시작·제품 스크립트 수정은 하지 않는다. actual exit 0, 예상 profile 오류 정확히 두 건, Job active 0, 원본/사본·HEAD/index/status 전후 안정 및 다른 SCRIPT ERROR 0은 진단 유효성 조건이다. verbose Ogg 네 클래스·네 객체, 해당 packet/stream 두 resource의 정확 재현은 인스턴스 번호를 제외한 클래스·경로·건수로 판정한다. 정확 재현은 제품 PASS가 아니다.

**05가 유효한 정확 재현일 때에만** 06 multi-ordered 1회를 수용한다. 05/06의 같은 정본 엔진·Dummy driver·음악/import/캐시·네 호스트 입력 및 baseline fingerprint를 확인하고, 유일한 모드 차이가 각 retire에서 stop 후 stream clear 전 tree 부착 상태의 12 `process_frame`+250ms 대기임을 원문 diff와 이벤트로 보존한다. 대기 중 host의 tick·두 clock phase가 변하지 않는지, player attached·stop→wait→clear→free 순서를 확인한다. 05의 원본 누수와 06의 진단 0이 성립하면 해당 **격리 다중 호스트 fixture의 종료 순서 회피**로만 해석한다. 05가 CLEAN 또는 관측 실패이면 06을 실행하지 않는다. 06도 누수면 K6 소진으로 멈추고 실패 근거를 보존한다.

두 시도는 전용 격리 경로만 쓰며 `hud/ui_kit/ui_sound.gd`, `scripts/FleetBattle3D.gd`, P02 등 공유 파일은 수정하지 않는다. host/engine 일반 원인, 제품 자연 종료·전환, 사용자 청취, 운영 복원·ACK는 이 대조에서 수용하지 않는다. 구현·실행 및 최종 5b는 별도다.
