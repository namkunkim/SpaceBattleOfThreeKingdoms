# P02 첫 실제 소비자 연결 — v2 독립 계획 수용

2026-11-05 KST. 판정: **R1~R4 보완된 제한 계획 수용. 명시한 작은 구현과5a 착수 가능.** 구현·검사 통과 또는 최종5b 수용은 아직 아니다. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED를 유지한다.

심사 대상은 PLAN.md 26397 bytes / SHA256 `28e68d982c3e2241a97bdf9260948575625350fb332de4f57e457e081d045671`다. v1 원문 PLAN-v1.before.txt 14477 bytes / SHA256 `f4e87fccb6bcc6140e0682d36b268708083469db5f654fa92780b773f4210c4c` 및 첫 REVIEW-PLAN.md 8057 bytes / SHA256 `5800fca0391e3aae9af3805fc700a208d89552d7c24d5cbe633509142d05d085`를 읽기·재해시했고 변경하지 않았다. 이 재심은 첫 심사의 반려/MD4 확인 이력을 삭제하거나 덮어쓰지 않는다.

검토자 `/root/independent_review`는 계획 작성·구현에 참여하지 않았다. 조율자가 요청한 심사 모델은 gpt-6-astra이며 별도 실행 모델 메타를 이 재심에서 직접 확인한 것은 아니다. 생산 코드·검사·상위문서·HTML·Git 변경 및 Godot 실행 없이 이 새 판정 파일만 작성했다.

## R1~R4 해소 판단

**R1 수용.** 컨테이너 검증을 인덱싱보다 먼저 수행하고, 누락/추가 필드·definition/checkpoint 입력을 명시 거부한다. seed uint32, hz10, 나머지 정수의 signed32 기술 상한과 ships/lv/count의 양수 조건, composition 합산 전 overflow 검사를 정했다. bool/비유한/분수/상한 밖을 int 변환 전에 거부한다. huge 값과 합계 overflow 반례를 추가하고 최대 정수는 순수 정규화만 검사하여 거대 runtime을 만들지 않는다. 제품 편성 상한이나 전체 저장 스키마 확정으로 확대하지 않는다.

**R2 수용.** 신규 opt-in의 --out을 필수로 하고 기존 파일/디렉터리를 열지 않는 no-clobber 계약으로 좁혔다. parse·입력검증 후 경로확인, write 직전 재확인, open/store/flush/get_error/재읽기 바이트 SHA 확인, 성공 게시의 최종 순서를 명시했다. 실패한 신규 partial 파일은 보존·진단하며 자동 삭제나 덮어쓰기 재시도를 하지 않는다. check-open 사이 제3자 경합 및 디스크 장애의 원자 복구를 보장하지 않는 한계도 적절하다. sentinel 보존·없는 부모·Windows 금지 leaf의 실제 CLI 반례가 있고, 실제 재현 실패를 PASS로 바꾸지 않는다.

**R3 수용.** adapter는 static factory이며 기존 private owner 하나만 반환한다. CLI가 성공/실패 모두 owner.close를 수행한 뒤 출력으로 이동하므로 출력 실패 때는 이미 owner가 닫혀 있다. read_projection의 Variant 인자·guard 선행·INT side0/1 검증, summary guard, 깊은 사본, 비소비 읽기와 alias 반례, 모듈 sim 참조 해제 검사가 명확하다. 정상 오류 반환의 정리 계약이며 runtime script 예외 복구 보장은 아니다. 정책은 공개 projection만 읽는다.

**R4 수용.** 표의 실제 ID를 추출하여 N18+X12+Y6+Z10=46개이며 중복0임을 확인했다. 각 expected error/path 및 API/실제 CLI 경로가 구분된다. API32/CLI14와 정상8, CLI 성공2 및 legacy before/after1쌍을 별도 분모로 기록한다. CLI 성공/거부/legacy 비교는 17논리항목·18실제프로세스이며 main API runner1와 회귀2는 별도다. 실제 parser를 통과하는 누락 인수·충돌·unknown/duplicate option·JSON/file 오류·stock profile·charge30·출력 오류를 포함한다.

## 구현에 적용할 반환 계약 해석

v2의 “성공메타는 norm profile이나 raw sim을 노출하지 않는다”는 **factory의 성공 반환 metadata**에 적용한다. 말미에서 명시적으로 허용한 pure validate/normalize는 정규화 결과를 검사하기 위해 별도의 detached 값 결과를 반환할 수 있다. 순수 결과에는 live owner/raw sim이 없어야 하고 호출자 원본과 alias를 공유하지 않는다. factory는 같은 순수 정규화 경로를 한 번 거쳐 Private.create에 전달하며, 메타에 normalized profile을 다시 싣거나 두 번째로 정규화하지 않는다. 이 구분은 두 문장을 함께 충족하므로 구현차단 모순으로 보지 않는다.

이 해석으로 pure 경계검사와 factory 실패/게시 검사는 다른 책임이다. 순수 정규화 성공만으로 Private.create 성공이나 실제 실행 readiness를 주장하지 않는다. factory의 생성 실패는 owner 없는 명시 오류이며 기존 활성 owner를 닫거나 바꾸지 않는다.

## 수용 범위·최종5b 기준

이번 수용은 기존 `tests/autoresolve.gd`의 실제 명령행 분기에서 명시된 제한 fresh 입력을 받아 공통 factory→private owner→공개 projection 정책→queue/advance/drain→결과로 연결하는 첫 headless 조각에만 해당한다. stock POC 전체 또는 적벽 모듈을 임의 제거해 성공시키지 않는다. UI host·AutoResolver 스레드·BattleSim.replay까지 연결했다고 표현할 수 없다. I01a 합성 기하 결과, 운영 checkpoint·global cursor·외부 save schema도 지원하지 않는다.

허용 생산 변경은 신규 adapter, private owner의 최소 public read 두 메서드, autoresolve의 명시 분기와 전용 helper다. 기존 play/play_rc/정책/통계 본문과 기존 private restore/context/codec, 데이터·기존 검사·allowlist/skip을 보존한다. 신규 parser 없는 legacy 기본 실행은 보존 source와 실제 결과를 비교한다. 원문 OUT-only 복사와 역치환 SHA, 정본 cache/resource_path, 실패/성공 입력·로그·actual exit, 기존3960/source35/격리77·HTML·ZIP 보존을 유지한다.

최소 회귀 P2c/core 및 active_replace source 연속성 검토는 현재 계획의 작은 read 추가 범위에 적절하다. 구현에서 추가 의존성이나 회귀 우려가 생기면 그 근거에 따라 필요한 검증을 보강한다. 기존 종료진단·전체 diff-check exit2를 전체 PASS로 바꾸지 않는다. 코드 K6의 새 단계와 과거 attempt 이력을 구분하고 usage-limit이면 즉시 보고·반복 중지한다.

최종5b는 실제 source/diff·정규화 반례·8정상 독립 oracle·46명명 완결·18실제 CLI 프로세스·public 정보/alias·close/lifecycle·legacy 비교·최소 회귀·로그와 SHA 보존을 대조해야 한다. Z10이나 다른 반례가 환경에서 재현되지 않으면 계획대로 미실행을 보고하고 계약 변경을 재심받는다. 이 계획 수용만으로 미실행 항목을 통과 처리하지 않는다. 최종5b 뒤 결과/체크리스트/인계·manifest/ZIP 및 별도 closeout이 남는다.
