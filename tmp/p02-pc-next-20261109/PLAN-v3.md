# P02 직접 출격 거절 · V3 정적 준비 인계

판정 요청 범위는 runner, 기존 테스트 overlay, 예상 실행 closure의 정적 검토다. 원본 제품/테스트와 이전 PC0 및 K6 기록을 바꾸지 않았고 Godot을 실행하지 않았다. 실제 runner 실행 적합성은 보류한다. 독립 심사자 실제 모델 식별은 조율자의 할당 기록을 사용한다.

## 재현할 파일과 이전 V2 대비 확정점

- run-reviewed.py는 V2의 14개 lane의 순서, argv 템플릿, 환경, 로그 위치, per-lane deadline과 기대 종료를 소스로 정의한다. attempt-NN 아래 before/after의 각 import, reject, direct, auto-complete, auto-cancel, title, restart다. auto-complete 외부 deadline은 probe의 175초 내부 기한을 감안해 195초다. 총 1,680초는 두 프로젝트의 각 명령 timeout 합계이며 해시·복제·스케줄링·정리 소요를 포함한 벽시계 보장은 아니다.
- closure-v2.json의 현재 SHA 1,480개는 PC0 source 명단과 기존 WorldLink 및 title/restart의 TestCheck 의존을 포함한다. 현재 P03 private owner와 다른 소유자의 runtime 파일은 두 lane 동일 bytes다. 4개 미존재 UID는 이전 격리 산출물이므로 현재 source에는 생략했고 기존 Godot 캐시를 복제하지 않는다. 보존 대상의 before SHA 및 actual HEAD/index를 runner가 재검사한다. reviewer는 source뿐 아니라 같은 시점의 P03 쓰기 경계도 확인한다.
- world-link-cases.gd.txt 및 prepare-world-test.py로 기존 tests/world_link.gd에 적용할 world-link-prepared.gd.txt를 실제 생성했다. 독립 리뷰는 전체 prepared 파일과 현재 suite의 diff를 본다. 기존 default suite의 _run 진입을 유지하고 두 명시 opt-in 분기를 추가한다. 테스트 파일은 원본에 적용하지 않았다. stdout 행 마커는 45개 ID 및 순서, 단언 실패와 종료를 비교한다. R1은 dynamic Object.call의 Variant를 읽어 void baseline을 즉시 오류로 중단하지 않는다. A/B 각각은 다른 sentinel/context로 설정하고 성공/실패 사례를 뒤섞지 않는다. C는 outgoing node 참조를 frame await 전에만 사용하고 scene_changed를 호출 전에 연결한다.
- 실제 엔진 fixture는 import 완료 뒤 복제본에서 FleetBattle3D.tscn 하나만 빠진 경로를 만들고, 의심 remap/대체 cache entry를 가드한다. WorldMap.tscn은 WorldMapScreen 스크립트만 참조한다. WorldLink의 대상은 문자열 const이고 기존 테스트 _round_trip은 WorldMap부터 만들며, 이 production 경계에서 씬을 preload하는 호출은 찾지 못했다. project.godot의 main_scene 참조는 남는다. --script + SceneTree로 앱 main scene을 로딩하지 않는 경로를 기대하며, 실제 GDScript/type loader가 명시 runner를 실행하지 못하면 정상 reject로 인정하지 않는다. F1/F2/F3과 실제 ERR_CANT_OPEN 원문을 요구한다.
- 실제 제품 후보의 두 파일 bytes는 아직 없다. 승인 manifest의 candidate 파일 경로가 누락되면 runner는 launch 전 실패한다. 조율자에게 승인받은 고정 SHA와 같은 파일만 읽으며 원본을 편집하는 코드가 없다. runner와 제품 후보, diff, executable, closure, 준비된 테스트를 포함한 독립 입력 승인이 필요하다.

## Windows 프로세스 계약과 현재 미검증

- 승인 실행 명령 형식은 C:/Python314/python.exe -I -B C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/p02-pc-next-20261109/run-reviewed.py <정확 승인 manifest 절대 경로> <그 SHA-256>이다. 새 attempt 경로, exact SHA, index/HEAD, 전용 user/appdata/tmp를 점검한다. command.json은 Popen 전에 기록된다.
- run-reviewed.py는 이전 owned_job_python_nowindow_candidate.py 모듈을 재사용하며 그 소스를 변경하지 않는다. 실행 시 stdout/stderr는 파이프가 아닌 두 신규 이진 파일 handle을 사용한다. 브로커의 stdin만 제한된 argv barrier pipe이고 할당 실패에서 EOF로 닫힌다. 고유 kill-on-close Job에 inert 브로커를 할당하고 성공 후 명령 한 줄만 전송한다. 개별 deadline/abort에서 자기 Job만 125로 terminate 요청, active 0과 브로커 exit 확인을 요구한다. 이름 기반 종료, 사용자 창·입력, 전역 파일 이동을 하지 않는다. supervisor exception은 별도 기록으로 남으며 정상 cleanup으로 오인하지 않는다.
- 기존 Python-only K3의 실패/예산을 보존한다. 이 준비는 그 진단의 재실행 또는 이름 변경 재시도가 아니다. 이전 독립 결과의 unexpected owned image와 실제 Godot console 자손, child exit 전파, Job/파일 handle 상속 및 user directory 초기화 적합성이 이번 파일 작성으로 해결됐다고 볼 수 없다. 특히 현재 receipt는 브로커 PID/exit와 Job active의 관측이며 개별 Godot child HANDLE과 실제 exit의 별도 관측은 제공하지 않는다. 이를 V2 제품 실행 계약에 충분하다고 가정하지 않는다. reviewer는 기존 C# 감독기 기반 stdout/stderr 추가나 다른 수용 가능한 관측 수단이 필요한지 먼저 판정한다. 이 미검증을 통과로 간주하거나 Python K3를 반복해서 메우지 않는다.
- runner의 정적 AST parse와 테스트 준비/원본 diff만 수행했다. GDScript 파싱, 예상 에러 정확한 텍스트·콘솔 스트림 귀속, 45행 실행, staging 이후 생성 캐시, actual exit/cleanup, UI 성공은 실행 전 가설이다. 실패 로그 문구는 Godot 소스에서 근거를 얻었으며 설치본 raw 결과로 구분한다. known teardown은 lane 대조 후 독립 심사가 필요하다. 45/45 후보, 정상 direct, auto 14/15 및 title/restart 결과가 있는 경우에도 범위는 legacy 장면 전환 경계다.

## 실행 전 독립 심사와 고정할 자료

1. prepared 테스트와 실제 두 product 후보를 독립 검토한다. browse에서는 출격 전 brief와 입력 해제, result에서는 이전 결산 객체/버튼/지역 표시, audio/timer 재게시 방지를 모두 검토한다.
2. runner의 console 자손/cleanup/exit 및 stdout/stderr 증거 부족 해결책을 검토한다. 해결 전 엔진을 실행하지 않는다. 불필요한 GUI/OS probe나 PC0 제품 실행으로 바꾸지 않는다.
3. 승인본 manifest에 실행 source/runner/test/candidate/engine 두 바이너리/기존 probe/broker SHA 및 실제 attempt를 고정한다. 예상 오류·재시도 상한을 검토한 뒤 최초 실행만 허용한다. execution-ready 표시나 승인 manifest는 이 준비에서 생성하지 않았다.
4. PC0 2/2, 이전 K6 미사용, 이번 별도 조각 0/6이다. P02 전체와 첫 PC operation은 NOT_READY. P03/P05/P07의 공유 소유를 유지하고 제품 파일을 별도 독립 심사 전 적용하지 않는다.
