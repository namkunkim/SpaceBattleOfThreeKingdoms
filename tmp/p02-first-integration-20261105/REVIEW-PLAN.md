# P02 첫 실제 소비자 연결 — 독립 계획 심사

2026-11-05 KST. 판정: **범위 선택 수용, 구현 전 아래 R1~R4 계약 보완 후 재심**. 구현 착수 수용이나 최종5b가 아니다. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED를 유지한다.

대상 PLAN.md SHA256은 `f4e87fccb6bcc6140e0682d36b268708083469db5f654fa92780b773f4210c4c`다. 심사자 `/root/independent_review`는 계획·구현에 참여하지 않았다. 조율자는 심사 모델 `gpt-6-astra`를 명시해 spawn했다고 전달했으나, 이 심사자는 실제 실행 모델을 입증하는 별도 runtime/session 메타를 직접 확인하지 못했다. 요청 모델과 실제 모델 확인을 혼동하지 않는다. 이번 작성은 이 파일만이며 생산 코드·검사·상위문서·HTML·Git을 변경하거나 Godot을 실행하지 않았다.

## 수용할 범위와 근거

플레이북·CLAUDE, SESSION-HANDOFF, 통합 요구 §6 P02~P09/§8, 상위 CHECKLIST, 활성교체 RESULT/REVIEW/CHECKLIST/HANDOFF와 계획/계획수용, P2c 결과/리뷰/인계/closeout, I01 입력·readiness K01~08/S01~15, H2, D04의 상태·원자성 계약을 대조했다. C:/와 C:/WorkSpace의 부모 AGENTS 및 저장소 재귀 검색에서 적용 AGENTS를 발견하지 못했다.

실제 소스를 읽은 결과, FleetBattle3D는 sim 외 UI/clock/selection/camera/trace 바인딩과 실패 전 기존 표시 정리를 수행한다. AutoResolver는 적벽 모듈·작업 스레드·BattleOutcome에 의존한다. 따라서 이 둘을 이번 좁은 동기 owner에 즉시 연결하지 않는 판단은 적절하다. `tests/autoresolve.gd`는 기존 명령행 통계 도구이며 실제 `_run` 분기부터 명시 입력을 읽고 정책→queue→step→drain→결과까지 실행하면 첫 실제 headless 소비자라고 한정할 수 있다. 별도 테스트만 owner를 소비하는 이전 성과와 구별된다.

stock POC의 reinf나 적벽 모듈을 런타임에서 몰래 지우지 않고 명시된 제한 profile만 받는 선택을 수용한다. I01a의 합성 기하 결과를 runtime profile로 승격하지 않고 identity/no-transform 입력 표현을 별도로 명명한 것도 타당하다. 이것은 전체 I01/K02 공간 변환의 완료가 아니다. `attack5`는 허용 명령 subset이며 `charge30` 선행 거부가 필요하다. 정책 입력은 `read_projection(0)`이어야 하며 비공개 `observe().fleets`나 `_sim`로 대체할 수 없다.

기존 play/play_rc/정책/요약통계 본문을 보존하고 기존 CLI 한 run의 실제 baseline 비교, 신규 raw BattleSim 독립 oracle, P2c/core 최소 회귀를 사용하는 검증 규모를 수용한다. 기존 검사·allowlist/skip을 완화하지 않는다. 추가 read API가 기존 private capture의 코드 SHA에 포함되므로 이전 packet과의 호환을 새로 주장하지 않으며, 기존 restore 구현의 보존은 별도로 대조한다.

## 구현 전 보완 — R1~R4

**R1. JSON→정수 검증의 경계와 순서를 고정한다.** 현재 “범위검증 뒤 int”만으로는 `max_ticks`, fleet 정수, composition.count의 상한과 overflow 동작이 정해지지 않았다. 최상위 Dictionary/정확 필드, profile·roster·composition 컨테이너의 타입을 인덱싱 전에 확인하고, bool/비유한/분수/변환가능 범위 밖을 명시 거부해야 한다. seed uint32·hz10 외 정수의 허용 상한을 정하고 JSON float→int의 안전 범위를 넘는 값(예: 1e30)을 실제 반례로 포함한다. 제품 수치 상한을 발명하기보다 이번 표현이 안전하게 전달 가능한 정수 범위의 기술 제한으로 기록할 수 있다. 작은 수 정상화와 1.5 거부만으로 overflow 경계를 검증했다고 하지 않는다.

**R2. 출력 파일의 보존·실패 결과를 구체화한다.** “새 경로에 한 번 게시”는 기존 경로를 명시 거부하는지, 임시파일 후 교체인지 불명확하다. 이 작은 조각에는 기존 out 존재 시 사전 거부하는 no-clobber 정책도 충분하다. 선택한 정책과 open/write/flush 실패 확인·exit를 명시하고, 출력 실패를 성공 summary/PASS로 표시하지 않는다. 이미 존재하는 out의 sentinel SHA 보존과 열 수 없는 출력 경로를 반례로 포함한다. 입력/실행 실패 외에 파일 쓰기를 시작한 뒤 실패를 어떻게 처리하는지 한계를 적는다. 지원하지 않는 OS 장애 복구 원자성까지 주장할 필요는 없다.

**R3. 새 public read API와 owner 수명을 닫는다.** factory 성공 이후 정상 완료·명령/관측 실패·출력 실패 각각에 close가 실행되는 책임을 적는다. 기존 close는 Salvo/Detection/Supply의 순환 sim 참조를 해제하므로 단순 지역변수 소멸과 같지 않다. `read_projection(side)`는 허용 side 타입/값을 호출 전에 검증하고 guard/깊은 사본 반환을 유지한다. 잘못된 side·closed/busy 읽기, 반환 projection/summary 변조 후 state·events·queue 불변, 거부 후 정상 호출 가능을 검사한다. 정책은 공개 projection만 사용하고 진단 summary/전체 관측을 입력으로 섞지 않는다. adapter가 별도 mutable owner를 중복 소유하지 않는 factory/handle 반환 관계도 명시한다.

**R4. 명명 분모와 실제 CLI 경로의 검사표를 고정한다.** 현재 “missing input/profile”, “malformed JSON/type”, “unknown mode/format/field” 등을 합친 18개는 정확 집계 단위가 불명확하다. 각 named case와 예상 code/path, API/실제 subprocess 어느 경로인지 1행씩 열거한다. R1~R3 추가 반례는 기존 18을 줄이거나 합쳐 숨기지 말고 별도 증가/부문 분모로 기록한다. CLI 플래그 존재하지만 인수 없음, conflicting legacy option, unknown option, parse 실패, 지원 밖 stock, 정상 두 profile, legacy baseline 비교가 실제 parser/파일 I/O 경로에서 도달하는지를 지정한다. 반환 `{ok:false}`를 만들었지만 CLI exit0/PASS를 남기는 구현을 통과시키지 않는다.

이 보완은 신규 제품 정책이나 지원 모듈 확장을 요구하지 않는다. 보완된 PLAN의 SHA와 정확한 검사표를 받은 뒤 재심한다. 수용 전 코드/fixture 생성·Godot 실행은 하지 않는다.

## 별도 확인: 2026-11-04 MD4 갱신

`tmp/i01b-checklist-confirmed-20261104/`의 before 원문4개·diff4개·validation·record-manifest와 현재 문서, 두 과거 closeout 원문을 독립 대조했다. 직접 바이트 SHA 재계산 결과는 다음과 같다.

- before.json의 기존3945경로: 누락0, 변경은 허용된 상위 CHECKLIST/통합 요구/P2c CHECKLIST/활성교체 CHECKLIST 정확히4개.
- 각 before 사본 SHA 및 현재 after SHA: 4개 모두 validation의 값과 일치.
- record-manifest18항: 누락/SHA 불일치0.
- 보호7개(helper·기존 test2개·HTML·ZIP2개·class cache): SHA 모두 일치.
- 원문 diff는 P01의 제한 계획 완료 및 두 구성요소의 기능/closeout 근거만 최신화한다. P02~P09 미완료, 전체 NOT_READY/UNCLASSIFIED, 오염 cache 이력·기존 종료진단·전체 diff-check exit2를 유지한다. 과거 ZIP에 최신 MD4를 소급 포함했다고 주장하지 않는다.

따라서 **이 MD4 갱신의 내용·보존은 별도 한정 수용**한다. 통합 문서 C01/C02는 최초 통합문서 작성/심사 이력이며 최신 MD4 심사가 당시 완료됐다는 뜻으로 확대하지 않는다. 이 심사 기록이 이번 별도 확인이다. 두 ZIP은 재해시했으나 내부 CRC를 이번에 다시 전량 검사한 것은 아니며, 내용 수치는 기존 독립 closeout 원문과 대조했다. Godot이나 Git 원격 검증을 새로 수행하지 않았다.

읽기 감사 첫 Python 호출은 기본 cp949 decoding 오류가 났고 UTF-8을 명시한 다음 호출로 재해시를 완료했다. 파일 변경이나 Godot runner attempt가 아니며 코드 K6에 합산하지 않는다.
