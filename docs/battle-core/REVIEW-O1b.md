# REVIEW-O1b — 조각 O1b 리뷰 (Sonnet 5.5, 구현과 다른 모델)

## 범위
커밋 38b521b(병합 e4eac12). 대상: `core/battle/organization.gd`, `tests/organization_rules.gd`. 기준: CHECKLIST-OPEN §8 "O1 리뷰" ①~④. 코드는 고치지 않았다.

## 실행한 테스트
`--import` 후 헤드리스. (Godot 종료 시 ObjectDB 누수 경고는 모든 실행에 있고 무관.)

| 테스트 | 결과 |
|---|---|
| organization_rules | ORGANIZATION_RULES_OK (약 3분 40초). 3시드 전투 종료·재생 지문 출력 확인 |
| roster | ROSTER_PASS |
| data_rules | DATA_RULES_PASS |
| core_rules | CORE_RULES_PASS |
| succession_rules | SUCCESSION_RULES_PASS |
| autoresolve `--profile red_cliffs --runs 3` (기본) | 완료(AUTORESOLVE_RC_DONE), 승률 1.0 |
| autoresolve 동일 + `--org auto` | 완료, 크래시 없음 |
| salvo_compare `--runs 10` | 완료, 크래시 없음 |
| boundary | 실행 안 함(기존 실패로 알려짐) |

## ①~④ 확인
1. 충족. `apply`가 `validate`를 먼저 돌려 실패 시 `{"errors"}` 반환(organization.gd:254-257). 테스트가 사유 코드별 케이스마다 `r.has("errors") and not r.has("ally")`로 확인하고 `{}`·`{"fleets":"x"}`·`["x",3]` 쓰레기 입력도 거부(organization_rules.gd:71-75). validate 앞머리 `fleets` 타입 검사(:62-63)와 `_fleet_shape`(:77, :129-146)가 크래시를 막는다.
2. 충족. missing_fleet(:119-121), 모르는 장비(:112, 키는 `combat.detection.equip_sensor`:69), 중복 함종(:112 `types`), 비정수·누락 count(`_is_int`, :129 이하; 누락은 `get`이 null이라 bad_fleet), 가용 밖 기함 제독(`_people`가 admiral 포함, :103-104 foreign_officer). float 정수(JSON 왕복)는 받고 apply가 int로 정규화.
3. 충족. 참모를 보직 순으로 정렬(:284), 기본 데이터가 이미 그 순서임을 테스트로 고정(organization_rules.gd:42-47).
4. 충족. 잘못된 org apply(:63-75), apply 뒤 승계(`_succession` :184 이하, 참모 역순 입력에도 강습이 첫 계승자), 장수 부족 7·2명(`_shortage_and_ties`), 동점 ID, 끈 함대 2개 + 3세력 자동 편성 전투 종료 + JSON 왕복 헤더 재생 지문 3시드(END_SEEDS=[1,2,3], :9, :215-231).

## 호출부(apply 반환형 변경)
`Organization.apply` 호출처를 grep(`.claude/worktrees` 사본 제외): 코어·뷰·hud에는 없음. 호출은 tests/organization_rules.gd와 tests/autoresolve.gd:271뿐이다. organization_rules는 전부 `has("errors")`를 확인하거나 유효 입력만 넣는다. **autoresolve.gd:271은 `has("errors")`를 확인하지 않는다**(발견 #1).

## 장비 검사 기준
`equip_sensor`(data/profiles/combat_m3.json:689-694)에 FAST-EQ-INTERCEPT/TORPEDO/RECON/RESCUE 4종이 모두 있다. 기본 편성·자동 편성(FILLER_EQUIP)이 validate를 통과하고 default org apply 지문이 동일해 정상 데이터 오거부는 없다. 다만 기준이 detection 센서 표여서 "유효 장비 목록"과 의미가 어긋난다(#3).

## 기본 경로
`apply(profile, default_org)` 지문이 직접 로드한 프로필과 같음을 테스트("default org keeps result", :139-141)로 확인했다. 편성 화면 없는 경로(autoresolve 기본)는 apply를 거치지 않아 변화 없음. 기본 autoresolve 결과 정상.

## 발견 사항
| 심각도 | file:line | 내용 | 권고 |
|---|---|---|---|
| 낮음 | tests/autoresolve.gd:271 | `--org auto`에서 apply 결과를 `has("errors")` 확인 없이 `p`에 대입. 검증 실패 시 `p`가 `{"errors"}`가 되어 `_tune(p.combat)`에서 불투명한 크래시. 현 데이터는 통과해 지금은 문제 없음 | `if p.has("errors"): push_error(...); quit(1)` 한 줄 |
| 낮음 | organization.gd:254-257 | 반환형이 성공(프로필 사본)과 실패(`{"errors"}`)를 한 Dictionary로 섞음. 호출부가 확인을 빠뜨리기 쉬운 형태(#1이 그 예). O4 편성 화면은 `validate`를 따로 부르므로 당장 해는 없음 | O4 착수 시 규약을 SESSION-HANDOFF에 명시하거나 `apply_checked` 래퍼 고려. 필수 아님 |
| 낮음 | organization.gd:69, 112 | 장비 유효성 기준이 `detection.equip_sensor` 키. 센서 표에 없는 새 장비가 생기면 정상 장비를 거부한다. 지금은 4종 모두 포함. 빈 문자열 `""`(salvo.gd:44는 "장비 없음"으로 허용)은 여기서 거부 | 장비 ID 정본 표가 생기면 거기로 옮기고, 지금은 주석으로 남긴다 |
| 낮음 | organization.gd:112, :131-146 | count가 1e30 같은 큰 float이면 `_is_int`는 통과하고 `int()` 변환에서 오버플로 가능. 상한 검사 없음(비용 한도는 별도) | count 상한(예: 한도 이내) 검사. 재생 헤더 방어 강화 시 |
| 낮음 | tests/organization_rules.gd:55-70 | 사유 케이스에 기함 제독 가용 밖(foreign_officer의 admiral 경로)과 count 키 누락이 없다. 코드는 맞게 처리하지만 테스트로 고정되지 않음 | 케이스 2개 추가 |
| 정보 | tests/organization_rules.gd | 테스트 소요 약 3분 40초. 사용자가 CI에서 돌릴 경우 부담 | 필요 시 전투 종료 시드를 줄이거나 분리 |

## 판정
**수용.** ①~④ 모두 충족, 관련 테스트 전부 통과, 기본 경로 결과 불변, 정상 장비 4종 오거부 없음. 위 낮음 항목은 O4 전에 autoresolve 1줄(#1)만 처리하면 되고 나머지는 이월해도 된다.
