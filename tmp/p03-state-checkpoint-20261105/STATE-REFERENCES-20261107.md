# 상태 조사 원문 대조 보충

2026-11-07 KST. [상태 조사](STATE-AUDIT.md)와 [명령 조사](COMMAND-AUDIT.md)의 적용 범위다.

| I01 준비 목록 | 조사 연결과 아직 필요한 증거 |
|---|---|
| S01/S14 | ST01. 정의/시도 식별자·실효 manifest·source/effective 변환 원장을 구분한다. 현 private 제한 profile 복제가 전체 K02 변환 또는 canonical hash 계약은 아니다. |
| S02–S05 | ST02/ST18. tick/clock/seed/hz 및 ID·AI 타이머는 실제 초기화 결과를 기록한다. 독립 commit_seq와 next_command_seq/last_applied_seq, 예정/적용 원장과 commit 절단점은 미정이다. |
| S06–S08 | ST03/04/06. 순서 있는 편성과 초기 override, 손상·무기 실효 상태 및 timer remainder를 캡처한다. C0 기본값을 Cn에 다시 적용하면 미래 실행이 달라질 수 있다. |
| S09–S10 | ST05/07/11/13/14. 활성 인스턴스의 모듈별 mutable과 참조를 추적하고 비활성에 근거를 붙인다. 현재 owner의 reject 목록은 모듈별 복원 책임을 대신하지 않는다. |
| S11–S13 | ST08/09–18. C0 투사체/처리키 초기 비어 있음과 Cn 활동 중 보존을 분리한다. 제품 확장 슬롯의 deferred/미초기/활성을 구분하고 실제 종료·결산 ID와 외부 게시 위치를 따로 확인한다. |
| S15 | wall/mono·UI 알림·진단과 논리 실행을 분리한다. host TickClock accumulator의 화면 또는 진행 복귀 기준은 P02/운영 재개의 공동 계약이다. |

K01 명시 opt-in/legacy 분기, K02 실효 설정, K03/K04 canonical 직렬 표현·해시, K05 ID와 명령 seq, K06 C0, K07 Cn, K08 동일 규칙 재개가 전체 준비 분모다. K03의 후보 외부 정규 표현과 exact runtime Dictionary 키 타입·삽입순서는 각각의 비교 대상이다. A06의 seq1/2 반영, seq3 대기 또는 suffix, 활성 투사체 및 처리 키 반례를 보존한다. P03 선언 경보에 이 반례를 실행한 것으로 집계하지 않는다. [I01 readiness](../../docs/battle-core/pc-campaign-design/I01-READINESS-DECISION-20261026.md) · [H2](../../docs/battle-core/pc-campaign-design/H2-DECISION.md)

P2b가 검증한 contacts/sup_* slice는 P2c fresh prepare의 위임 구간이다. 제한 private owner의 생성→비대상 복원→P2b slice→exact/bindings 검증 뒤 후보 반환과, 이후 활성교체의 동일-context 후보 준비→이전→old module.sim retire를 구분한다. 활성 실패에서 기존 sim/packet이 보존된 과거 증거는 실제 UI·worker·외부 효과 게시의 보존 증거로 쓰지 않는다. [P2b 결과](../../docs/battle-core/pc-campaign-design/I01B-P2B-RESULT-20261031.md) · [P2c 결과](../../docs/battle-core/pc-campaign-design/I01B-P2C-RESULT-20261101.md) · [활성교체 심사](../../docs/battle-core/pc-campaign-design/REVIEW-I01B-ACTIVE-REPLACE-20261104.md)

P02 CLI 진입/옵션 검증은 `tests/autoresolve.gd:33,75,136`이고 policy가 읽는 공개 투영은 99행부터다. `core/battle/operation_private_state.gd:240,246`은 추가된 읽기 표면이다. 현재 소스 관측 SHA와 비Astra 최종 마감 수용 기록을 분리한다. P02 전체와 UI/worker/replay 및 supply 완료 사건 E2E는 여전히 미완료다. [P02 비Astra 독립 마감](../p02-first-integration-20261105/REVIEW-CLOSEOUT-NON-ASTRA-20261107.md)

저장소의 외부 .gd 검색은 [파일 목록 stdout](scope-observation-20261107/1-stdout.bin)과 [생성·시계·replay·preload 후보](scope-observation-20261107/5-stdout.bin)로 남긴다. 도구의 .gitignore 기본 적용 및 tmp/.godot 제외 조건에 해당한다. 182개 목록과 검색 hit 92행은 문장 검색 관측치이며 활성 모듈 분모가 아니다. 동적 로드·문자열 조립·비 GDScript/리소스 및 실제 소비 순서 전체는 미분류다.
