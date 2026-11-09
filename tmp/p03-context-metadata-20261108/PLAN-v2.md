# P03 typed context 계획 보완 v2

2026-11-08 KST. [초안](PLAN.md)을 보완한다. Dictionary 관측 방향은 **typed active Dictionary[String,int] → untyped candidate {"k":7}** 한 방향이다. 역방향은 이 조각의 분모에 넣지 않는다.

- `MATCH`는 입력, capture packet 및 독립 prepare owner에서 유일 metadata 차이가 유지되고, active restore가 정확히 `replacement_context_mismatch`를 반환하며 활성 상태/packet/busy 무변이와 다음 정상 advance가 확인된 경우만 기록한다.
- `MISMATCH`는 같은 전 과정에서 유일 metadata 차이가 유지됐고 실제 active restore가 성공해 sim이 교체됐으며 이 성공 분기의 packet·owner 불변식이 확인된 경우만 기록한다.
- 그 외 reason의 거부, prepare/사전조건 실패, 중간 metadata 손실 및 결과 불확실은 **관측 절차 실패**다. MATCH/MISMATCH의 표본으로 간주하지 않으며 actual gate nonzero와 상세 단계를 남긴다.

명명 5개, 새로운 K6 0, 공유 경로 읽기 전용 및 독립 계획 심사 전 실행 금지를 유지한다.
