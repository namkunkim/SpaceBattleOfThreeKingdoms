# P02 독립 5-b 반려 후 변경 전 회귀 재구성 계획

2026-11-08 KST. 정본 보완 계획이며 구현·실행 승인 전이다. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED.

## 반려와 범위

baseline-regressions/results.json의 freeze_changes에 gate.py가 있다. 이 실행에서 나온 7개 비교용 변경 전 회귀는 비정본이다. baseline-world는 별도의 실행이다. prove.py의 required_freezes_stable에서 baseline-regressions가 빠져 proof-attempt1-verified의 passed=true는 유효한 종합 판정이 아니다. 기존 실행물/판정은 바이트 그대로 보존하고 새 감사에서 실패 이력으로 연결한다. 변경된 실행기가 이미 로딩됐다는 설명은 사전·사후 동결을 대체하지 않는다. 제품 소스의 수정이 필요한 반례는 이 지적에서 확인되지 않았다.

기존 17개 기본 실행 분모, 14개 E행, 독립 심사의 소유 hunk 범위를 그대로 둔다. 새 재현은 누락된 기준선의 보조 실행으로 7개를 복구한다. 기존 after 회귀와 경로/출력 차이의 영향을 점검하기 위해 동일 격리 경로 구성의 변경 후 7회도 실행한다. 기본 분모와 별도로 새 14회 및 리소스·격리 사전 탐침 프로세스의 실제 수를 기록한다. WorldLink의 정본 변경 전/후 기록과 CLI 4쌍, E행은 새 집계기가 동결 증거를 재검사한 뒤 재사용한다. 격리 비교는 제품 화면 인수가 아니다.

## 사전 복사 및 격리

1. 새 실행 증거 루트 tmp/p02-fourth-20261108/rebaseline-N/ 및 완전히 새 sibling 프로젝트 경로 두 개를 사용한다. workspace 내부의 일반 디렉터리로 만들되 canonical res:// 하위 경로는 그대로 유지한다. 프로젝트 쌍에 서로 또는 기존 프로젝트를 가리키는 symlink, junction, hardlink를 넣지 않는다. repo 전체 snapshot/worktree/브랜치 전환과 원 작업트리 owner 되감기를 금한다. 디스크 여유와 파일 수를 복사 전에 확인한다. 사용량 제한 시 즉시 중단·보고한다.
2. 복사 전 실제 기준선 감사로 owner 외 기존 입력 8656개와 branch/HEAD/index, 기존 P03와 ZIP을 보호한다. 합의된 동시변경은 원인·소유자·양 SHA를 별도 기재한다. 소스나 fixture가 동결값과 다르거나 P03/기존 증거와의 소유권 충돌이 확인되면 쓰기를 보류한다. 이후의 감사는 새 증거 루트만 분모에서 제외한다. 기존 runner, gate/prove 및 판정과 로그는 별도 SHA 목록으로 보호한다.
3. 복사 allowlist는 원 프로젝트의 project.godot, canonical source·tests·scenes·리소스 디렉터리, 런타임 데이터·assets와 원본 .import 설정, canonical .godot/global_script_class_cache.cfg, uid_cache.bin 및 필요한 imported/scene_groups_cache 자료, replay runner의 tmp/p02-third-20261108/oracle.native와 해당 runner가 실제 읽는 동결 입력이다. 기존 tmp/output 트리를 통째로 복사하지 않는다. 복사 목록의 정확한 상대경로/바이트/SHA와 참조 폐쇄를 실행 전 매니페스트에 명시한다. 숨김·ignored import 캐시는 baseline tracked 집계와 따로 기록한다. 외부 절대경로 의존을 발견하거나 cache 누락으로 import가 필요하면 실행 정본에서 제외하고 재심사한다. 에디터와 import 갱신은 금지한다.
4. before 프로젝트의 core/battle/operation_private_state.gd만 owner.before.gd.txt에서 바이트 그대로 복사한다. 사본 SHA·크기가 최초 baseline.json의 해당 행과 같고, 현재 작업트리 owner에서 owned-hunk.gd.txt 한 번만 역제거한 결과도 그 SHA와 같아야 한다. after 프로젝트는 현재 승인 검토 대상 owner bytes를 복사한다. 두 프로젝트는 owner 및 고정된 실행 출력/탐침을 제외한 모든 실행 소스·스크립트·cache·fixture 경로별 SHA가 같다. 각각 최초 baseline와 후속 freeze에 있는 대응 해시를 대조한다. 다른 차이는 근거 없이 정본으로 인정하지 않는다.
5. tests/p02_headless_adapter.gd와 tests/i01b_active_replace.gd의 기존 고정 OUT은 격리 프로젝트 안에서만 생성되도록 부모 디렉터리를 각각 비어 있게 만든다. 기존 파일은 복사하지 않는다. 두 runner와 나머지 5개 runner를 모두 canonical res://tests 경로에서 원문 그대로 실행한다. OUT 문자열을 바꾸거나 wrapper로 교체할 필요가 없다. 이전 headless relocation을 경유한 after와 비교할 때는 역치환한 runner SHA가 canonical runner와 일치함을 보여 주고, canonical pair에서 해당 pass marker 및 관측 분모를 대조한다. 기존 원경로에 쓰는 i01b 실행이 있었다면 해당 관측 사실과 전후 SHA 검증의 한계를 기록한다.
6. 실행 자식 프로세스의 사용자 데이터 환경을 별도의 새 경로에 지정한다. Windows Godot에서 실제 적용 여부를 추정하지 말고 동일 엔진의 headless 탐침에서 ProjectSettings.globalize_path("user://"), res://, 경로 케이스/절대 경로를 실측한다. trace/settings가 기존 사용자 디렉터리 또는 live repo에 매핑되면 본 실행을 시작하지 않는다. --path와 cwd 모두 격리 프로젝트, --log-file 및 stdout/stderr는 새 evidence 디렉터리로 설정한다. 탐침에서 Private._classes() 성공, BattleSim·owner·핵심 리소스 .resource_path, classcache 및 uid SHA, 설치 엔진 버전/SHA를 양쪽 확인한다. runner preload/scene/data가 canonical res:// 아래에서 실제 로드되는지 로그 및 매니페스트로 점검한다. 새 탐침은 집계 대상 7개 테스트와 분리한다.

## 실행과 판정

- 고정 일곱 행은 p02_headless_adapter, p02_worker_adapter, p02_replay_adapter, detection_rules, battle_flow, placement, i01b_active_replace다. before/after 각각 동일 순서로 실행한다. 별도 격리 경로와 순차 실행으로 출력 경합과 시간 변동 원인을 줄인다. 변경 전후 frozen launcher 자체를 수정하지 않는다. launcher·집계기 SHA, 명령 배열·cwd·환경 경로, engine·canonical cache·uid 및 양쪽 모든 입력 파일 SHA를 첫 프로세스 이전부터 마지막 이후까지 검증한다. 새 OUT 및 격리 user/log의 허용된 산출물 외 소스/cache 변경은 비정본이다. 검사별 timeout·actual exit·PASS marker·실제 논리/검사 수·stdout/stderr/engine log bytes SHA와 출력 크기/SHA를 기록한다. 실패 및 timeout은 보존한다.
- 기존 허용 진단 규칙을 넓히지 않는다. BattleFlow의 종료 누수 개수 차이는 기존 정확한 역사 로그 기준과 동일 규칙으로 따로 판정한다. 새 비교에서 미지의 차이는 숨기지 않고 독립 심사에 보낸다. 출력물의 비결정적 항목이 있다면 실제 바이트 차이와 허용 사유를 개별 기록한다. K6은 코드 조각의 기존 시도 번호와 연동하며 별도 무제한 재실행을 금한다.
- 새 집계기는 case별 before/after 및 viewer record의 실제 파일·프로세스 SHA에서 참조 stage 집합을 산출한다. 비교에 사용한 모든 stage의 freeze_changes가 비어 있고 입력·증거 매니페스트 검사가 성공해야만 passed=true를 낸다. 신규 baseline을 누락했거나 freeze_changes가 있는 기존 baseline-regressions를 명시 참조하면 실패하는 부정 검사도 별도 기록한다. 이 실패 판정은 실제 과거 결과를 편집해 주입하지 않는다. 기존 proof 판정 파일 및 로그는 변경하지 않는다.
- 종료 직후 실제 작업트리 전체 크기/SHA·신규경로 및 branch/HEAD/index, P03·ZIP·cache·기존 테스트 출력 보호를 재감사한다. 기존 owner 허용 hunk 역제거 및 기존 전체 diff-check 진단을 다시 입증한다. 기존 증거에 대한 회귀 실행의 동일 바이트 재기록 가능성과 새 실행의 미기록을 구분한다. 사용량 제한은 반복 호출 없이 즉시 보고한다.

독립 비-Astra 심사자가 계획 보완과 새 증거를 분리 판정한다. 실제 model/agent path/session ID/parent 및 판정 SHA를 기록한다. 작업트리 변경 없이 실행 조건을 확보하지 못하면 7개를 정본으로 선언하지 않는다. 이 경우 조율자는 새 기준선이 왜 불가능했는지, 근거로 쓸 기존 정본과 인수 범위가 얼마나 좁아지는지 별도 제안하고 독립 스펙 수용을 먼저 받아야 한다.
