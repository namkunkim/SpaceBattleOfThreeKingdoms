# P03 다음 비충돌 후보 — 특기 즉시 효과와 만료 상태

2026-11-08 KST. **읽기 조사 후보, 독립 계획 심사 대기.** P02 revision9는 FleetBattle3D 초기화 마감의 공유 문서 줄바꿈·압축 보완 중이다. owner SHA c5550999…9a6e 유지, 쓰기 소유 이관은 확인되지 않았다. 공유 core 및 P02 문서를 바꾸지 않는다.

다음 범위는 ST07의 `SkillCore` 7개 선언 및 FleetState의 `skill_slots/skill_used/fx`, `side_fx` 효과 record다. 기존 계략 원장은 화공/terrain/Decision 카드이고 이 조각은 **특기의 즉시 자원·사기 변경과 만료 가능한 효과를 분리**한다. 시전자/수혜자/guard 참조, _views의 공개 투영 cache, 사용 횟수, side와 함대 효과 결합 순서의 실제 작성·갱신·소비 source:line을 분류한다. 현재 제한 owner의 skills 거부는 유지한다.

새 문서의 최소 반례는 ① 즉시 charge/회복/사기 지급이 snapshot에 이미 포함된 경우의 재적용, ② fleet fx와 side_fx의 순서 및 만료 tick 변경, ③ guard/시전자 ID 또는 AI _views의 stale 투영이다. source에서 확인한 분류와 미실행 반례를 나눠 적는다. 7 선언·3 FleetState 필드·세 반례, 입력 SHA/refs/index·링크 검사를 문서 5-a로 두고 독립 대조한다. 제품 효과 순서/외부 schema를 확정하지 않고 코드/Godot 실행도 하지 않는다. 문서 K3, 사용량 제한 즉시 보고·반복 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
