# P02 직접 출격 거절 · V4 실제 엔진 계획 검토본

상태: 제품 후보·테스트와 C# 직접 실행 경로를 격리 evidence 안에 준비했다. C# Add-Type 컴파일, PowerShell parser, Python AST만 확인했다. Godot 및 실제 Windows Job 감독은 0회다. 제품 파일·테스트 원본과 Git index는 그대로다. 독립 실행계획 수용 전 제품이나 이 runner를 실행하지 않는다.

## 후보와 범위

- candidate/world_link.gd.txt와 candidate/world_map_screen.gd.txt가 두 제품 파일의 정확한 후보 bytes다. candidate-review.diff는 원본과 후보 두 파일 및 tests/world_link.gd 검증 overlay를 대조한다. .txt 확장자는 evidence의 GDScript class가 원본 project import에 등록되지 않게 한다.
- WorldLink.go_battle는 기존 성공 순서로 brief/outcome/난이도/모드를 먼저 설정한다. SceneTree가 즉시 반환한 Error가 OK가 아니면 네 필드의 이전 값과 참조를 되돌린다. WorldMap은 출격 직전 상태·brief·표시·입력 잠금·화살표·소유 지역 표현을 보존한다. 거절 시 장면을 떠나지 않고 같은 카드/결산을 복구하고 오류를 표시한다. 결과 객체는 직접 바꾸지 않는다. 기존 _show_result·consume·decision 소리·타이머 생성은 호출하지 않는다. 전환이 수락된 다음 장면 내부 준비 실패는 기존 별도 경계다. 기존 auto와 WorldLink 부재 분기의 선택은 그대로다.
- 초기 복구에서 카메라 연출의 시간·프레임은 되감지 않는다. 이 범위는 legacy 실제 PC 직접 출격의 에러 처리다. 신규 operation 입력·권위 상태·시간·명령·결산 연결과 PC 물리 입력/자연 종료는 미완료다.
- 기존 테스트 검증 overlay의 --direct-reject는 F/R/A/BS/BN 45행과 엔진 거절 4회다. --direct-round-trip은 기존 왕복과 고정 추가 C1–C4를 실행한다. 성공 lane은 결과를 강제 발생시키므로 자연 종결 인수가 아니다. auto는 기존 K5 probe의 완료 14행/취소 15행 및 전후 결산 fingerprint 일치, title/restart는 기존 통과 마커와 exit를 요구한다. 후보 GDScript의 파싱·테스트 수명 및 각 행의 실측은 남아 있다.

## 정확한 실행 입력 및 경계

- DIRECT-MANIFEST-REVIEW-ONLY.json의 승인 전 SHA-256은 bd97072161948804f8ab970ec83573c4b589a64548f374c8b77105976a4c9b76이다. attempt-01의 14개 실제 argv/env/absolute cwd/out과 승인 필수 11개 파일 SHA를 포함한다. runner는 검토본 상태값을 거절한다. 심사자가 수용한 경우에만 상태를 별도 승인본에 기록하며 기존 검토본은 보존한다. 외부 명령은 C:/Python314/python.exe -I -B C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/p02-pc-next-20261109/run-direct.py <독립 승인본 절대 경로> <승인본 SHA>다.
- run-direct.py는 branch/HEAD/index SHA와 closure-v2.json의 source bytes를 재검사한다. P03 private owner SHA 46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3, worker·P02 진행표·project.godot 동결을 확인한다. before/after에 현재 P03 bytes가 동일하고 후보 변경은 두 제품 파일뿐이다. 각 isolated import 전에 동일 prepared 테스트 및 byte-identical K5 probe를 넣는다. .godot/class cache 및 생성 UID는 새로 생성되어 post-import.json에서 실제 해시를 얻는다. 원본 cache는 입력으로 복제하지 않는다. 원본 해시 변화 또는 상대 소유 충돌이 생기면 적용 전에 멈추고 재동결한다.
- reject는 각 import 완료 사본에서 오직 FleetBattle3D.tscn을 복제 대상에서 제외한다. 해당 scene 외 after-import SHA와 모두 일치해야 하며 remap/cache 패턴 가드와 F1/F2를 통과해야 한다. 프로젝트 기본 scene 설정은 그대로 둔다. 설치된 엔진 버전에 해당하는 소스에서 --script 설정 시 기본 scene fallback을 건너뛰고 script로 SceneTree를 생성한 뒤 WorldLink autoload를 읽는 분기를 확인했다. 실제 장면 누락이 typed script startup을 막으면 F/R/A/B 누락으로 실패한다. 이 경우 main scene startup 실패를 정상 엔진 거절로 집계하지 않는다. [Godot 4.7.2 main source](https://github.com/godotengine/godot/blob/ed1daf0bf/main/main.cpp#L4018).
- 14개 process에 import 300초, reject 45초, direct 60초, auto-complete 195초, auto-cancel 90초, title 75초, restart 75초를 before/after 각 적용한다. 합 1,680초는 Godot lane 기한의 합이다. staging·PowerShell 컴파일·OS scheduling·정리 포함 전체 벽시계 보장이 아니다. launcher의 별도 Python supervisor wait는 lane+45초, abort 이후 15초, exact supervisor 종료 및 wait 5초다. 각 실제 보고에서 stop/실패/exit/cleanup은 별개다.

## C# 직접 감독과 로그 오라클

- P02DirectJob.cs는 PC0의 C# 직접 실행기에서 GUI 관찰·창 단계 없이 사용하는 분기다. console wrapper를 거치지 않고 공식 Godot GUI exe에 --headless --log-file을 넘긴다. suspended root를 새 kill-on-close Job에 할당하고 보유 HANDLE의 image/hash/membership 확인 뒤 재개한다. raw root PID·실제 signal/exit, Job snapshot, 보유한 자손 HANDLE signal/exit 및 active 0을 TSV에 기록한다. 종료값 1은 before reject에서만 기대하며 제품 후보 reject와 정상 lane은 0이다. 외부 supervisor가 실패하면 raw 자료를 보존하고 성공을 판정하지 않는다. 새 코드에서 실제 Job 동작은 미실행이며 이전 PC0 관측은 이 실행을 보증하지 않는다.
- engine.log만 Godot 출력의 검증 계약이다. supervisor.stdout/stderr는 PowerShell 감독기용이며 엔진 스트림 귀속을 주장하지 않는다. engine.log 부재·행/마커 누락·새 오류·SCRIPT ERROR·parse 오류는 실패다. missing-scene 호출당 두 정확한 경로의 엔진 오류를 각각 네 개 요구한다. baseline reject에서는 의도된 테스트 실패와 실제 1을 별도로 집계하고, 후보 reject는 ERR_CANT_OPEN 계약과 전체 45/45, 실제 0 및 cleanup 0을 요구한다. 자원 종료 진단은 독립 5-b에서 전후 raw 로그로 별도 대조한다. [텍스트 로더](https://github.com/godotengine/godot/blob/ed1daf0bf/scene/resources/resource_format_text.cpp#L1344) · [ResourceLoader](https://github.com/godotengine/godot/blob/ed1daf0bf/core/io/resource_loader.cpp#L274).
- 이전 Python broker와 Python-only K3을 실행하지 않는다. PC0의 2/2는 소진 상태다. 여덟째 K6은 미사용이고 이번 조각은 별도의 0/6이다. PC0의 first GUI scene·화면·입력을 다시 시도하는 계획이 아니다.

## 인수 순서

1. 다른 실제 비-Astra 모델이 고정 manifest, 후보·테스트 diff, C# 프로세스 경계, engine log 판정 및 소유 상태를 대조한다. 독립 판정 모델 ID를 실제 런타임에서 확인해 남긴다.
2. 실행계획 수용 이후 고정된 격리 lane만 실행한다. 결과 해석은 실제 TSV/engine log와 source/생성 cache SHA에 근거한다. 필요 시 이 조각의 K 상한 안에서 수정하고 이전 로그는 남긴다.
3. 독립 5-b 이후 공유 원본 적용 여부를 판단한다. 이 조각의 수용만으로 P02 전체나 첫 PC operation을 완료로 바꾸지 않는다.
