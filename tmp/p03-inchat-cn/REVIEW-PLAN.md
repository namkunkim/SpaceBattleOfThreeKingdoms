# P03 owner/thread 경로 계획 독립 심사

판정: **조건부 수용**. 계획의 정적 조사 및 6개 경로/4개 비교 분모는 이 조사 목표에 적절하다. 구현 및 사후 결과를 승인한 것은 아니다. 아래 동결 조건을 조사 시작과 5a 전에 적용한다.

- 계획 원문 SHA-256 `334f6d5ad16ae6ba5e2ce2666e74639c05c219ff6f5f057d54e8f4443db31ca6`, 현재 HEAD `0be09755b70378286105972f35ac5b7031715664`. HEAD만으로 작업트리 내용을 고정할 수 없다. 실제 정규 경로별 SHA-256과 검색 명령·결과 및 파일 목록을 전후 보존하고 추가/삭제까지 비교하라. 변경 시 해당 실행을 실패 처리하라.
- 현재 `core/battle/operation_private_state.gd`는 이미 Git 수정 상태이며 SHA-256 `46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3`; P02 진행표도 수정 상태다. 이것은 기존 작업트리 상태이지 본 심사 변경이 아니다. 기존 변경을 되돌리거나 HEAD 버전으로 대체하지 말고, P02 동시 변경도 별도로 감지·보고하라. 본 심사는 지정된 이 파일 외 공유 파일을 쓰지 않았다. 전체 작업트리의 동시 타인 변경이 없었다고는 주장하지 않는다.
- 6/4는 조사 대상의 고정 분모이지 생산 호출자 전체가 6개라는 뜻이 아니다. `core/battle`, `scripts`, `scenes`, `hud`, `input`, `view`의 현재 `.gd`/`.tscn` 파일 전체와 검색어·제외 규칙을 명시하고, 경로 ID의 고유성 및 비교 쌍의 정확한 구성도 독립 oracle과 대조하라. 동적 호출, 범위 밖, 테스트를 제외한 정적 부재만 표시하라. 미발견을 전역 부재나 런타임 불가능으로 승격하지 말라.
- 실제 `scripts/world/auto_resolver.gd:155-164`의 `busy/worker`는 resolver의 두 thread 필드에 대한 시작 거절이다. `core/battle/operation_private_state.gd:165-167`의 `busy`는 해당 owner의 `_busy` guard다. 별개의 조건이며 worker busy만으로 같은 owner 경합을 주장할 수 없다. `_operation_mutex`가 취소 플래그를 보호하는 실제 범위와 owner `_busy`의 비원자적 접근을 구분하라. 관찰된 강제 설정과 자연 제품 경합 도달은 별도로 표기하라.
- 원문에서 제한 worker는 입력 복제 후 `Thread.start(_run_operation.bind(snapshot))`, worker 내부 `OperationAdapter.create`, owner close, 결과 반환을 갖는다(`auto_resolver.gd:155-183,199-213`). 이는 계획의 추적 지점이 타당함을 보여주지만 모든 별칭·간접 경로의 부재를 입증하지 않는다. raw host는 `scripts/FleetBattle3D.gd:306,324,491`을 출발점으로 하고 WorldLink 정규 경로는 `scripts/world_link.gd`다.
- 5a 음성 사례는 각각 독립 사본 하나의 단일 변이로 만들고 실제 프로세스 종료 코드 0/1/1/2, stdout/stderr, 변이 차집합과 전후 manifest를 보존하라. 존재하지 않는 근거의 2와 의미 오류의 1이 실제 구별되는지 사후 심사한다. 게이트 통과만으로 원문 추론의 진실성이나 자연 경합을 입증하지 않는다. K=3 및 한도 즉시 중단 조건을 유지한다.

심사 범위: 계획과 위 현재 소스 anchor, HEAD, 지정 핵심 파일 해시 및 Git 상태의 읽기 전용 확인. 실행·경쟁 실험·검증기 구현은 하지 않았다. 후속 산출물에 대한 독립 심사는 별도다.
