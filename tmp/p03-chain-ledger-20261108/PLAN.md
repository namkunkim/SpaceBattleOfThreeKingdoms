# P03 ChainOp 동적 상태 책임 원장 계획

2026-11-08 KST. **읽기 조사 계획, 독립 심사 대기, 코드/Godot 미착수.** Sol 실행 / Terra 심사 명시 배정, Astra 제외. P02 revision8은 FleetBattle3D 초기화의 trace·리소스 진단 반증 중이다. 공통 owner 소유 이관 근거는 없다.

기존 P03 상태 조사는 계략을 모듈 한 행으로 다뤘고 제한 private owner는 `chain`을 거부한다. 새 원장은 `stratagem.gd`의 20개 선언을 모듈 인스턴스·설정, 상태/충전/의심, 화공 창, 불길과 만료, counter/결정, 통계의 실제 초기화·갱신·소비에 연결한다. 후보 capture/rebuild/rebind/recompute는 현재 지원이라고 해석하지 않는다. P02/생산 공유 경로는 읽기만 하고 전용 문서·SHA에만 쓴다.

독립 5-a 분모는 선언 20개 및 동적 상태 5묶음(`warned`, `fires`의 내부 burned/counter 포함, `_revert`, `_hazards`와 terrain.zones, `stats`). 각 동적 record의 실제 key/타입/삽입순서/ID·객체 결합·tick 단위·갱신/소비 source:line을 추적한다. `host_sq`(편성 ID), fleet runtime ID, 구역 ID, `card_id`(DecisionBoard) 및 `next_event_id`가 다른 공간인지 구분한다. 시계·첫 명중 `first_hit_tick` 및 `sensor_until` 소비, 타이머 실행 순서, 외부 모듈 alias와 공개/비공개 projection/fingerprint의 한계를 별도 적는다.

후속 반례는 (1) 화공 spread의 burned/counter 상태나 순서를 잃은 동일 suffix, (2) hazard 목록과 terrain.zones의 만료 ID가 어긋나 다른 구역이 지워지거나 지속, (3) decision card·_revert·sensor 만료 시점에 중복 처리/유실이다. 실제 실행 확인은 기존 테스트 분모와 분리한다. 수치·동일 틱 정책·저장 스키마/원장을 확정하지 않는다.

정본 ChainOp와 실제 외부 소비/참조 소스, D04/ST07·ST12·ST18 및 기존 private 거부 근거의 SHA를 전후 동결하고 문서의 행 수·링크·refs/index를 검사한다. 문서 K3, 사용량 제한 즉시 보고·반복 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
