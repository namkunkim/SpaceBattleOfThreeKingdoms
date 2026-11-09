# 비제품 Godot Variant ABI 독립 시험 계획

검토용이며 실행 금지 상태다. 이 시험은 기존 제품 project, Godot cache, battle rule, fixture 및 오버레이를 참조하지 않는다. 독립 심사가 비제품 경계를 확인하고 파일시스템 및 Job 실행 경계가 입증된 후에만 시도한다. 제품 코드나 제품 fixture가 섞이면 중단한다. 이 프로젝트를 실행하더라도 C와 K6 제품 분모에는 편입하지 않는다.

## 고정 입력과 실행

variant-abi-review/minimal은 project.godot와 probe.gd 두 파일만 가진다. probe는 SceneTree 시작 시 각 Variant를 직렬화하고 10행을 출력한 뒤 종료한다. Scene·autoload·사용자 상호작용·입력·네트워크는 사용하지 않는다. Python comparator는 engine을 시작하지 않는다.

Source/engine/Python SHA, fresh sandbox 절대 경로, 복사 목적지, argv/env override 및 관측 경계는 variant-abi-review/ABI-DRAFT-MANIFEST.json에 고정했다. 기존 제품 cwd를 사용하지 않고 approved managed confinement 안에 fresh project/user/cache/temp/log directories를 만든다. Exact Windows environment whitelist, resolved user path 및 Job-owned runner를 실행 전에 확정해야 한다. log sink는 source project와 별도로 둔다. Headless script 실행 한 번만 포함한다. Editor/import/cache warmup을 하지 않는다. Job 정상 종료 포함 launch~exit 20초, owned drain 최대 5초, 출력을 합쳐 256KiB 제한이다. stdout/stderr 원문, engine PID/HANDLE/creation time, exit, output size, initial/final SHA를 기록한다. 기존 Godot이나 사용자 프로세스는 확인 목적의 활성화·정리 대상으로 삼지 않는다.

## 고정 분모와 판정

- 10행은 bool, 64-bit int, f32/f64 두 표현, StringName, Vector2, Array[int], Dictionary[int, Vector2], ordered int-key nested contact, distance-order 세 값이다.
- 독립 Python ABI comparator는 source-probe가 출력한 자료를 실제 Godot 실행 결과에서만 받는다. 기대 구조는 별도 함수에서 리터럴·타입 및 typed metadata로 정의한다. int64/f32/f64 헤더 플래그도 직접 확인한다. distance tuple은 (4096,1)과 (4096,0)의 동률 및 (4096,2)의 더 큰 거리다. 엔진이 다르게 산출하면 그 빌드가 모델과 다르다고 기록한다. 결과에 맞춰 기대를 변경하지 않는다.
- Exit 0, 비어 있는 stderr, canonical 10행과 원문 evidence가 모두 필요하다. parse/engine 오류, 20초 초과, closure 또는 환경 불일치, stream 누락/중복과 원문 PID 불확실은 실패다. 재시도 없이 실제 실패 기록을 보존한다.

시험이 성공해도 제품 서비스 context 전체의 타입·크기, 실제 projection과 동일 정책·좌표, 실제 C fixture 또는 21행 통과를 증명하지 않는다. 별도 watchdog W1~W5와 GUI 시험의 수용 근거로 대신 사용하지 않는다.
