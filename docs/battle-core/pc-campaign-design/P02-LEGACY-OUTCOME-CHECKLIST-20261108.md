# P02 legacy WorldMap 결산 경계 체크리스트

2026-11-08 KST. 적용 범위는 legacy 결산 경계다. P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**.

- [x] 정본 엔진·클래스 캐시, 공통 4,209개 입력, 제품 파일 원문, v3 사전 오라클 동결. v2의 실패와 우회 이력을 따로 보존. [오라클 동결](../../../tmp/p02-fifth-20261108/v3/oracle-freeze.json)
- [x] legacy worker 사본 반환, join·취소 확인 후 결산, join된 legacy에 한한 오류 fallback. 제품 자동/직접 화면과 취소 두 경로 검증. [결과](P02-LEGACY-OUTCOME-RESULT-20261108.md)
- [x] v3 공통 18행·106단언 양쪽 일치, 경계 7행·33단언 통과. clean-user WorldLink 기존 1실패 유지, returning-user WorldLink 양쪽 통과. [5-a](../../../tmp/p02-fifth-20261108/v3/gate-verdict.json)
- [x] 비-Astra 독립 구현 5-b 한정 수용. 심사 세션 `/root/p02_fifth_review`, 요청 모델 gpt-6.1-terra, 실제 모델 미확인. [심사](../../../tmp/p02-fifth-20261108/REVIEW-5B-INDEPENDENT.md)
- [ ] 전달 ZIP과 문서의 독립 마감 판정.
- [ ] 제품 operation 입력·진행·취소·결산, FleetBattle3D 호스트와 제품 replay 공동 인수.
- [ ] 실제 1800초 상한 도달, OS Thread.start 실패·엔진 예외·손상 sim·동시 writer 및 수동 GUI·Android·성능 검증.
