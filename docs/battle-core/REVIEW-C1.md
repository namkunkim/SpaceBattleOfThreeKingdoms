# REVIEW-C1 — C1(0e2735c, cb787f8, 병합 4a497e3) 리뷰

리뷰어: Sonnet. 코드 수정 없음, 커밋 없음. 2026-10-11. 범위: `git diff 7d588e8..4a497e3 -- core/`.

## 1. 요약 판정: 수용 (낮음·정보 지적만 남음)

다섯 최적화 모두 현재 코드·데이터에서 원래 판정과 논리적으로 동치다. 부동소수 연산 순서, RNG 호출, emit 순서, 순회 순서를 바꾸는 곳은 찾지 못했다. 동치가 깨지는 반례는 없다(이론상 반례 1건은 지적 1, 현 데이터에서는 도달 불가).

## 2. 실행한 테스트
| 테스트 | 결과 |
|---|---|
| detection_rules | DETECTION_RULES_PASS |
| commander_ai | COMMANDER_AI_PASS |

두 테스트가 qualifying·조준점·sight_foe 경로를 직접 친다. 종료 시 리소스 경고 17건은 기존과 같다. 구현 세션의 autoresolve 행 동일 검증은 재실행하지 않았다(다른 세션 측정 중).

## 3. 항목별 검토

### 3.1 qualifying 상한 (`salvo.gd:354-356, 385-402`)
- 상한 반복 대상은 `platforms()`와 같은 집합(stages 키 + equip 조건)이고 effective 0 필터만 뺀 상위집합이라 `max p.range ≤ r`이다. stages에 있으나 effective 0인 함종은 상한만 키우고 판정은 뒤의 `_any_qualifies`/원 루프가 그대로 한다.
- 지형: `range_mul`은 맞은 구역의 `range_bp/BP`를 구역 순서로 곱한다(`terrain.gd:64-69`). 상한은 모든 구역의 `max(1, ·)` 곱. 모든 인자가 양수이면 IEEE 곱이 각 인자에 단조라 `p.range*rmul ≤ r*m`이다. 구역은 호출마다 `terr.zones`를 새로 읽으므로 런타임에 구역이 추가·삭제돼도(`stratagem.gd:243,305`) 낡지 않는다. `terr == null`이면 m 곱 없음, rmul = 1.0이라 동치.
- 데이터에 `range_bp > 10000`이 있어도 `max(1,·)`로 처리된다. 현 데이터 최대는 9000.
- `cap` 기본값 -1.0 센티널은 `_range_cap`이 항상 0 이상이라 충돌 없음. `_pick_target`이 캐시한 cap은 한 루프 안에서 zones·stages가 안 바뀌어 유효.
- `dist`는 원래와 같은 `f.pos.distance_to(aim)`(같은 float32 Vector2 경로).

### 3.2 `_any_qualifies` (`salvo.gd:368-379`)
- 사거리 `dist <= float(range) * rmul`, 사격각 `off <= maxf(0, arc + adelta) * 0.5 + 0.001`은 원 루프 식과 문자 단위로 같다(`float()` 변환 포함). 장비 경로는 `platforms()`의 `f.equip == eq`(eq는 `equipment.keys()` 원소)를 `w.equipment.has(f.equip)`로 바꾼 것이라 동치. 참/거짓만 쓰므로 반복 순서 무관, 부작용 없음(`effective_of`, `range_mul`, `arc_delta` 모두 순수).
- 줄 잇기 `\` 뒤 탭은 GDScript에서 통과한다(테스트로 확인).

### 3.3 `_pick_target`·`sight_foe` 접촉 조회 합치기
- `sees`: `t != null and not t.dead and (detect == null or can_target)`. `can_target`은 state가 `confirmed`/`estimated`. 새 코드는 `o.dead` 검사 + 같은 두 문자열 비교. `lost`·빈 state·기록 없음은 모두 건너뛴다. `detect == null`은 `_pick_target`에서 aim = o.pos, 접촉 조회 생략으로 원래와 같다. `sight_foe`는 detect null이면 함수 앞머리에서 이미 분기.
- 조준점: 원래 `aim_pos`는 기록이 비었거나 confirmed면 `t.pos`, 아니면 `r.pos`. can_target 통과 시 기록은 항상 있고(`detection.gd:149`의 nr에 pos 포함) 같은 결과. `known_pos`도 같다.
- 검사 순서: 원래 dead/side → sees → truce, 새 코드 dead/side → 접촉 → truce로 순서 동일. `truce`는 순수(`stratagem.gd:86`). 따라서 순서 문제 없음.
- `d >= bd` 이후 `d > cap` 컷은 `qualifying`이 빈 배열일 때와 같고, `bd` 갱신은 원래도 q가 비어 있지 않을 때만이라 동치.

### 3.4 `BattleState.by_id` 색인 (`battle_state.gd:58-68`)
- `fleets`에 추가하는 곳은 `battle_sim.gd:225`(`_spawn`) 하나. 제거(erase/remove)·교체(`st.fleets =`)·`f.id` 재대입(`battle_sim.gd:200` spawn 직후 append 전) 모두 core·scripts·hud·view·tests grep에서 없다(`view/` 쪽 `fleets`·`id`는 뷰모델 자체 배열). `BattleState` 복제·직렬화도 없다. 크기 비교로 추가는 감지된다.
- 중복 ID는 앞의 것 유지로 선형 탐색과 동일. 미존재 ID는 null.

### 3.5 supply 정렬 캐시 (`supply.gd:196-209`)
- `ammo_ratio_bp`는 `f.ammo`·`ammo_cap`만 읽는 순수 함수, 정렬 중 어떤 상태도 안 바뀐다. 키는 고유한 `f.id`. 비교기 구조(`_prior` → ratio → sup_since → id)는 그대로라 정렬 결과가 같다. `_prior`는 아직 비교마다 전 함대를 순회한다(지적 3).

## 4. 지적 사항

| # | 심각도 | file:line | 내용 | 권고 |
|---|---|---|---|---|
| 1 | 정보 | `salvo.gd:396-399` | 상한 증명은 모든 `range_bp ≥ 0`에 기댄다. 음수 `range_bp` 구역이 둘 이상이면 `rmul`이 양수로 1을 넘을 수 있는데 상한은 그 구역을 1로 쳐서 어긋난다. 현 데이터(8000~9000)와 stratagem 생성 구역에서는 불가능 | `_range_cap` 주석에 "range_bp ≥ 0 전제" 한 줄. 지금은 수정 불필요 |
| 2 | 정보 | `battle_state.gd:58-68` | 색인 무효화는 `fleets.size()`만 본다. 같은 크기로 원소를 바꾸는 경우(교체·`f.id` 변경)는 잡지 못한다. 현재 코드에는 그런 경로가 없다. 새 테스트가 `st.fleets`를 직접 바꾸면 조용히 틀린 결과가 난다 | 주석에 "추가 전용 전제" 명기는 이미 있음. 직접 조작이 생기면 `_idx_n = -1`로 무효화 |
| 3 | 낮음(성능) | `supply.gd:199-209` | 캐시 후에도 비교기가 `_prior(a)`, `_prior(b)`를 매 비교마다 부르고 각각 전 함대를 순회한다(O(n log n × n)). 손님이 많으면 틱 평균에 남는 항목일 수 있다 | `ratio`처럼 `_prior`도 정렬 전에 한 번씩 계산해 사전에 둔다(`sup_first`·`sup_hold`는 정렬 중 불변) |
| 4 | 정보(성능) | `battle_state.gd:61-67` | 색인은 스폰마다 한 번 재구축(O(n))이며 매 틱 재구축은 일어나지 않는다. 문제 없음 | — |
| 5 | 정보 | `salvo.gd:410-419` | `_pick_target`의 `cur`(현 표적) 경로는 `qualifying(f, cat, cur)`로 cap 캐시 없이 `_range_cap`을 한 번 더 계산한다. 비용은 작다 | 필요 시 cap을 먼저 계산해 공유 |

## 5. 결론
- 동치가 깨지는 반례는 찾지 못했다. 이론상 한계 1건은 지적 1.
- 놓친 큰 성능 위험 없음. 남은 후보는 지적 3.
- 보류 조건 없음. 비트 동치의 최종 근거는 구현 세션의 autoresolve 행 동일 검증(시드 0~2 × none·attack)이고, 이 리뷰는 그것을 코드 논증으로 뒷받침한다.
