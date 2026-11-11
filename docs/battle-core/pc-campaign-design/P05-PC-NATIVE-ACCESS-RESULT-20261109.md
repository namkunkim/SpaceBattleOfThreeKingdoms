# P05 전용 경로 가드와 Windows PC 검증

2026-11-09 · **P05 독립 실행 검증 19/19 · 제품 P05/A04 및 전체 캠페인/I01/I01b NOT_READY · 외부 저장 스키마 UNCLASSIFIED**.

## 구현과 인수 범위

채택한 `p05-layout-disks-v1`, 승인 중심 편차 2와 별도 안전 여유 1을 사용했다. 앞선 오프라인 검증의 경로와 정지 좌표·후보 반경을 읽어 `effective` manifest를 만들고, 검증 전용 Godot 창에서 동일 자료를 읽는다. 기존 게임 프로젝트와 별개이며 P02/P03의 제품 진입·명령·결산에는 배선하지 않았다. [접근 계약](P05-PC-MAP-ACCESS-VALIDATION-20261109.md) · [외곽 근거](P05-PC-FORMATION-ENVELOPE-EVIDENCE-20261109.md) · [실행 방법](../../../tools/p05_access_demo/README.md).

- 그룹 가드는 한 업데이트에서 제안된 두 중심, heading·진행 인덱스·틱을 함께 검사한 뒤 게시한다. 계획 중심 대비 오차, 한 걸음의 상한, 연속 이동선의 전장·회랑·수비 외곽·다른 함대 이격을 검사한다. 구간별 정지 후 방향을 바꾸고, 같은 경로로 복귀한다. 실패 시 직전 위치와 진행을 통째로 유지한다. [이동 가드](../../../tools/p05_access_demo/guard.gd).
- E/R 배치는 팽창 외곽 전체, A/B 보급·C 목표·E 철수는 해당 정지 지점에서 각 함대 중심을 검증한다. C 수비는 고정 외곽이며 움직이는 적의 교전, 보급량이나 시간 증원 사건, 제품의 목표·철수 결산은 이 실행에서 관찰하지 않았다. 유비군 두 진형 전환은 이미 전환 최대를 포함한 외곽으로 검사했다. [이동과 영역](../../../tools/p05_access_demo/guard.gd).
- 시작 버튼의 처리기를 두 자동 모드에서도 호출한다. Windows 자동 검사는 외부 마우스·키보드 입력을 보내지 않았으며 화면은 완료된 경로와 정지 외곽을 표시한다. 엔진 로그와 렌더러를 구분해 기록했다. [검증 장면](../../../tools/p05_access_demo/demo.gd).

## 실행 결과

| 실행 | 환경과 판정 | 증거 |
|---|---|---|
| Headless | Windows, Godot 4.7.2, display `headless`, 19/19, exit 0 | [결과 JSON](../../../tmp/p05-native-20261109/headless/Headless.json) · [실행 명령](../../../tmp/p05-native-20261109/headless/Headless.command.json) · [종료값](../../../tmp/p05-native-20261109/headless/Headless.exit.txt) |
| WindowsAuto | Windows display, Intel Arc 130V, 1050×760, 19/19, exit 0. 두 번의 프레임 그리기 완료 후 화면을 읽어 PNG 저장 | [결과 JSON](../../../tmp/p05-native-20261109/windows/WindowsAuto.json) · [실행 명령](../../../tmp/p05-native-20261109/windows/WindowsAuto.command.json) · [종료값](../../../tmp/p05-native-20261109/windows/WindowsAuto.exit.txt) · [렌더 프레임](../../../tmp/p05-native-20261109/windows/P05-Windows-frame.png) |

두 실행의 19개 검사 행이 정확히 일치했다. 양성 12개는 정면·우회의 E 진입, A/B 정지와 이탈, C 접근, 명시 복귀 후 E 철수, R 진입과 C 접근이다. 부정·복구 7개는 다음과 같다.

| 사례 | 관측 |
|---|---|
| 추종 편차 위반 | 두 번째 함대에만 (1.5,1.5)를 제안해 `tracking_budget`으로 거부. 두 함대 위치·heading·경로·틱·진행·방문·배치 상태 전부 동일. |
| 허용 속도 초과 | 두 번째 함대에만 진행 방향 추가 이동을 제안해 `step_speed`로 거부. 전체 이전 상태 보존. |
| 유효 재시도 | 같은 그룹에서 정상 이동을 재시도하자 한 틱 진행되고 두 위치가 바뀜. |
| J–A 목 폭 부족 | 경유점을 유지한 상태에서 연속 swept 외곽이 폭 120 구간에 걸려 `throat_clearance`로 거부. 실패한 한 걸음 전 상태 보존. |
| A 서비스 접근 불가 | 정면의 A 정지까지 이동한 뒤 `service_inaccessible`로 거부. 전체 이전 상태 보존. |
| 서비스 실패 후 항로 유지 | A 서비스 거부 뒤 같은 정면 항로에서 다음 구간 진행 성공. |
| 새 시작 거부 | 지원 밖 경로가 `unknown_route`로 거부되고 활성 상태 전부 동일. |

거부 다섯 건은 두 결과 JSON에 `transaction.before/after` 전체를 포함하며 각 객체를 대조했다. 이번 Windows 화면에는 검사 19/19, 세 항로와 목표 접근 정지 외곽이 보인다. 엔진은 각 실행에서 프로젝트 파일을 전용 임시 디렉터리로 복사해 사용했다. [격리 실행](../../../tools/p05_access_demo/run.ps1).

## 재현 기준

| 항목 | SHA-256 |
|---|---|
| [이동 가드](../../../tools/p05_access_demo/guard.gd) | `47de8be4449084014b80d6180a1ea6bd52c37105bfa72eb69229bd4e012900eb` |
| [검증 장면 처리기](../../../tools/p05_access_demo/demo.gd) | `d44e5a562115d23e7a989bcb3de2276cb6dd37c25fe88229e51f925a3bd7c975` |
| [manifest 생성기](../../../tools/p05_access_demo/build_manifest.py) | `d06e755cab5a1784133b11a4e148f185734a372f3ad4c536a0fbfacf9bb018c8` |
| [Windows 실행 manifest](../../../tmp/p05-native-20261109/windows/WindowsAuto.manifest.json) / [Headless 실행 manifest](../../../tmp/p05-native-20261109/headless/Headless.manifest.json) | `223eb53c920bd7bd8662962c0196ee2e02056962636ed4306725439d94c48ecd` |
| [Windows 프레임](../../../tmp/p05-native-20261109/windows/P05-Windows-frame.png) | `5e0c4f01536605b5fb7897686f2dc9692b5e703498c403c912c6a4587f2c80d6` |

제품 이관은 P02 실제 PC 시작·표시·결산과 P03 명령·전투 상태의 소유 경계에서 수행한다. P07의 가동 보급·시간 증원·목표 달성·철수 정책을 연결하고, 같은 수용 사례를 제품에서 다시 실행해야 한다.
