# P03 보급 완료 시점 혼합 packet 관측

2026-11-08 KST. **REJECTED_ATOMIC.** 실제 tick600의 보급 주기에서 중파가 2→1, 공급 물자가 8→7이 됐고 supply 사건에는 repair=1이 기록됐다. 정합한 완료 후 B의 다음 step은 새 진행만 쌓였다. B의 손님 `view.service.supply.fleets[1].values.sup_prog` 한 필드만 완료 전 A 값으로 되돌린 C는 `restored_state_mismatch`로 거부됐다. active sim·정본 상태·packet·busy가 유지됐으며 이후 정상 step은 B 대조와 일치했다. [독립 5-b](REVIEW-5B-attempt-04.md)

`sup_prog`는 fleet view와 service slice에 모두 있고, 이번 C는 그중 service 한 필드만 바꿨다. 현재 거부는 두 사본의 재관측 불일치와 일치한다. 두 사본을 같은 값으로 되돌린 교차 시점 혼합, 전체 자원 지출의 원자성, 실제 플레이 피해 또는 P02 supply 완료 E2E는 별도다.

정본 attempt-04/K6 actual Godot exit0, 명명4·1234 단언(반복 advance/drain 포함), 46개 입력 전후 SHA 일치 및 오류/경고/누수0. 01은 multiline if 파싱 실패, 02/03은 계획의 4척 대신 기존 fixture의 2척을 복제한 전제 실패였다. 04에서 사전등록한 4척으로 구현을 바로잡았다. 실패 로그는 그대로 남겼다. [실행](attempt-04/run.json)

시작 dirty 20298개 재해시는 누락0·변경0, 실행 입력46 drift0. 신규 외부112는 P02 화면 초기화 작업 관측으로 분리했다. 기존 전체 diff-check exit2와 새 전용 파일 공백 검사를 분리한다. [보존 감사](preservation.json)

전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. Dictionary metadata 결함, 접촉 만료 공개 정책·실제 UI, P02 공유 소유권을 이 관측으로 해소하지 않는다.
