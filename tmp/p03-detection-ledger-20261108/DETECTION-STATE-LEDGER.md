# P03 Detection 상태 책임 원장

2026-11-08 KST. 읽기 조사. 적용 근거는 [동결 원문](input-manifest.json) 및 [계획](PLAN.md)이다. 경로는 아래에서 `core/battle/` 기준이다. D04 ST14의 접촉·마지막 위치·확인 수준·오차 책임을 현재 모듈에 대조한다. P02 최신 revision5는 제품 자동결산 독립 마감 중이었다. 공통 owner/필터의 쓰기 소유 이관은 확인하지 못했다. 조사 결과는 저장·보안 정책 결정이 아니다.

| 선언 | 소유/타입·수명과 경로 | 복원 책임과 현재 근거 |
|---|---|---|
| F01 `sim` | `Detection`의 `BattleSim` 참조. `detection.gd:12,19–20`에서 생성 owner를 붙이고 `55–67,85–96,144–195,206`에서 fleet/config/step/event 소비 | **재결합**. 새 sim 생성에서 `battle_sim.gd:73–76`이 새 Detection에 자기 참조를 준다. `operation_service_state.gd:100–102` identity 확인. 이전 sim 참조를 capture하지 않는다 |
| F02 `D` | 설정 `Dictionary`, `detection.gd:13,19–21`에서 `SalvoCombat.C.detection` 별칭. `69,76–121,175–194`의 sensor·EW·가시 거리·메모리·오차/신뢰 규칙에 사용 | **재구성+재결합**. `battle_sim.gd:55–76` 및 service `102,136–146`가 C 내부 참조 identity와 복제한 combat context를 확인한다. 관측 가능한 값 동일성과 런타임 alias 동일성을 따로 유지한다 |
| F03 `terr` | `BattleTerrain` 참조, `detection.gd:14,19–22`. 전장의 공통 지형이 없으면 독립 빈 지형 객체. `88,105`에서 sensor 보정·conceal 조회 | **재구성+재결합**. `battle_sim.gd:72–76`과 service `103–105,144`에서 공통 terrain identity 또는 빈 fallback zones 검사. 활성 계략의 동적 지형까지 복원한다고 해석하지 않는다 |
| F04 `contacts` | 바깥 `Array`에 진영별 `Dictionary` 2개. `detection.gd:15,151–195,197–203`에서 int target ID로 기록을 생성/교체/삭제. `27–67`의 query와 관측/사격/AI가 읽음 | **capture+복원**. service `12–41,167–178`는 deep-copy, 대상 ID/필드 검사, 새 후보에 재할당. 동일 값·순서와 객체 alias를 분리. restore 중 평가를 다시 하지 않는다 |
| F05 `_period` | int 평가 간격(논리 tick), `detection.gd:16,23`에서 `maxi(1,ticks(eval_period_s,hz))`. `144–149`가 `(tick-1)%_period`에 맞춰 두 진영 평가 | **파생 재계산**. service `106–109,144`에서 새 sim의 period를 계산 규칙과 context에 대조한다. 평가 phase는 같은 `st.tick`을 필요로 하며 별도 wall clock을 읽지 않는다 |
| F06 `_conf0` | int 추정 시작 신뢰도(bp), `detection.gd:17,24`에서 fog override 또는 `D.confidence_bp`. `187–190`에서 estimated 보정 | **파생 재계산**. service `106–109,144`에서 같은 override와 기본 설정으로 계산한 값을 검증한다. 과거 개별 record의 conf_bp는 재계산하지 않고 F04에 포함 |

## 동적 records

side는 내부 [0,1] 순서다. int target ID는 sim의 fleet ID 공간이며 release 가능한 객체 참조가 아니다. `_eval`은 st.fleets 순으로 순회하며 자기편 또는 `max_hull==0`을 건너뛴다. dead는 다음 평가에서 삭제된다. 관측이 발생하면 seen/pos를 새로 설정하고, 관측이 끊기면 기존 seen/pos를 유지하며 estimated→lost→삭제로 바꾼다. `_store`는 기존 위치에 값 갱신 또는 erase, 이후 다시 들어오면 새로운 삽입 순서다. `detection.gd:151–206`

| 필드 | 현재 타입·출처·소비 | 보존/거부 근거 |
|---|---|---|
| R01 `seen` | int 마지막 관측 tick. `detection.gd:174–184`에서 현재 tick으로 갱신하거나 이전 값 유지. age 계산·상태 전이 및 `battle_fingerprint.gd:49` | service `175`는 0 이상/target tick 이하. 현재 tick으로 덮어쓰면 memory/lost 타이밍 변경 |
| R02 `pos` | Vector2 마지막 관측 좌표. `detection.gd:176–184`가 관측 시 t.pos를 읽고 미탐지에는 보존. 추정 조준·접촉 투영·이벤트가 사용(`39–46,55–67,206`) | service `77–93,176`의 finite·type 검사를 거친 copy. confirmed 조준 시 실제 위치와 record에 저장된 평가 위치는 목적이 다름 |
| R03 `state` | String confirmed/estimated/lost. `detection.gd:185–194` 전이. `can_target:34–36`은 confirmed/estimated, `foes:55–67`는 살아 있는 lost도 목록에 포함 | service `177` whitelist. record 부재는 빈 string 조회이며 삭제 후의 공개 이벤트 값 none과 별도. key 존재만으로 사격 유효라고 가정하지 않음 |
| R04 `conf_bp` | int 신뢰도 bp. `detection.gd:184–192`의 confirmed BP/estimated 감소 및 하한/lost 기본 0. `salvo.gd:359` 명중 배율, projection 및 fingerprint 소비 | service `178` 0..BP. 현재 검증에서 상태별 수치 조합을 별도 검사하는 분기나 record의 생성 가능성을 보증하는 테스트는 이 조사에서 확인하지 않음 |
| R05 `err_r` | float 오차 반경. `detection.gd:184–188`에서 규칙과 age에 따른 증가, confirmed 0.0. `detection.gd:44–46` 및 `salvo.gd:463–467` 추정 조준 허용 | service `77–93,176`에서 finite와 float·비음수 확인. `battle_fingerprint.gd:45–49`의 요약에는 없는 필드이므로 지문으로 원장 전체 대조 불가 |

기존 service 검증은 두 side 배열, 정수 ID 및 대상 roster의 존재를 확인한다. 검사 코드에는 그 ID가 해당 진영의 적인지, 상태와 confidence/error의 모든 생성 규칙이 일관되는지까지 판정하는 분기가 없다. 예를 들어 source에서 가능한 후보는 **존재하는 자기편 ID를 side book에 넣은 packet**이다. 현 코드의 검증 범위 관측이며 실제 수용 여부나 제품 거부 요구는 별도 fixture/계약 심사 대상이다. `operation_service_state.gd:148–178`

## 갱신·소비 교차점

- 평가 호출은 `battle_sim.gd:949–971`에서 salvo의 첫 하위걸음에 있고, `detection.gd:144–149`가 외부 tick의 주기를 한 번 더 거른다. 탐지 점수는 함종/장비·진형·지형·거리/은폐와 지원 모듈을 읽는다. `detection.gd:73–141`. 직전 fleet/terrain이 복원되지 않은 상태로 contacts만 넣어도 전체 재현이라고 할 수 없다.
- `rec:27–28`은 내부 record를 직접 반환한다. 이 경로 자체는 detached DTO가 아니다. 현재 대표 읽기 소비는 `battle_sim.gd:385–420,778`의 가시/명령/거리 및 `salvo.gd:359,463–502`의 명중/조준/타깃이다. 이 소비 경로에서 모든 caller의 alias 사용을 증명하지 않았다. service packet은 deep-copy로 다른 경계를 갖는다.
- `foes:55–67`는 ID 정렬 및 dead 제거, `battle_projection.gd:42–44,105–141`는 이를 공개 접촉으로 축소한다. `ai/commander_ai.gd:73,262`는 접촉 키·값을 직접 읽고 `ai/poc_enemy_ai.gd:15`는 foes를 읽는다. 표시 정렬, AI/코어 소비 순서, 원 book 삽입순서는 각각 별도다.
- `_store:197–206`의 side0 상태 전이는 contact 사건을 enqueue한다. `battle_sim.gd:424–448`의 필터는 contact에서 side1을 제외하고 side0은 일반 마스킹 분기에 넣지 않는다. 이것은 `BattleProjection`의 sqs 공개 계약과 다른 표면이다.

## 후속 독립 반례

1. **정렬과 exactness.** 여러 실제 접촉 ID를 역순으로 삽입한 후보와 원본의 raw key order를 대조한다. `foes`/fingerprint는 ID 정렬이고 fingerprint는 err_r도 생략한다. 화면/지문 일치가 raw 상태와 모든 소비의 동등성을 증명하는지 별도로 반증한다. 현재는 소스 경로만 확인했다.
2. **기억과 상태.** 평가를 건너뛰는 tick과 재평가 tick, confirmed→estimated→lost를 지나며 현재 적 좌표와 last seen 좌표가 다른 fixture를 분리한다. restore 직후 현재 좌표로 기억을 갱신하면 source/target 사격·공개 투영이 달라질 수 있다. lost는 표시 항목이나 key가 남아도 `can_target=false`다. 기존 활성교체의 estimated 관측을 lost/만료 전체 검증으로 집계하지 않는다.
3. **제거 사건 위치 가설.** 메모리 만료 또는 dead 평가에서 `nr={}`가 `_store`로 전달된다. side0의 was→none일 때 position fallback은 이전 last known이 아니라 해당 평가의 `t.pos`다. side0 표시용 drain의 contact 특례는 이 payload에 일반 마스킹을 하지 않는다. 현재 좌표와 마지막 공개 좌표를 분리한 실제 사례로 raw/filtered event·projection을 모두 대조해야 한다. **실제 정보 노출이나 제품 정책 위반 여부는 아직 미검증**이며 D05는 임무/추격의 제한 정보 방향과 별도의 공개 계약을 요구한다.

P2b는 contacts의 부분 인메모리 capture/restore이며 caller가 필요한 대상 상태를 먼저 맞춘다. P2c는 새 제한 owner를 준비하고 비대상 state를 복원한 뒤 이 slice를 위임한다. `operation_private_state.gd:272–294,316–334,465–469`에 근거한다. 이 책임표에서 전체 ST14의 UI/알림 정책, 지원 밖 모듈, 객체형 packet metadata 및 저장 스키마를 확정하지 않는다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. [P2b](../../docs/battle-core/pc-campaign-design/I01B-P2B-RESULT-20261031.md) · [P2c](../../docs/battle-core/pc-campaign-design/I01B-P2C-RESULT-20261101.md) · [D04](../../docs/battle-core/pc-campaign-design/D04-STATE.md) · [D05](../../docs/battle-core/pc-campaign-design/D05-MISSIONS.md)
