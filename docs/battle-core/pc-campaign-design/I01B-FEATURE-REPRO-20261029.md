# I01b feature 재현·커밋 범위

2026-10-29 KST. 대상 feature 브랜치 이름에는 `not_remove`를 포함한다.

## 커밋 범위와 의존성

이 feature는 추격 fallback 데이터 정본화, I01b-P0 선언 재고 도구, P1 논리시계 검사, bundle 기하 데이터 분리, P2a B0 선택 상태 관측 및 결과/독립 심사 기록을 포함한다.

기하 데이터 분리의 동결 기준에는 HEAD 8292805에 없던 `BundleLayout.offsets`와 `slots`의 함대 수·전환 범위·전장 축소 처리가 이미 있었다. 검사된 실행 코드를 재현하기 위해 이 필수 선행 기능과 `tests/bundle_layout.gd`의 관련 회귀도 함께 포함한다. UI·브랜딩·다른 미커밋 변경은 포함하지 않는다. Android export 설정은 `data/bundle-layout.json` 포함 경로만 추가한다.

기존 결과 문서의 tmp 경로와 SHA는 당시 로컬 실행 증거의 위치이며 실행 당시 상태를 보존한다. 과거 9종 gate의 group/UI 결과를 이번 feature의 독립 checkout 검증으로 확장하지 않는다. 대량 raw 로그·관측 JSON·원본 전체 변경 동결본은 feature에 포함하지 않는다. 커밋된 검사로 새로운 실행 결과를 생성할 수 있다.

## 재현 준비

Godot 4.7.2로 프로젝트를 headless editor import한 뒤 아래 검사들을 별도 프로세스로 실행한다. `--path`에는 feature checkout 절대경로를 사용한다. 로그는 새 출력 폴더에 둔다.

```powershell
Set-Location '<feature checkout>'
New-Item -ItemType Directory -Force tmp/i01b-runtime-inventory-20261028 | Out-Null
& '<Godot console>' --headless --path '<feature checkout>' --editor --import
& '<Godot console>' --headless --path '<feature checkout>' --script tests/core_rules.gd
& '<Godot console>' --headless --path '<feature checkout>' --script tests/data_rules.gd
& '<Godot console>' --headless --path '<feature checkout>' --script tests/i01_operation_config.gd
& '<Godot console>' --headless --path '<feature checkout>' --script tests/i01b_logical_clock.gd
& '<Godot console>' --headless --path '<feature checkout>' --script tests/bundle_layout_data.gd
& '<Godot console>' --headless --path '<feature checkout>' --script tests/bundle_layout.gd
& '<Godot console>' --headless --path '<feature checkout>' --script tests/i01b_runtime_inventory.gd
& '<Godot console>' --headless --path '<feature checkout>' --script tests/detection_rules.gd
& '<Godot console>' --headless --path '<feature checkout>' --script tests/supply_rules.gd
```

P2a runner는 고정된 `res://tmp/i01b-runtime-inventory-20261028/observations.json`으로 출력하므로 위 mkdir가 필요하다. 실제 타입/순서 비교는 JSON 변환 전에 수행한다. stdout의 2352 checks는 파일 열기 검사를 포함하고 JSON의 2351은 그 직전 집계다. 종료 정리의 참조 해제는 관측 후 별도 처리다.

P0 재고 도구는 함께 보존한 `tmp/i01b-p0-20261028-state-inventory/source-freeze.json`의 21개 파일을 먼저 확인한다.

```powershell
& tools/scenario/audit_i01b_contract.ps1 -SourceRoot '<feature checkout>' -FreezePath tmp/i01b-p0-20261028-state-inventory/source-freeze.json -OutputPath tmp/i01b-runtime-inventory-20261028/source-inventory.json
```

SHA가 개행 정책 때문에 다르면 기존 freeze를 덮어쓰지 않는다. 해당 feature 커밋의 Git blob과 현재 21개 소스의 내용이 CRLF/LF 정규화 외에는 정확히 동일함을 먼저 확인한다. 이 확인을 통과한 경우에만 새 경로의 freeze 사본에 checkout 바이트 SHA를 기록하고 관측 HEAD와 개행 차이를 함께 명시한다. 실제 코드 차이는 새 freeze로 숨기지 않고 실패로 조사한다.

## 판정 경계

B0는 생성자 반환 직후이며 C0·호스트 초기화 완료가 아니다. 선택 필드 관측의 save_policy는 UNCLASSIFIED다. 실제 어댑터·저장/복원·후속 명령·제품 공간 및 전체 I01/I01b/A04~A06는 NOT_READY다. 실제 Android export와 GUI/사람 플레이를 이 feature의 headless 결과로 완료 표시하지 않는다. 종료 리소스/TRACE 진단은 PASS/실제 종료코드와 분리해 기록한다.
## feature 등록본의 실제 재검사 (2026-10-29)

원본의 다른 dirty 변경을 제외한 정확한 등록본 25경로와 HEAD 전체를 임시 파일 복사본으로 만든 뒤 검사했다(새 Git worktree 아님). 정식 권한 headless editor import exit0 후 core_rules/data_rules/i01_operation_config/i01b_logical_clock/bundle_layout_data/bundle_layout/i01b_runtime_inventory 7종이 모두 실제 종료코드0이었다. config326, clock60, geometry56, B0관측40·2352체크를 확인했다. P0도 함께 등록한 source-freeze를 수정 없이 사용해 exit0·19모듈/283선언/14앵커였다. 이 재검사에는 UI group·전체 전투/배포/사람 플레이를 포함하지 않았다.

data_rules와 bundle_layout의 종료 ObjectDB/resource 진단은 남았다. 첫 일반 권한 import의 AppData 설정쓰기 진단은 원문 보존하고 정식 권한 import로 재실행했다. 커밋 준비 전 동결한 원본 1091경로는 모두 SHA동일·누락0이었다. 실제 로그와 커밋 준비 감사는 로컬 `tmp/i01b-feature-push-20261029/`에 보존하며 대량 raw 자료는 이 feature에 싣지 않는다.