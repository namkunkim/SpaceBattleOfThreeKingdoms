# PC0 terminal 수정 준비물 독립 심사

판정: **격리 legacy PC0 기준선 한 회를 수용한다.** 제품 operation·사람 플레이·여덟째 K6 또는 P02/P03 전체 수용이 아니다. 심사 모델 gpt-6.1-terra. 본 심사에서는 제품/Godot/GUI/Job을 실행하지 않았다.

승인 대상 `prepared-pc0-terminal/REVIEW-MANIFEST.json` SHA-256 **`4783b7dbad772643726a8cf7b253f353aa48f0481b732634afc3bc41436b1cc7`**이며 정확 part 12개 SHA 및 1,470 source/641 generated import refs/unresolved 0을 확인했다. 현재 frozen Git/protected baseline과 엔진 두 SHA가 일치하며 `run-01`은 없다. 수용 기록 `PC0-TERMINAL-APPROVAL.json` SHA `f833e71284e390de33a1a1af35f1e85348f88a957c7feab54ba4dcf8f7352e21`은 위 manifest를 지목한다. 실행 직전 동일 SHA·protected HEAD/index/P03/worker·전용 run 및 output 부재를 다시 확인하고 drift면 멈춘다. 이전 원문을 복원·stage·삭제하지 않는다.

앞선 terminal 결함은 수정됐다. 동일 host/sim/epoch·tick/clock 및 2초 간격을 요구하면서 정상 play→end 전환은 허용하고, 별도 end-screen marker의 결과 HUD·순서·동일 시계를 검사한다. hand-authored `verify_battle` synthetic을 독립 실행해 정상 2·변조 8 거부를 확인했다. 이것은 정상 실제 엔진 결과가 아니다. source 기반 tick 12010/1,200,950ms는 기존 10Hz·2×50ms 첫 substep·1초 판정 및 다른 우선 종결 부재라는 조건하의 기대다.

정확 실행 명령은 기본 managed sandbox에서 `pwsh -NoProfile -File C:\WorkSpace\SpaceBattleOfThreeKingdoms\tmp\p02-first-pc-20261109\prepared-pc0-terminal\supervisor.ps1 -AcceptedManifestSha 4783b7dbad772643726a8cf7b253f353aa48f0481b732634afc3bc41436b1cc7`이다. Supervisor는 HEAD source를 신규 복제하고 격리 user/cache·headless isolation/import 성공 후에만 동일 GUI exe 제품 장면을 시작한다. 직접 suspended→전용 Job assign/membership→resume, action 전 HWND/PID/foreground/client 검증, 단계별 180/180/1440/120초·전체 1920초 및 소유 Job 정리를 따른다. OS Job·headless print/log·GUI 실행은 아직 실측이 아니며 실패하면 그 지점에서 중단하고 실제 원문을 남긴다. 예상 밖 자손이나 membership 불능을 통과로 바꾸지 않는다. 기존 사용자 창·프로세스는 조작하지 않는다.

CUA 실제 입력만 사용하고 각 action의 전후 screenshot·foreground·대응 trace를 원문으로 남긴다. 외부 입력을 완전히 배제했다는 주장은 하지 않는다. 명령은 ID/log·거절 부재·이동과 함께, terminal은 실제 event/outcome·지도 1회 소비와 함께 검증한다. trace의 적 비가시 정보는 수집/플레이어 판단에 사용하지 않는다. 고정 seed overlay는 원래 randi 소비 뒤 결과만 고정한 fixture이며 관찰용 나머지 두 overlay는 제품 상태를 의도적으로 쓰지 않는다. UI·자연 종료·생성 로그/성능의 미측정 또는 시간 초과는 미완료이고 내부 함수나 강제 종료로 보충하지 않는다.

승인은 **이번 PC0 한 번**에 한정된다. 결과 원문과 시각 근거는 별도 비Astra 독립 5-b를 받아야 한다. 과거 Python K3 실패와 여덟째 후보 K1~K5/미실행 K6 한 회·21행을 보존하고, 이 legacy baseline 결과를 그 후보나 실제 적벽 operation/P07 목표·명시 철수의 증거로 전환하지 않는다.
