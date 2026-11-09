# P03 독립 후속 후보 — 보급 완료의 상태 책임

2026-11-08 KST. **읽기 전용 계획 후보, 독립 심사 전, 코드/Godot 미실행.** P02 revision6은 실제 전투 화면의 초기화 candidate/commit 후보를 조사 중이다. 공통 owner 쓰기 권한 이관 근거는 없다. 기존 Dictionary MISMATCH와 접촉 만료 공개 계약은 별도로 남는다.

기존 P2b의 SUP_FIELDS 10개와 활성 교체의 보급 완료 재현을 되풀이하지 않는다. 작은 후속은 **SupplyCore의 7개 선언, FleetState sup_* 10개, 그리고 보급 완료에서 함께 변하는 slice 밖 자원/손상/사건의 갱신·소비 책임표**다. `supply.gd:158–231,245–294`의 예약 유지→빈자리 우선순위→진행 증가→완료 지출과 `operation_service_state.gd`의 부분 복원 경계를 소스에 연결한다. 기존 root/P02 공유 경로는 읽기 전용이다.

사전등록 분모는 모듈 선언 7, slice 10 및 완료 주변 상태 묶음 4(탄약/charge, damage stages/repair, 공급원 재고·우선권, event/누계)다. 각 항목의 타입·단위·소유·초기/갱신/소비 source:line, capture/rebind/recompute 및 현재 미검증 책임을 표시한다. 동적 source key·fleet ID·ordered bases와 step 지역 `used/ratio`의 재계산을 분리한다. 최소 반례는 **(1)** 이전 progress만 복원해 다음 completion에서 재고/repair 중복, **(2)** 동일 거리 공급원 동률에서 순서 손실, **(3)** 이동·이탈 뒤 한 step 이전의 stale source ID와 다음 step 재검증이다. 기존 결과에서 실제로 검증된 반례만 실제 증거로 표시한다.

입력은 D04 ST11/ST18, D07의 재고 책임, P2b/P2c/활성교체, SupplyCore/FleetState/SalvoCombat/Service/Private와 실제 P02 소비 경계다. SHA 전후·Git refs/index·링크/행수·미결 분리를 검사하고 독립 문서 심사를 받는다. 문서 K3, 사용량 제한 즉시 보고·반복 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
