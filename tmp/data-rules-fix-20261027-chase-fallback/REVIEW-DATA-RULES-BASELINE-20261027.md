# data_rules 기준선 오류 해소 독립 검토

2026-10-28 KST / data_rules_review / **수용: 지정 3파일 수정과 6종 기계 gate 통과.**

검토자는 코드·데이터·검사 작성 및 실행에 참여하지 않았다. 플레이북의 계획 2/3단계 검토 후 최종 5-b를 수행했다. 작성자 data_rules_fix가 정식 권한으로 target 배치와 Godot gate를 실행했으며 부모는 조율을 맡았다. 이번 검토자는 원문·diff·감사·실제 로그를 읽고 이 리뷰 문서 하나만 작성했다.

## 기준과 범위

대상은 `C:/Users/nk782/.codex/worktrees/i01a-operation-config/SpaceBattleOfThreeKingdoms`, 감사 HEAD `8292805143f4561a4f5258d40b7b94adf4ff5802`다. 입력은 저장소 CLAUDE.md·워크플로우-플레이북.md·SESSION-HANDOFF.md·CHECKLIST-OPEN.md의 PC 캠페인 블록, I01a 결과/독립 리뷰와 기존 326 PASS·170.0 FAIL 로그다. 적용 경로·확인한 상위 폴더에서 추가 AGENTS.md는 발견하지 못했다. 원 프로젝트의 무관한 dirty나 PC 실험 변경을 통합하지 않는다.

기존 data_rules는 리터럴 검사 첫 실패 후 반환하여 후속 항목이 미검증이었다. 이번 수정은 추격 기본값 170과 시나리오 override 우선권을 보존하며 그 차단과 후속 gate를 해소하는 범위다. 실제 캠페인 구현·I01b·원 A04/A05/A06 완료를 뜻하지 않는다.

## 최종 코드·정본 검토

- core/battle/battle_sim.gd는 기존 `rs.rt("range_band_hold.engagement_distance", 170.0)`의 fallback 인자만 `R.chase_engagement_fallback_r`로 교체했다. 분기·maxf·돌격·이동·별도 hold blocker는 그대로다.
- data/profiles/poc_corridor.json의 rules에 `chase_engagement_fallback_r: 170` 하나를 추가했다. 검토자가 JSON 파싱과 이 추가 줄 제거 후 변경 전 raw text 일치를 직접 확인했다. PocSetup이 이 수기 데이터 정본을 복제하고 ScenarioProfile이 해당 base rules를 상속한다. RuleSet의 R 접근과 data_rules의 POC/적벽 키 존재·unused 검사에 새 키가 정식 참여한다.
- tools에서 POC 데이터 생성 writer를 발견하지 못했다. 적벽 생성기 make_red_cliffs_208.py는 data/scenarios/red_cliffs_208_realtime.json만 출력한다. 해당 생성기·생성물의 engagement_distance=170은 유지했다. 별개 함종 사거리 170을 재활용하거나 문자열로 숫자를 숨기지 않았다.
- tests/data_rules.gd는 기존 숫자 allowlist·예외·후속 검사와 PASS 기준을 유지하고 10개 실제 추격 회귀를 추가했다. scenario 전체/realtime/부모/leaf 누락 4종 각각 거리169 정지·171 전진, override150/거리160 전진 및 override200/거리180 정지를 검사한다. salvo·assault 활성, charge0, 보이는 지정 표적, 기존 사거리 비율 임계 미달을 확인한 후 실제 _fleet_phase와 위치·moving을 함께 검사한다.

검토자가 target 3파일 SHA-256을 직접 읽어 manifest-k2.json 및 final-change-audit.json과 일치함을 확인했다.

| 파일 | 최종 SHA-256 |
|---|---|
| core/battle/battle_sim.gd | 670916af166c1f67fd58f6ab3007782a598a7a8f6fea72024042e1945beb967a |
| data/profiles/poc_corridor.json | bb7c2dbaa8c258dc8b43f16894502a72cb66a22d2058b5d5314816a0488e9d8e |
| tests/data_rules.gd | e21db4b23e9814bb89cae2fc5f5e8f5751b6dcdb952fb3da01cc68da8af670d3 |

감사 증거는 정확 위 3파일 변경, status_removed 0, cr-at-eol을 인정한 whitespace 검사 exit0을 기록한다. 원래 CRLF를 유지하며 불필요한 일괄 정규화를 하지 않았다. 검토자의 직접 Git 명령 실행 결과가 아니라 실행자가 보존한 감사·diff와 target 원문 대조 결과다.

## 실제 5-a와 K1/K2

Godot 버전 표식은 `4.7.2.stable.official.ed1daf0bf`다. test-results.json의 6개 로그를 직접 읽고 각 로그 SHA-256을 대조했으며 6건 모두 일치했다. 종료코드는 실행자의 보존 JSON을 근거로 확인했다.

| 검사 | 종료·표식 |
|---|---|
| data_rules K2 | 0, DATA_RULES_PASS keys=80 core=28 proposed=28 first_move=1814 |
| i01_operation_config | 0, a01~a06 PASS, 설정60·명명거부24·추가17·CHECKS326 |
| hold_distance | 0, HOLD_DISTANCE_PASS |
| commander_ai | 0, COMMANDER_AI_PASS |
| core_rules | 0, CORE_RULES_PASS |
| battle_flow | 0, BATTLE_FLOW_PASS |

K1 data_rules는 missing-0-outside fixture가 기존 _hold_blocker의 별도 rt 조회에서 float(null)에 진입해 script error와 TEST_FAIL로 종료했다. logs/data_rules-k1.log와 test-results-k1.json을 보존한다. K2는 fixture의 `_hold_d2=0.0`과 이유 주석 2줄만 추가해 별도 위치 차단을 고립했다. 이는 추격 fallback/override 입력이나 결과 oracle를 약화하지 않는다. fallback을 제거하면 거리169 정지 사례가 여전히 실패하고 override를 무시하면150/200 사례가 실패한다. 별도 hold_distance 전체 gate도 통과했다. 기존 hold blocker의 누락 realtime 지원은 이번에 고치거나 새로 보증하지 않는다.

다른 5종은 K1 때 실행한 결과다. K2에서 해당 실행이 읽는 production 2파일과 5개 runner가 변하지 않고 data_rules fixture만 달라졌으므로 그 결과를 재사용하는 것이 적절하다. 코드 재시도 K=6 이내의 2회다. manifest-k2의 pending 문구는 gate 실행 전 생성 시점 이력이며 최종 결과는 test-results.json과 본 판정으로 구분한다.

## 잔여 한계와 0번 되먹임

data_rules·hold_distance·commander_ai·battle_flow 로그에는 PASS 뒤 종료 시 ObjectDB 누수 경고 및 resources still in use 오류가 있다. 6개 gate의 종료0·인수 PASS를 취소할 script/TEST_FAIL은 최종 로그에서 발견하지 못했지만, 깨끗한 종료나 누수 회귀 부재까지 검증했다고 쓰면 안 된다. 변경 전 동일 실행 비교가 없어 이 메시지를 기존 기준선 문제라고 확정하지 않는다. 이번 제한된 수치 이동의 잔여 반려사항으로 보지는 않으며 후속 자원 수명 검토로 남긴다.

실패 패턴 되먹임: 실제 추격 분기의 단위 검사는 별개 위치 차단·시야·사거리 조건을 명시적으로 고립해야 한다. 숫자 리터럴을 정식 profile rules로 옮길 때 POC 수기 정본과 상속 프로필의 키 존재, rt 우선권, 생성기 출력 경계를 함께 확인한다. 첫 리터럴 검사 실패 뒤 후속 검사는 미실행으로 기록하고, 수정 후에는 전체 data_rules PASS를 확인한다.

지정 data_rules 기준선 오류 해소와 두 I01a 검사 gate는 이번 범위에서 통과했다. I01a 326은 순수 설정/fixture 결과다. 원 전체 I01/I01b와 원 A04/A05/A06, host/runtime/save/suffix·실제 공간 통행·PC 화면·성능·사람 플레이 및 Q67 후속 판단은 남는다. 커밋·병합·푸시와 다른 작업 통합 여부는 별도다.