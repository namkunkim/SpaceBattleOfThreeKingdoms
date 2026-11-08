# P02 legacy WorldMap 결산 경계 인계

2026-11-08 KST. [결과](P02-LEGACY-OUTCOME-RESULT-20261108.md)와 [전용 체크리스트](P02-LEGACY-OUTCOME-CHECKLIST-20261108.md)를 기준으로 이어간다. P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**.

- worker의 legacy 결산 자료와 메인 join 후 게시 경계를 [AutoResolver](../../../scripts/world/auto_resolver.gd)와 [BattleOutcome](../../../scripts/world/battle_outcome.gd)에 분리했다. 직접 지휘와 blocking은 기존 진입점을 사용한다. 제한 operation에는 legacy 결산 fallback을 추가하지 않았다.
- 기존 clean-user WorldLink의 서막/브리핑 단언 실패는 v3 전후 동일하며 returning-user는 양쪽 통과했다. 원본 common 오라클과 두 고정 입력의 재실행 근거는 [5-a](../../../tmp/p02-fifth-20261108/v3/gate-verdict.json)에 있다. [독립 구현 심사](../../../tmp/p02-fifth-20261108/REVIEW-5B-INDEPENDENT.md)
- 다음 계약을 시작할 때 제품 적벽/Victory를 지원할 owner와 입력·결산 책임을 먼저 정한다. WorldMap 진행·취소·join 및 FleetBattle3D 시계·controls·배치·명령·투영·사건·선택·카메라·trace의 인수는 별도다. 제품 replay도 남는다.
- 새 증거는 [전달 ZIP](../../../tmp/p02-fifth-20261108/closeout/P02-LEGACY-OUTCOME-DELIVERY-20261108.zip)에 담았다. 독립 마감 판정은 ZIP 외부에 별도 기록한다. 신규 미귀속 파일은 첫 관측 이후 비교만 제공하며 기존 산출물과 P03 변경을 분리한다.
