# I01b-P2b 진행 체크리스트 — 탐지·보급 부분 인메모리 복원

2026-10-31 KST. 이 문서는 현재 P2b의 단일 진행 체크리스트이며, 전체 I01b/A04~A06는 **NOT_READY**다. [계획](../../../tmp/i01b-next-20261031/PLAN.md)에 따라 진행하고 구현과 독립된 검토자가 최종 판정한다.

## 목표와 경계

기존 비초기 Detection contacts와 함대 sup_*10개만 깊은 사본으로 추출하고, 이미 생성·준비된 target의 기존 모듈/함대에 검증 후 적용한다. 현재 부분 helper는 전체 ST11, C0/Cn checkpoint, 저장파일·외부 스키마, host/headless/replay 통합이 아니다. save schema는 UNCLASSIFIED로 남긴다.

ammo/wch/stages/hit_tick/healed_wound/healed_mod/supplied, 위치·다른 모듈·명령/사건 등 비대상 상태는 호출자가 먼저 동일 경계로 복원해야 한다. 단순 config/시계/roster 일치만으로 전체 상태 동등성을 보장하지 않는다. 기존 전투 실행 코드는 수정하지 않으며 커밋·푸시는 하지 않는다.

## 단계별 현재 상태

- [x] 0: 플레이북·CLAUDE·인계·H2/I01/ST11/ST14 확인, feature HEAD fb660ce/index 비어 있음 확인.
- [x] 0: 기존 추적 변경·미추적 3594경로 SHA 동결 (`tmp/i01b-next-20261031/before.json`).
- [x] 1~3: 목표·부분 범위·상태 분류·비대상 선행조건·소유 경로·5-a/5-b·K6 계획 작성.
- [x] 3: 독립 계획 심사 수용, 기존 코어 파일 불변 조건 확인.
- [x] 4: 신규 helper `core/battle/operation_service_state.gd`와 신규 검사 `tests/i01b_service_state.gd` 구현.
- [x] 5-a 신규: 최종 attempt5 실제 exit0, 40사례/10seed/2202체크/33명명 거부 PASS. SCRIPT ERROR/ERROR/누수 진단 0.
- [x] 5-a 회귀: core/data/config/clock/detection/supply 6종 실제 exit0 및 PASS 원문 확인. data/detection/supply의 기존 종료 리소스 진단은 남는다.
- [x] 5-a 보존: 기존3594경로 변경0·누락0, source22개·최종 코드/입력/로그 SHA 명세. 사용자 요청으로 추가한 상위 체크리스트 한 행은 별도 원문 복구 해시로 보존을 입증했다.
- [x] 5-b: 독립 최종 수용. source/engine/관측/attempt/회귀 51 SHA 불일치0, 기존3594경로 직접 재해시 변경0·누락0 및 체크리스트 한 행 외 원문 일치 확인. [독립 심사](REVIEW-I01B-P2B-20261031.md).
- [x] 6: [결과·후속 인계](I01B-P2B-RESULT-20261031.md), 이 문서와 상위 체크리스트 완료행·독립 심사 링크·최종 보존 감사/manifest를 기록했다. 기존3594 전부 동일·누락0, CHECKLIST는 별도 한 행 외 원문 SHA 일치, helper/test는 5-b 후 동일하다.

## 검증한 부분과 최종 심사에서 지킬 기준

- [x] contacts의 실제 키·타입·삽입 순서·과거 pos/seen과 sup_*10개를 사본으로 보존.
- [x] contacts 고정 진영 수2, malformed source/packet 길이1·3 거부와 오염된 target 길이 복구.
- [x] 실제 estimated/lost 기억·진행 중 보급/완료 후 재고 지출을 확보하고 suffix가 평가/보급 완료 경계를 통과.
- [x] 복원 생략/현재 적 위치로 기억 덮어쓰기 차이 검출, **완료 후** constructor 역순의 재고 reset 반례.
- [x] 마지막 contact/fleet 오류도 적용 전 원자 거부, 거부한 packet/target 불변(순환·NaN·Object 입력 포함).
- [x] source/packet/target mutable alias 격리 및 기존 target 모듈/함대 identity와 참조 유지, 재적용 추가 효과 없음.
- [x] 비대상 상태·사건·명령 불변과 prepared source/target의 명시적 선행 동등성을 실제 비교.
- [x] attempt1 오류와 attempt2의 SCRIPT ERROR 후 PASS/exit0는 무효 이력으로 보존. 최종40/33완결 guard로 검사 구간 누락을 방지.
- [ ] 전체 저장·재개/전체 상태·원자 게시/명령 커서·제품 공간·host/replay 연결은 후속이며 이번 완료로 승격하지 않음.

증거 폴더: `tmp/i01b-next-20261031/`. 코드 K6 중 실행5까지 사용했고 최종 attempt5가 통과했다. JSON의2201체크는 evidence 파일 열기 검사 직전이며 stdout2202는 그 검사까지 포함한다. 종료 정리의 참조 해제는 관측 이후 별도 변이다.