# P03 활성 DecisionBoard 도달 경계 확인 계획

기준 HEAD fb660cea69207fd332e26128643007694910a253. Sol 담당. 독립 타 모델 계획 수용 후 전용 tmp/p03-parallel-active-20261108 안에만 fixture·실행 증거·결과를 작성한다. 공유 코어, 제품 호스트, 기존 증거, 작업 트리와 브랜치/커밋은 편집 대상에서 제외한다.

1. 기존 forced fixture attempt-02의 capture 정확 거부 및 restore 교체·모듈 소실은 선행 근거로 링크한다. 실제 제품 호출과 별도 분류한다.
2. production_battle_constructor. 3D 호스트의 적벽 profile 정의와 제품 로더로 생성한 프로필을 정본 BattleSim 생성자에 넘겨 DecisionBoard 활성 및 역참조를 검사한다. 시나리오 카드 데이터 원본과 프로필 경로를 동결한다. 직접 new 실행은 호스트의 코어 생성 경계이며 실제 UI 게시·사용을 판정하지 않는다. 정상 종료 전 테스트가 만든 모듈 순환 참조를 정리한다.
3. restricted_owner_boundary. 동일 정상 제한 POC 입력의 adapter 생성, capture, one tick, same-context restore 및 Decisions 비활성을 확인한다. 제한 프로필에 적벽 정본 realtime_rules의 decision_cards를 담은 비어 있지 않은 scenario만 추가하고 adapter에서 unsupported_scenario 및 path profile, owner 없음, 입력 유지의 정확 거부를 확인한다. 이 최소 단일 변이는 제한 owner의 차단 원인을 분리한다. 적벽 전체 프로필의 첫 거부가 scenario라고 가정하지 않는다.
4. 호출 관계 조사. private owner의 ready 설정 및 _bindings(), DecisionBoard 할당 지점, 3D 호스트 생성·게시, production restore_completed 호출 위치를 추적한다. 추적한 경로의 부재와 잠재 동적/미구현 host 경로를 구분한다. 정책 원장에 제한 owner 활성 모듈 거부와 기존 owner의 restore 정책 적용 명문화 여부를 구분한다. 생산 수정은 요청 범위 밖이다.

검증은 전용 headless script와 기존 Windows Job 방식으로 실제 exit·timeout·Godot 진단·명명 결과 및 실행 전후 HEAD/경로·엔진·의존성 SHA를 남긴다. 5a 절차/출처, 5b 실행, closeout 독립 심사. 사용량 제한 즉시 보고 및 반복 금지. 전체 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
