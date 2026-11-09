# P05 전용 native 접근 검증 독립 심사

2026-11-09 / 독립 검토자 `independent_review` / **P05 전용 가드 및 Windows 자동 렌더 검증 한정 수용**.

대상 [결과](P05-PC-NATIVE-ACCESS-RESULT-20261109.md)의 동결 SHA-256 `65ED367455DF454417573E80DC8C8F7C6FDEC6136D5E99441E14F875799A5331`을 직접 확인했다. 작성·구현에 참여하지 않은 검토자가 `tools/p05_access_demo/` 원문, 실행 자료 및 Windows PNG를 대조하고 별도 headless 실행과 연속 이동 반례를 수행했다.

## 실행 근거

| 확인 | 결과 |
|---|---|
| 정본 Headless | Windows/Godot 4.7.2, display=headless, 19/19, exit 0. 로그 안 P05_RESULT와 결과 JSON 일치, SCRIPT ERROR/ERROR/WARNING 문자열 없음. |
| 정본 WindowsAuto | display=Windows, Intel Arc 130V, 1050×760, 19/19, exit 0. 명령에 --headless 없음. 로그의 OpenGL 장치 정보·결과 JSON·프레임 완료/저장 결과가 일치한다. |
| PNG 직접 확인 | 19/19 표시, 세 항로·노드·C 앞 정지 외곽을 눈으로 확인했다. SHA-256 `5E0C4F01536605B5FB7897686F2DC9692B5E703498C403C912C6A4587F2C80D6` 일치. |
| 독립 Headless | [별도 실행 결과](../../../tmp/p05-native-independent-20261109/headless/Headless.json), [명령](../../../tmp/p05-native-independent-20261109/headless/Headless.command.json), [exit](../../../tmp/p05-native-independent-20261109/headless/Headless.exit.txt). actual exit 0, 19/19. 정본 두 실행과 results 배열 전체가 필드 단위로 같다. |
| 독립 swept 반례 | [별도 탐침](../../../tmp/p05-native-independent-20261109/probe/independent_sweep_probe.gd), [로그](../../../tmp/p05-native-independent-20261109/headless/independent-sweep.log). 수비 원 밖의 두 끝점을 잇지만 중간이 침범하는 2단위 선분을 `_swept`에 넣어 defender_clearance와 상태 불변을 확인했다(actual exit 0). 전장 경계의 허용과 0.01 바깥 거부도 통과했다. 이는 내부 기하 함수 반례이며 정상 사용자 경로 실행과 구별한다. |

독립 탐침 첫 시도는 이전 도구 호출의 임시 프로젝트 경로가 다음 호출에서 보이지 않아 파일 생성/프로젝트 접근이 실패했다. 이를 성공 증거로 쓰지 않았다. 후속은 별도 workspace tmp에 원본 파일을 복사한 프로젝트에서 성공했다. 원본 구현은 수정하지 않았다.

결과 문서에 기록한 guard/demo/build_manifest·manifest·PNG 해시를 대조했고 일치했다. Windows와 Headless의 manifest는 동일하다. 이 확인은 지정 입력의 일치이며 작업 트리 전체 변경 보존의 감사는 아니다.

## 시작점·화면 증거의 경계

`project.godot`/`main.tscn`의 전용 장면에서 manifest를 읽고 버튼을 만든다. 수동 버튼의 pressed와 Headless/WindowsAuto의 지연 signal emit은 같은 `_start_checks`로 연결된다. 자동 검사는 외부 OS 마우스·키보드 입력을 보내지 않는다. WindowsAuto는 렌더 완료 신호를 두 번 기다린 뒤 자기 viewport를 저장한다. 따라서 실제 Windows 렌더러가 그린 전용 검증 장면의 증거로 수용한다.

실제 사용자의 버튼 클릭·OS 입력 귀속, 시간에 따른 이동 애니메이션, 기존 FleetBattle3D/WorldMap 시작·표시·결산의 검증은 아니다. `_start_checks` 안에서 시뮬레이션을 동기로 완료한 뒤 최종 정지 witness를 그린다는 구현과 결과 문서의 한계가 일치한다. 검토자는 Windows UI 입력이나 새 Windows GUI 실행을 하지 않았다.

## 가드와 실패 원자성

`step`은 이전 state의 깊은 사본에 tick/heading/plan/index/positions를 제안하고 `_swept` 성공 뒤에만 state를 게시한다. 추종 편차·속도·기하 실패 경로는 게시 전에 반환한다. `visit`도 모든 중심의 영역 조건을 확인한 뒤 visits/complete를 사본에 기록한다. unknown_route 시작은 route/points/offsets를 바꾸기 전에 반환한다.

거부 5건에서 live Dictionary 비교와 JSON before/after를 확인했다. 위치·heading·tick·진행 index·moving·returning·visits·complete 및 route/points/offsets/radii/neck/service 설정이 보존된다. 정상 retry는 추종/속도 거부 뒤 같은 그룹에서 한 틱 진행하고 두 위치가 바뀐다. 서비스 거부 뒤에도 다음 구간을 진행할 수 있다.

전용 구현에는 실제 게임 이벤트 큐나 외부 결산 게시가 없다. visits는 전용 영역 방문 기록이며, 그 보존을 실제 P03 사건·외부 효과 원자성으로 확대하지 않는다. 고정 manifest는 snapshot 대상이 아니며 입력 검증 전반·동시 writer·외부 IO 실패를 검사한 것으로 해석하지 않는다.

## 연속 이동과 영역

- 각 실제 끝점에서 추종 2, 속도 상한과 전장·캡슐 침식 조건을 검사한다. 허용 속도에는 0.001의 수치 비교 허용폭이 있다. 두 실제 끝점 사이를 직선으로 잇는 전용 모형에서 전장과 침식 캡슐은 볼록하므로 끝점 검사로 전체 선분을 덮는다.
- 실제 중심을 검사할 때 반경에서 TRACK을 빼고 채택 외곽+SAFETY를 사용하는 것은 실제 위치에 추종 편차를 중복 합산하지 않는 처리다. 수비 원은 팽창값을 유지해 보수적으로 검사한다.
- 수비 외곽은 중심부터 이동 선분까지의 최소 거리, 아군끼리는 상대 위치 선분의 원점 최소 거리로 검사한다. 샘플 사이 침범을 놓치는 끝점 전용 검사가 아니다. 독립 tangent 반례에서도 이를 확인했다.
- 횡단 목 검사는 해당 J–A 구간의 축 범위·횡폭 조건을 적용한다. 원이 목에 닿는 범위를 보수적으로 잡으므로 좁은 목의 실패가 보장된다. 임의 장애물 경로 탐색이나 지도 전체 우회 불가 증거는 아니다.
- E/R 배치에서 전체 팽창 외곽과 세계 경계·아군 이격을 검사한다. A/B 서비스 및 C/E 도착은 정지 계획점과 실제 중심을 검사한다. 구간 끝 정지 후 heading을 갱신하고 동일 경로를 역순으로 복귀하므로 19행의 정면/우회 서비스 이탈·목표 접근·철수 및 R 접근을 수용한다.

허용되는 세계선은 이 전용 모형의 직선 보간과 정지 선회다. 기존 게임의 실제 기동·렌더 추종을 이 가드가 제어한다는 증거는 아니다. 진형 전환은 채택된 최대 원에 포함하는 방식이며 개별 함선 전환 애니메이션을 실행해 검증하지 않았다.

## 최종 범위

정본의 12개 양성·7개 부정/복구 및 별도 내부 swept 반례에서 차단 결함을 발견하지 못했다. **P05 전용 native 실행과 Windows 자동 렌더 확인을 한정 수용**한다. 제품 이관은 별도다. P02의 실제 시작·명령·표시·결산, P03 전투 상태/사건과 원자성, P07 실제 가동 보급·시간 증원·목표/철수 결과를 연결하고 같은 반례를 다시 인수해야 한다.

**제품 P05/A04 및 전체 캠페인/I01/I01b NOT_READY, 외부 저장 스키마 UNCLASSIFIED**를 유지한다. 검토 쓰기는 이 리뷰와 허용된 독립 실행용 tmp 자료뿐이며 P02/P03·공유 소스·HTML·Git 상태를 변경하지 않았다.
