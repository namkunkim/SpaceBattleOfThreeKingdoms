# data_rules 기준선 실패 해소 결과

2026-10-27 착수 / **2026-10-28(KST) 완료 · 5-a 6종 통과 · 독립 5-b 수용**.

이전 I01a 설정 구현·기록은 `8292805143f4561a4f5258d40b7b94adf4ff5802`에 포함되어 이전 작업에서 main 푸시가 확인됐다. 이번 작업은 그 HEAD의 기존 `data_rules` 실패를 별도로 해소했으며, 이번 변경은 커밋·병합·푸시하지 않았다. 원 I01/I01b 및 원 A04/A05/A06는 NOT_READY다.

## 범위와 변경

- `core/battle/battle_sim.gd:1019`의 `rt()` fallback 인자 `170.0`을 `R.chase_engagement_fallback_r`로 바꿨다. 시나리오의 `range_band_hold.engagement_distance`가 있으면 그 값을 우선한다.
- 수기 규칙 정본 `data/profiles/poc_corridor.json`에 기본값 170을 추가했다. 적벽의 모든 난이도는 기존 `base.rules` 복제 경로로 이 값을 읽는다. 기존 JSON 값은 변경하지 않았다. 이 파일을 덮어쓰는 생성기는 없고, 시나리오 생성기/생성물은 수정하지 않아 재생성으로 이번 fallback이 유실되지 않는다.
- `tests/data_rules.gd`에 실제 `_fleet_phase(false)`를 실행하는 10사례를 추가했다. 시나리오/realtime/부모/leaf 누락 4종 각각 거리169 정지·171 전진, override150/거리160 전진·override200/거리180 정지를 확인한다. 숫자 허용 목록·skip·별도 hold 생산 코드는 유지했다.

## 실제 5-a와 독립 판정

Godot `4.7.2.stable.official.ed1daf0bf`, Windows PC headless. 실행 담당이 정식 권한으로 SHA-256 before/after 가드 복사와 순차 검사를 수행했고 조율자는 흐름을 관리했다.

| 검사 | 실제 결과 |
|---|---|
| data_rules (K2) | exit 0, DATA_RULES_PASS keys=80 core=28 proposed=28 first_move=1814 |
| i01_operation_config | exit 0, 60 builds / 24 named rejections / 17 additional regressions / CHECKS=326 |
| hold_distance | exit 0, HOLD_DISTANCE_PASS |
| commander_ai | exit 0, COMMANDER_AI_PASS |
| core_rules | exit 0, CORE_RULES_PASS |
| battle_flow | exit 0, BATTLE_FLOW_PASS |

작성·수정에 참여하지 않은 검토자가 최종 코드·SHA·실행 로그·변경 감사를 대조하여 [독립 5-b 수용](REVIEW-DATA-RULES-BASELINE-20261027.md)했다. 5-a 통과를 작업자가 최종 수용으로 판정하지 않았다.

K1 data_rules는 누락 fixture가 별도 `_hold_blocker:1135`의 `float(null)`을 실행해 exit 1이었다. K2에서 fixture의 `_hold_d2=0.0`으로 위치 차단을 비활성화해 추격 임계 분기를 고립했다. 추격 입력·위치/moving oracle와 10사례는 보존했다. 기존 별도 hold 경로의 누락 입력 지원은 이번 수정 범위가 아니며 생산 코드에서 고치지 않았다. 재시도는 K=6 중 2회다.

최종 data_rules·hold_distance·commander_ai·battle_flow 로그에는 종료 후 ObjectDB leak/resources-in-use 진단이 있다. 이 4종도 종료 코드0 및 PASS 표식이 있으나 clean shutdown을 보장하지 않는다. 변경 전 동일 진단이라는 실행 증거가 없어 기존 현상이라고 단정하지 않는다.

## 증거와 0번 되먹임

증거 루트는 `C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/data-rules-fix-20261027-chase-fallback`이다. 날짜가 넘어가도 10-27 시작 증거 이름과 원본은 보존했다. `manifest.json`/`test-results-k1.json`/`final-change-audit-k1.json`은 K1 이력, `manifest-k2.json`은 K2 실행 전 생성 이력, `test-results.json`/`final-change-audit.json`/`logs/change-k2.diff` 및 각 로그는 최종 코드 3파일 검사 증거다. manifest의 pending 문구는 생성 당시 상태이며 최신 판정은 이 문서와 독립 검토다.

최종 코드 감사는 HEAD 불변·실질 diff 정확3파일·status 추가3개/제거0개를 확인했다. 원래 CRLF 바이트 형식을 보존하고 `core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol`의 `git diff --check` 종료0을 확인했다. CRLF를 문자 그대로 검사한 첫 exit2는 형식 진단 이력으로 보존했다. 원프로젝트의 무관 dirty14개나 import 메타데이터를 정리하지 않았다.

되먹임: 추격 임계 단위 fixture는 별도 위치 차단을 명시적으로 고립해야 한다. 데이터 fallback은 수기 정본/생성기 소유권을 확인한 뒤 옮기고, CRLF checkout의 공백 검사는 `cr-at-eol`을 명시한다. 다음은 I01b의 공간·논리시계·지속 상태 계약 준비와 독립 검토다. 실제 host/runtime/save 통합·저장/재생·게임/GUI·사람 플레이·플랫폼 전체 회귀를 이번 결과로 완료 표시하지 않는다.