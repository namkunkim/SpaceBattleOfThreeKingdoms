# P03 제한 owner 공개 복원 거부 검증 계획

상태는 독립 계획 심사 대기. 작업자의 gpt-6.1-sol은 부모가 세션 rollout의 turn_context로 확인했다. 실행 전 해당 실행자의 실제 모델을 다시 확인한다. Astra, 모델 확인 불가, 사용량 제한이면 중단하고 보고한다.

기존 직접 생성은 표준 적벽 자동 편성의 DecisionBoard 생성만 관측했다. 기존 제한 adapter 검증은 create 거부만 확인했다. 이번 조각은 이미 진행 중인 제한 owner의 공개 restore_completed에서 같은 종류의 scenario 입력 거부가 기존 상태를 보존하는지 확인한다. 선행 강제 주입 반례, 제품 호스트와 owner 연결, 운영 정책, UI 게시와 외부 효과 원자성은 열린 상태다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.

## 인수 조건

- [ ] 기존 제한 PoC fixture로 동일 seed, Hz, profile, controls의 시험 owner와 무개입 대조 owner를 만든다. 공개 명령과 advance로 tick을 양수로 만들고 미소비 이벤트와 pending 명령을 확보한다. 두 owner의 상태가 같고 두 배열이 모두 비어 있지 않음을 공개 observe/capture로 검사한다. fixture가 이 전제를 충족하지 않으면 테스트 실패로 남긴다.
- [ ] 공개 capture_completed의 유효한 패킷을 깊게 복제한 뒤, 후보 profile에 앞선 적벽 관측에서 사용한 비어 있지 않은 scenario만 추가한다. 그 키를 제거한 대조 복사본은 원본 패킷과 일치한다. 후보 입력의 직렬화 바이트를 호출 전에 저장한다. 직접 prepare 또는 adapter.create 호출로 이 시험의 공개 진입점을 대체하지 않는다.
- [ ] 준비된 시험 owner에 restore_completed를 1회 호출한다. 반환은 소스의 _fail 형태에 맞춘 정확한 unsupported_scenario 실패이고 owner 키가 없다. 후보 패킷 바이트는 동일하다. 시험 owner와 기존 sim의 객체 동일성 및 ready/idle을 확인한다. 객체 동일성과 busy 검사는 읽기 전용 내부 계측이다.
- [ ] 거부 직후 공개 capture로 이전 tick/clock, 순서 있는 pending 및 미소비 events, 그 외 캡처 상태가 모두 동일함을 확인한다. 대조 owner와도 같아야 한다. 비교 전에 drain 또는 advance를 호출하지 않는다.
- [ ] 두 owner에 동일한 후속 공개 issue와 advance를 수행한다. 양쪽 성공, tick 1 증가, pending 소진 및 기존 pending과 새 명령의 로그 반영이 각각 한 번이고 순서가 같음을 확인한다. 이후 공개 drain 결과 전체와 순서를 대조하고, 두 번째 drain이 비었음을 확인한다. 같은 무변경 패킷의 정상 복원은 새 거부 실험과 분리된 양성 대조에서 확인하고, restore가 성공하며 캡처 상태가 패킷과 일치하는지 확인한다.

## 작업과 게이트

계획 심사 수용 후 전용 owner-contract 경로에만 독립 probe, 실행 게이트와 기록을 작성한다. 기존 i01b_active_replace.gd는 부정 입력 및 후속 검증 패턴의 근거다. 기존 worker_probe.gd는 PoC fixture와 scenario 입력의 근거다. 두 파일 모두 읽기 전용이다. 기존 worker_gate.py와 windows_job.py의 프로세스 수명 및 원문 증거 처리 패턴을 재사용한다. 전용 .gdignore와 별도의 Godot 사용자 데이터 위치를 사용한다. 공유 프로젝트 import나 클래스 캐시 재생성이 필요하면 중단한다.

계획 기준선은 PLAN-HEAD.txt, PLAN-STATUS.txt와 stderr, PLAN-INPUT-SHA.json에 남겼다. Git status는 core.longpaths=true 및 전용 경로만 제외하는 동일 옵션으로 재수집한다. 동시 변경은 분리해 보고하고, 동결 입력 SHA나 HEAD가 달라지면 실행이나 수용을 중단한다. 입력 분모는 선행 70개 및 이번 계획의 근거 파일을 합친 80개다. 실행 직전 게이트에 실제 추가 의존성과 승인 계획·심사·probe·launcher의 SHA를 더하고 전후 비교한다. status 비교로 공유 트리 전체의 바이트 보존을 주장하지 않는다.

5-a는 검증된 Godot console 엔진으로 headless probe를 실행한다. 시도별 새 디렉터리에 명령, 실행한 probe 사본, 엔진 버전, 입출력 SHA, stdout/stderr 원문, 실제 종료 코드, 제한시간과 자식 종료를 기록한다. 30초 내 exit 0, 남은 자식 0, 오류·종료 누수 진단 0, 단일 기계 판독 결과와 인수 조건별 통과, HEAD/동결 입력 불변을 요구한다. 공유 git diff --check의 기존 진단은 보존하고 전용 신규 파일 공백은 별도로 검사한다. 실패 시 기존 증거를 보존한 채 최대 총 3회 시도한다.

5-b는 구현에 참여하지 않은 확인된 비 Astra 심사자가 원문 로그, fixture 전제, scenario 단독 차이, 정확한 오류와 객체/상태 보존, 무개입 후속 대조, 독립 재계산한 SHA를 검사한다. 계획과 구현의 범위 한계를 결과·체크리스트·인계에 기록하고 별도 closeout 판정을 받는다. 반려 시 스펙으로 되돌린다. 전용 경로 외 수정 및 새 worktree, branch, commit, push, merge는 작업 범위 밖이다.
