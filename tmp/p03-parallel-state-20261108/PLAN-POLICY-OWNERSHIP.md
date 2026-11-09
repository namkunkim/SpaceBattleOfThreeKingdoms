# P03 운영 정책·소유권 35셀 대조 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 목적은 [운영 경계표](boundary-closure/boundary-matrix.json)에서 POLICY_REQUIRED 24개와 UNCLASSIFIED 11개를 모두 대조하고, 남은 인수 중 어떤 것이 이미 결정됐고 어떤 것이 제품 선택이나 소유권 합의에 달렸는지 분리하는 것이다. 결과에 따라 정책을 채택하거나 생산 경로를 수정하지 않는다. 독립 계획 수용 전 원장/검사기 구현과 실행은 보류한다.

## 입력 분모와 대조 순서

- 기준 경계표 SHA256 9e18e4604e0b369496ae21bdfaca14956e7555900698b5ee0d843b14319c8b1f. 원본은 편집하지 않는다. 행 ID와 책임 열의 튜플을 고유 키로 삼는다. 정책 24개는 12행 각각의 effect_delivery 및 durable_cursor다. 미분류 11개는 B0_PARTIAL·C0_POST_PUBLISH의 owner_host 2개와 ISSUE_RETURN, QUEUE_RETURN, STEP_IN_PROGRESS, STEP_RETURN, TERMINAL_RETURN, PRE_DRAIN, POST_RAW_DRAIN, POST_FILTERED_DRAIN, BUSY_OR_CLOSED의 ui_publish 9개다. raw/filtered는 같은 미소비 큐의 대안적 소비 경로다.
- 수용 후 조회 직전에 기준 경계표·사후 5b·정본 D04/D10/K05–K07/A06/O07 및 관련 결정/인계, P02 진행표와 worker/replay/viewer/host-prep/prep-error/legacy 결과, 최신 독립 P02 closeout 및 미완 기록의 경로와 SHA를 목록으로 고정한다. P03 owner-operational, Detection UI, Supply 혼합, cursor/drain, combined-cut의 최신 독립 근거도 동일하게 고정한다. 현재 확인된 P02 후보는 sixth/seventh 독립 closeout과 eighth 미완 인계다. 그 뒤 읽을 수 있는 확정 근거가 있으면 결과 표에서 어떤 기록이 기존 근거를 대체했는지 명시하며 미완·중단을 완료로 올리지 않는다.
- 정본 문구가 권고·후보·명시 합의 중 어디인지 표기하고, 런타임 관측은 해당 fixture/정적 경로/미실행을 구분한다. 소유권은 `현재 호출/변경 소유`, `미래 계약 제안 소유`, `공동 인수 대상`을 별도 기입한다. 생산 코드 조회 범위는 owner·코어 sim, operation adapter/replay, raw 3D host·viewer bridge, WorldLink 및 결산/표시 연결 중 정본이 가리키는 실제 경로로 제한한다. 동시 P02 변경을 발견하면 해시와 범위를 별도 기록한다. 공유 파일을 수정하지 않는다.

## 원장 산출물과 실제 선택지

35개 각 행에 `기준 disposition`, `확정 결정`, `추가 조사`, `사용자 제품 선택`, `소유 합의`를 독립 필드로 넣는다. 해당 없음은 사유와 함께 명시한다. 같은 셀에서 현재 제한 정책이 결정됐어도 운영 정책이 남으면 각각 기록한다. 선택이 필요한 행은 결정 패키지 ID, 최소 두 가지 상호 배타적 대안, 각 대안의 UI/운영·복구·검증 영향, 선행 작업, 결정 주체, 다음 acceptance를 연결한다. 증거가 부족한 셀에는 가짜 선택지를 만들지 않고 먼저 판정에 필요한 관측을 적는다.

조사할 실제 대안의 범위는 다음과 같다. 현재 채택안으로 간주하지 않는다.

| 결정 패키지 | 비교할 대안 | 영향 및 선행 |
|---|---|---|
| host/owner 게시 권위 | 기존 raw host 전용 및 제한 복원을 제품에서 명시적으로 미지원 / 제품 host가 후보 owner를 준비한 뒤 원자 게시 | 전자는 현재 제품 준비 경로를 유지, 후자는 P02↔P03 배선과 실패 시 이전 UI/owner 보존 fixture가 필요 |
| 내부 사건과 외부 전달 | core drain 뒤 휘발성 단일 소비 / 외부 delivery 책임자가 안정 키를 부여하고 실패 후 재시도 | 중복/유실 및 복구 의미가 달라진다. 전달 대상·raw/filtered 공개 정책과 처리 시점부터 합의 |
| 저장 범위 | 제한 in-memory C0/Cn만 / versioned 운영 checkpoint·cursor와 복구 계약 | 후자는 K05–K07 seq/commit, O07 저장 스키마 및 외부 처리키 ownership이 선행 |
| 활성 모듈 및 입력 정책 | 지원 밖 후보를 원자 거부 / 모듈·의미 검사를 명시적으로 인수하고 후보 복원 | 기존 강제 주입 반례·오염 packet, 오류 우선순위, 정상 제품 도달을 각각 확인 |
| 접촉·결산 공개 | 표시 투영만 권위로 사용 / 허용된 filtered payload 필드를 UI 및 외부 계약으로 명문화 | 사용자에게 무엇이 보이는지 달라진다. 숨은 좌표와 ref lifetime·ack를 분리해 제품 경계 조사 |

## 5a 및 독립 5b

전용 `policy-ownership/`만 쓴다. 독립 oracle은 위 35개 정확 tuple, 두 원본 분모, 결정/조사/선택/소유 필드 및 P02 독립 closeout의 증거 위계를 수기로 대조한다. 결과 작성 도구가 기대값을 원장 자체에서 만들지 않는다. 5a는 35개 누락/중복, source anchor, 선택 행의 대안·영향·선행·주체·acceptance 존재와 미채택 표기를 검사한다. 대조는 정상 exit 0, POST_FILTERED_DRAIN/ui_publish 누락 exit 1, 미완 P02 eighth를 확정 계약 근거로 승격한 오분류 exit 1, 필수 정본 경로 부재 exit 2다. 모든 후보는 전용 폴더 사본에서만 만들고 실제 child exit/차집합/stdout/stderr를 남긴다.

승인 후 `python tmp/p03-parallel-state-20261108/policy-ownership/run_gate.py --manifest-sha256 <sha> --out <attempt>`를 저장소 루트에서 실행한다. PowerShell ErrorActionPreference Stop과 실제 LASTEXITCODE 전달, 정규 경로 중복/누락, 입력 및 manifest SHA, HEAD/Git 전후 대조를 요구한다. 정적 실행으로 Godot·프로젝트 cache를 쓰지 않는다. 재시도 K=3, 제한에 닿으면 즉시 보고하고 반복을 중단한다. 사후 5b는 구현 독립 비-Astra 모델이 35개 원문 매핑과 정책·현재 동작·책임 경계, 선택지의 실제 영향, 차집합 및 보존을 검토한다.
