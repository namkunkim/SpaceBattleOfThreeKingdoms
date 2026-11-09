# P03 격리 호스트 시계·게시 실행 결과

2026-11-09 KST. 5a PASS는 **선택적 BGM을 뺀 격리 호스트의 마지막 호출**에 한정한다. 구현 담당 배정은 gpt-6.1-sol이며 Astra는 사용하지 않았다. 독립 5b와 별도 마감은 다른 비-Astra GPT-6 Sol에 제출했다. HEAD `0be09755b70378286105972f35ac5b7031715664`.

| 실행 | 실제 종료 | 판정과 근거 |
|---|---:|---|
| 중지 전 preserve/reset, 2회 | 0 / 0 | 초기 지문 불일치. 두 로그 모두 스크립트 오류와 종료 누수. 미수용 이력. |
| attempt-03 | 0 | 네 단언 참, 초기 지문 동일. 스크립트 오류는 사라졌으나 ObjectDB 4·resource 2와 즉시 Job active 1로 게이트 실패. |
| attempt-04 | 0 | 네 단언 참, Job active 0. verbose에서 Ogg packet·stream 및 playback의 ObjectDB 4·resource 2를 `stars_stripes.ogg`로 좁힘. 게이트 실패. |
| attempt-05 | 0 | 격리 fixture에서 플레이어 stop, stream 분리, 250ms 대기 후에도 같은 음악 누수. 네 단언 참, Job active 0, 게이트 실패. |
| attempt-06 | 0 | 사전 독립 수용한 네 음악 관련 복사 제외 적용. 명명 단언 4/4, 예상 malformed profile 오류 2개만 관측. SCRIPT ERROR·누수·추가 진단 0, Job active 0·total 3, 게이트 통과. |

이전 두 호출을 포함한 실제 호출 상한 **K6 중 6회**를 사용했다. attempt-06에서 네 호스트는 canonical 경로로 로드했고, 같은 WorldLink brief seed 20261109에서 시작 논리 tick/clock_ms 0/0, 동일 지문 `c65540dbac9f03d8d0abecd7c03bdad03acd253d01b9d8243a786e3c81b972a7`, 동일 초기 투영·양 clock·표시 ID를 확인했다. 첫 프레임은 10Hz·1배속·0.05초를 실제 `FleetBattle3D._process`에 넘겼다. 주 clock phase 0은 tick/clock_ms 0/0, acc/alpha .5/.5였고 phase .75는 1/100, .25/.25였다. 시계 비교 허용 오차는 1e-6이며 나머지 보존 값과 대조군 관측은 정확 비교했다.

각 phase에서 `profile_patch`로 `profile.ally`를 의도적으로 잘못 만들어 실제 `init_game` 준비 오류에 도달했다. 오류 UI가 게시되는 것은 예상했다. 그 외 기존 sim·두 clock·VM·renderer·HUD 및 전대 객체, fingerprint·투영·표시 ID·화면·G·clock 관측이 유지됐다. selection/marker는 관측에 포함했으나 초기 빈 상태를 비교했다. 거부 직후 같은 다음 프레임은 각각 후보를 시도하지 않은 대조군과 일치했다. 대조군의 정상 새 전장 게시에서는 새 sim·clock을 채택하고 두 clock과 tick이 초기화됐다. 이 정상 게시는 운영 복원 진입의 증거가 아니다.

원본 입력 2,766개와 격리 사본 입력 2,748개는 각자의 전후 바이트 SHA가 일치했다. HEAD·index 및 전후 Git porcelain 상태 차이도 없었다. 원본과 복사 사이 차집합은 승인된 BGM 원본·import 설명자와 그 캐시 2개에 한정했다. 격리 엔진의 ResourceLoader도 음악 자산 부재를 확인했다. 실행 본체 `C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe` PID 37104, console PID 20916이며 해당 Windows Job의 종료 accounting active는 0이다. Job의 총 프로세스 3개 중 추가 자식의 실행 파일 정체는 따로 입증하지 않았다. 모든 TRACE는 격리 appdata 아래 기록됐다.

근거는 [원 실행 JSON](attempt-06/result.json), [stdout](attempt-06/stdout.txt), [stderr](attempt-06/stderr.txt), [격리 복사 차집합](attempt-06/approved-source-copy-differences.json)이다. 실행 중 보호 입력 안정성은 입력 전체의 의미, 원래 작업 트리 모든 바이트나 잠시 바뀌었다 되돌아온 입력을 증명하지 않는다. 공유 생산 파일은 변경하지 않았다. 완전한 제품 자산 환경의 깨끗한 종료, 실제 운영 복원 첫 프레임, 운영 phase 정책·UI 실패 보존 계약과 외부 ACK는 미검증이다. P03/I01/I01b/A04~A06 NOT_READY, 외부 저장 스키마 UNCLASSIFIED 유지.
