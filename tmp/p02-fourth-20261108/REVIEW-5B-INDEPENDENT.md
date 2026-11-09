# P02 네 번째 조각 독립 구현 5-b

2026-11-08. **반려 — 변경 전 회귀 기준선 동결 위반.** 심사 계획 SHA `b57713b931567f8be7e6bc9e1c958fed74de3bd3ddb28b4d46c5718ca20725a8`. 제품 host를 심사하거나 P02 전체를 수용한 것이 아니다.

## 차단 사유

`baseline-regressions/results.json`의 `freeze_changes`에 `tmp/p02-fourth-20261108/gate.py`가 있다. 계획은 실행 전후 의존 source SHA 확인과 오염된 실행의 비정본 처리를 요구한다. 따라서 이 실행에서 얻은 변경 전 일곱 회귀 결과를 정본 기준선으로 쓸 수 없다. 해당 실행의 WorldLink는 90초 timeout이었고, 별도 `baseline-world` 재실행은 정상이다. `prove.py`의 `required_freezes_stable` 집합은 `baseline-regressions`를 빼므로 최종 verdict의 true는 이 위반을 가리지 못한다. 실행 중 gate.py 변경이 실제 자식 프로세스 결과를 오염시켰다는 증거는 없으나 계획의 동결 판정은 충족하지 않는다.

동결된 원본 owner를 안전하게 격리한 실행 환경에서 해당 변경 전 회귀를 다시 실행하여 source·runner·engine·fixture SHA와 결과를 남기거나, 기준선 대체 방법을 계획 단계에서 독립 재심사받아야 한다. 기존 실패와 판정 원문을 유지하고 새 증거의 실제 프로세스 수를 별도로 보고할 것. 수정 후 독립 5-b 재심사가 필요하다.

## 관찰

- 생산 변경은 guard 및 exact int side 검사 후 native `drain_events_for` 한 번과 깊은 복사다. 실제 제품 `_pump`가 요구하는 단일 공유 큐 소거·현재 탐지표에 따른 필터에 맞고, raw 접근이 남으므로 권한 보안 경계는 아니다. 기존 제품 화면, 배치, 시계, trace, WorldMap, replay 연결은 미완료다.
- runner는 독립 typed native BattleSim과 비교하고 양 side 안개 유무, raw 교체·side 전환 반례, 늦은 탐지, 자연 발생 2 salvo actor 마스킹과 1 ship_lost other 마스킹을 검사한다. invalid/busy guard·큐 보존, 양 방향 소거, nested payload 변형의 원본 참조 불변 및 pending command/clock/projection 검사를 확인했다. 원문 viewer는 E01–E14 148 assertions PASS다. 이는 검증된 제한 입력에 한정된다.
- 17개 기본 프로세스는 exit 0 15개와 의도 exit 1 2개로 기록됐다. 3 CLI 성공 바이트 전후 일치와 거부 출력 부재 판정은 있으나, 위 기준선 위반으로 전체 게이트를 수용하지 않는다. 처음 diagnostic 정규식 후처리 판정은 false로 보존되어 있고 후속 수정 판정이 true다. BattleFlow 변경 전 종료 진단은 161 ObjectDB/22 resources, 변경 후는 153/18이다. 후자는 10/28 과거 로그와 같으며 변경 직전 진단과 동일하다고 주장할 수 없다. WorldLink 별도 변경 전 재실행 및 변경 후 진단은 154/20이다.
- baseline 8656개를 독립 재해시하여 기존 경로에서 owner 하나만 변한 것을 확인했다. P03 경로의 추가 변동은 없었다. attempt1 freeze 206개는 현재 SHA가 모두 일치했다. before 및 baseline-regressions 당시 freeze에는 현재와 다른 owner와 gate.py가 있고 baseline-regressions의 실행 중 gate 변경이 위 차단 사유다. 이 검사는 실행 순간의 원자 스냅샷 증명이 아니다. 소유 hunk 역제거·신규 파일·index 등은 기록된 verdict에 추가 심사가 필요하다.

전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED. 엔진 예외, 동시 호출, 실제 제품 화면과 Android/성능은 범위 밖이다.
