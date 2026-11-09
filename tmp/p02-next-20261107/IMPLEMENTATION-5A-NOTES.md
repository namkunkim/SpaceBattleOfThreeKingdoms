# P02 operation worker 5-a 실행 메모

- 계획 SHA256 `868d120de5d6c1de2c66c3bb8268902bde114cfb9948f2cddac9b1c523694c8c` 및 독립 계획 한정 수용 후 실행. 이번 기록은 구현 심사 전 단계다.
- `preflight-crlf`는 resolver 원문 복사 검사에서 CRLF를 처리하지 못해 실패했다. child engine 실행 전이므로 새 K6 시도에 포함하지 않는다.
- Attempt 1: API 검사에서 `AutoResolver.resource_path`를 GDScript 파서가 정적 멤버로 해석했다. actual exit 1, SCRIPT ERROR 1, ERROR 1. 결과와 원문을 보존했다. 검사를 인스턴스의 실제 script resource path로 바꿨다.
- Attempt 2: W1–W4/W6 실행 및 기존 통계/sync exact bytes는 통과했다. 초기 module 부정 입력의 임의 combat key는 원본 어댑터에서 `unsupported_combat_content/profile`을 반환했다. `unsupported_module_config/profile.combat`은 금지된 이름인 morale 등을 구성한 경우에 해당함을 `OperationPrivateState._profile_error`로 확인했다. Attempt 3에서 임의 콘텐츠와 실제 금지 모듈을 따로 검사한다. 기존 allowlist를 수정하지 않았다. Attempt 2의 WorldLink 전 기준선 프로세스는 90초 제한에서 timeout 처리했다. 시도 3 준비 중 공유 runner 및 API runner가 바뀌어 시도 2의 사후 freeze 대조가 실패했다. 두 원인 모두 결과에 보존한다.
- Attempt 3: 사전 동결 후 실행했다. 실행별 실제 exit, stdout, stderr, Godot engine log, 진단 수, 기대값, output SHA를 별도 저장한다. WorldLink는 각각 240초 제한이고 원문 legacy resolver 및 현재 resolver의 결산 사본을 비교하며 원본 world_link.gd를 별도로 실행한다. 테스트용 WorldLink 사본은 preload 경로와 결산 출력 한 줄만 추가했고 바이트 역변환을 확인했다.
- Worker fixture 원본/파생 SHA와 변경 필드는 `fixture-provenance.json`에 있다. W1/W2에 기존 POC/services의 policy=none, 전원 delegate, max_ticks=18000을 적용했다. W3는 원거리 fixture에서 max_ticks=1을 유지했다. 직접 BattleSim oracle은 fixture 값의 fleet 정수 타입을 독립 지정해 native step과 drain을 검증한다.
- 서비스 fixture에서 contact 1, salvo 9, ship_lost 5, battle_end 1. supply 완료 사건은 관측되지 않았다. 세 fixture의 CLI 결과는 executor 외 기존 동기 결과와 동일하고 API의 native event 자료형과 순서는 직접 oracle과 일치했다. 정책 외부 명령 주입이 없으며 세 관측의 명령 로그 count는 0이다.
- Thread.start OS 실패 및 엔진 예외 주입은 미실증. worker 소유 스레드 ID를 DTO에 넣지 않았으며 생성·close 호출 경계는 독립 소스 심사 항목이다. stock data_rules는 이번 별도 실행 대상에서 제외했다. 기존 프로필/룰 파일 변경이 없고 core/private/P02와 WorldLink를 별도로 대조한다.
- 보존 기준선 7,078개 중 소유 원문 2, P03 별도 활성 작업의 수정 3, 나머지 7,073개 동일, 누락 0. P03 새 증거 트리는 변경 경로와 명령·freeze 의존성에서 제외되어 있다. 현재 diff-check exit 2 및 stdout/stderr는 사전과 byte-exact이고 CHECKLIST-OPEN 33행 진단만 있다. 소유 코드 diff-check exit 0. HEAD/branch/index/index-tree 원문도 동일하다.

## Attempt 3 종료

- 총 53 subprocess, 정상 기대 exit 0 19개와 거부 기대 exit 1 34개. Worker 거부 17개와 기존 CLI 거부 17개를 별도 집계했다. API 59개 고정 검사와 관측 running frame 58개. 총 9개 비교가 참이고 412개 사전 동결 입력의 사후 SHA가 일치했다.
- WorldLink 계측 사본 전/후는 전체 outcome JSON과 stderr가 byte-exact였다. 전/후 모두 154 ObjectDB instances WARNING 1 및 20 resources in use ERROR 1. 순정 world_link.gd 역시 WORLD_LINK_PASS, exit 0이며 종료 진단 종류는 같고 수치는 150 instances와 18 resources였다. 3개 이외 프로세스에서 SCRIPT ERROR/ERROR/WARNING 0.
- Attempt 1/2 runner 원문은 두 freeze 기록과 동일한 SHA로 별도 복원해 각 폴더의 source.txt에 보관했다.
