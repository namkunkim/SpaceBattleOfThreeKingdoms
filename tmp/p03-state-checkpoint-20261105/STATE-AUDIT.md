# P03 C0/Cn 상태 책임 조사

2026-11-07 KST. 읽기 조사. H2의 현재 상태와 후속 명령, 초기 동일 규칙 버전, 논리 재생과 관람 구분을 따른다. [D04 ST01~18](../../docs/battle-core/pc-campaign-design/D04-STATE.md), [I01 사전등록](../../docs/battle-core/pc-campaign-design/I01-ACCEPTANCE-PREREG-20261026.md) 및 [COMMAND-AUDIT](COMMAND-AUDIT.md)의 명령·커서 경계와 함께 읽는다. 아래 분류 중 제안은 전체 C0/Cn 계약 결정에 앞선 책임 후보이다. 전체 I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.

## 실제 경계

- **C0 후보**는 정본 source→effective 입력이 결정되고 seed/hz/profile/편성, 모듈과 참조, 초기 제어권을 붙인 다음 외부 게시 전의 상태다. `core/battle/battle_sim.gd:40`이 초기 sim을 조립하고 `operation_private_state.gd:142`가 제한 프로필 검증 및 detached 복사 후 이를 호출한다. `[]`는 초기 컨트롤 override가 없음을 뜻한다. 명시 delegate 배열은 실제 override다. 실효 입력 생성, 호스트 준비/발행, 전체 ST 계약까지 포함하는 C0는 미확정이다.
- **Cn 후보**는 같은 owner 안의 바깥 step 완료/즉시 명령 완료 이후, 전투·명령·대기·사건·소비자 위치가 합의된 절단점이다. `battle_sim.gd:172,923,949`의 바깥 step과 substep은 `BattleState.tick`, `clock_ms`, `BattleSim.sub_ms`의 뜻이 다르다. 종료가 substep 중 일어날 수 있어 tick×100으로 시간을 복원하면 안 된다. `operation_private_state.gd:165,275,306,344,367`에는 ready/busy, 메모리 packet, 새 후보 준비, 동일 context 활성 교체가 있다. 실제 host/worker drain·게시와 전역 커밋에 관한 계약은 후속이다.
- `operation_private_state.gd:10–16,35–60,367–460`의 allowlist·property coverage와 수동 복원은 제한 범위의 사실이다. P2c fresh 70/11553/45와 활성 교체 20/20099(명명 8, 호출 9)는 해당 범위의 기존 수용 이력이다. `operation_service_state.gd`의 정확 비교와 동일 context 제한을 참고한다. exact Variant type/value, Dictionary 키 타입과 삽입 순서, Array 순서, typed builtin/class/script identity가 실제 재개 비교 분모다. 문자열화·키 정렬·수치 정규화로 대체하면 안 된다.

## 선언·갱신·소비와 책임

경로는 `core/battle/` 기준이며 외부 경로는 별도 표시한다. 각 행의 위치는 대표 경로이며 필드별 동적 key 및 모든 소비자까지 확인한 목록은 미완료다. 현재 raw 선언 전수는 [oracle-20261107](oracle-20261107.json)에 별도 보관한다.

| ST | 현재 출처와 흐름 | 책임 후보와 남은 증명 |
|---|---|---|
| 01 | `rule_set.gd:8–20,54` rules/scenario/combat/Vector2 world. `battle_sim.gd:40` 조립 후 각 모듈 참조. `battle_rng.gd:9–29` profile ID와 tick/event/sub 기반 난수 | 적용 정의·seed/hz·모듈 구성과 코드/내용 근거 capture. RuleSet/rng 재구성 후 참조 일치. 같은 ID의 다른 내용 및 실효 지형/입력 hash, 기능 미구현과 비활성 분리 필요 |
| 02 | `battle_state.gd:28–65` tick/clock·ID·사건 카운터와 상태 배열. `battle_sim.gd:172,214,923,949` 진행·발급·종료. `tick_clock.gd:11–32` host speed/acc/dropped | 논리 카운터와 sub_ms capture, host accumulator·pause·dropped의 저장 또는 재시작 정책은 미정. projectile과 fleet ID namespace 및 commit seq 구분 |
| 03 | `fleet_state.gd`의 comp0/stages/hull/loss/ships와 stat dictionaries. `salvo.gd:26,230–257` 초기화·소비. `battle_sim.gd:264–308` 손상/손실·제거 | 순서와 숫자 타입을 가진 손상/손실 capture. 기존 편성·생성 ID를 재결합하고 파괴함 부활 금지. 손실률 환산은 동등성 근거 없음 |
| 04 | `fleet_state.gd` ammo/energy/heat/remainders/next_fire와 cooldown·반격 예약. `salvo.gd:26,257,282` 장착/유효 플랫폼, `battle_sim.gd:320,336,832,875,991` 발사·타이머. `supply.gd:245` 자원 증가 | 기존 수치와 시간 단위 capture. 허용 범주·정확 key order와 자원 상하한을 검사. 다음 사격 초기화나 보급 재실행 금지 |
| 05 | `morale.gd:11–20,41,70,110,138,161,185` 결집 횟수·비용·위기/역병/퇴각. `victory.gd:43–79,120` 소비 | fleet과 module mutable 별도 capture 후보. 생성 분모와 config 참조 재결합. 제한 owner는 morale/victory 비활성만 지원 |
| 06 | `fleet_state.gd` Vector2 position/target/route, control/posture, transition·group·speed. `battle_sim.gd:460,889,991` 갱신, `salvo.gd:150–218` 전환과 shape | 순서 있는 경유지와 진행 중 전환 capture. 대상 ID 재결합. 시각 캐시 제거와 논리 캐시 재계산은 별도 오라클 필요 |
| 07 | `command.gd:19–22,55–103` 승계·통계. `skills.gd:24–27,313,365,388,405` 진영 효과, 사용 횟수, 투영·만료. `assault.gd:13–15,86,139` 상태·피해. `stratagem.gd:15–35,168,280,385,488` 화재·지형·시간창 | active effect와 사용 이력 capture, config/sim/terrain 참조 재결합. _views/통계도 미래 의존 또는 비교 포함 여부 확인. 현재 제한 복원에서는 활성 모듈 제외 |
| 08 | `battle_state.gd:6–26` Missile/Swarm 클래스. `battle_sim.gd:320,336,1172,1192` 생성·이동·소모. `operation_private_state.gd:405–459` 제한 검증과 개체 생성 | 순서/identity가 있는 projectile 목록 capture, source/target ID 재결합. Vector2 및 float 점 자료의 논리·표시 의존성 검증 후만 재계산 |
| 09–10 | `supply.gd:22,24,115,245,311` 기존 bases와 소스·공개 투영 | 연속 작전 거점 소유/가동/재점령·입출고·지급 원장은 아직 연결되지 않았다. 기존 bases 목록을 권위 거점·거래 원장으로 해석할 수 없다 |
| 11 | `supply.gd:16–22,115,158,245,324` sim/config·대상 소스·보급 진행과 완료. `fleet_state.gd`의 sup_* 및 healed_*에 진행·재고·위치가 유지. `operation_service_state.gd`가 제한 복원 위임을 받음 | 작업·재고·지출/완료를 함께 capture, source ID/후보 sim 재결합. bases/need/light_ticks/still_eps의 파생 동일성 필요. 외부 지급 원장과 drain은 별도 |
| 12 | `terrain.gd:9–15,42–72` zones 및 기동/센서/사거리. `stratagem.gd:168,280` 동적 지형 효과. `BattleState._idx` 캐시는 ID 검색 | 활성 지형 변경은 config에서 초기화할 수 없다. 동적 zone 순서·ID capture 후보. _idx/_idx_n은 private restore 457행 부근에서 무효화 후 다시 계산. 제품 항로/통제·유효경로 버전 미정 |
| 13 | `decisions.gd:10–17,53–81,118` cards/done, _seq/시간/반응. `ai/commander_ai.gd:13–17` 공개 입력·기억·통계. `battle_sim.gd:923` AI 주기 | 실행·만료·정책 상태 capture 후보. 공개 입력 복원 직후 다시 계산 가능한지 검증. 캠페인 임무·보고·재계획 원장은 별도 |
| 14 | `detection.gd:12–17,27–67,144–197` contacts/period/confidence/시야. `battle_sim.gd:385–449` 표적 조회·사건 필터. `battle_projection.gd` 공개 투영 | 접촉 dictionary의 진영/정수 ID/삽입순서·last seen·confidence 보존. sim/terrain 재결합과 period 재구성, 가시성 투영 재계산. 숨은 실제 위치로 기억 덮어쓰기 금지 |
| 15–16 | `battle_sim.gd:252,923` reinf 예약/생성, `battle_state.gd`의 reinf/reinf_ms. 제한 owner는 증원 프로필을 거부(`operation_private_state.gd:86,402` 부근) | Cn 전후 예약·출발·지연·생성·완료와 cargo/출고/수취 ID capture 후보. 단일 reinf 플래그로 다중 일정이나 호송 원장을 나타낼 수 없음 |
| 17 | `battle_sim.gd:1215` 전투 종료, `victory.gd:120,139–170` 조건·결과. `BattleState`의 over/win/result/end_tick/end_ms | 실제 종료 위치/결과 capture. 게시·결산 적용은 별도 결산 ID 및 중복 거부 정책 필요. 실제 제품 목표/철수/실패 동시 우선순위 계약 미정 |
| 18 | `battle_sim.gd:95–101,142–194,214,424` queue/issue/log/replay/emit/drain. `operation_private_state.gd:14,206–238,275` 제한 command, pending, 사건 | [COMMAND-AUDIT](COMMAND-AUDIT.md)의 접수/적용/완료/소비 구분. 이미 반영된 명령 재적용 금지. 미적용 pending과 suffix 절단점을 합의해야 한다. 복원된 _events는 외부 exactly-once 보장이 아니다 |

## 소비자와 P02 접점

| 소비자 | 현재 근거 | 함께 확정할 부분 |
|---|---|---|
| 실제 UI | `scripts/FleetBattle3D.gd:94–97,204–212` sim과 두 TickClock, 화면 G/vm | host ready/busy, 각 clock/선택/카메라/trace의 복원·유지·리셋 정책, 실패 시 현재 활성 전투 및 표시 유지, 게시 시점 |
| worker | `scripts/world/auto_resolver.gd:34` worker에서 직접 sim 생성 | 동일 스레드 단독 owner, 완료/close/join 후 DTO, 실패 시 소비·게시 전무. wrapper가 동기 공유 객체가 되면 안 됨 |
| headless | `core/battle/operation_runtime_adapter.gd:20,72` runtime-ready normalize/create. `tests/autoresolve.gd` opt-in consume. P02 인계와 5-b는 제한 fresh 연결만 수용 | P02가 실제 소비자·옵션 소유. P03은 capture 가능 경계, 적용 cursor와 pending, 사건 drain/게시·실패 원자성을 계약 후보로 전달할 수 있다. P02 마감 수용 여부는 해당 기록을 따른다 |
| replay | `battle_sim.gd:183`, `tests/battle_flow.gd:104` 초기 시드/프로필과 tick log 재생 | Cn 이후 suffix 소비 및 관람 trace와 별도. tick만으로 동일 틱 복수 issue, queue, 종료 substep 및 사건 수신자를 구분할 수 없다 |

`bundle_layout.gd:12–14` 정적 _layout/_layout_loaded/_layout_valid와 `poc_setup.gd:9` _cache는 소유자가 개별 owner 밖에 있다. 선언 목록에 포함하되 값·외부 데이터·초기화 타이밍과 mutable 공유 여부는 별도 검증한다. `SalvoCombat.C`, `SupplyCore.S`, `Detection.D`, RuleSet 하위 Dictionary의 공유/복제 관계도 키와 값 동등성만으로 확인할 수 없다. 생성 코드·동적 Dictionary key·상수의 새 입력·core 밖의 host 및 preload·Resource에서 새 상태가 생겨도 31개 선언 목록만으로 그 의미를 분류할 수 없다. 선언 없는 파일도 현재 재고에 포함하고, 외부 경로 검색은 미분류 근거로 보존한다. 모든 runtime 필드/참조에 대한 capture·rebuild·rebind·recompute·exclude 승인 원장 및 실제 suffix 검증은 후속이다.
