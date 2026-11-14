# H1 사건 경계 — 격리 헬퍼 검증 증거

2026-11-14. **격리 구현의 34/34 시험 기록과 독립 코드 검토를 수용한다. 제품 활성화, P06/P07 확장 완료 또는 기존 v1 저장 호환성 인수는 아니다.** 이 커밋은 문서 증거만 추가한다. 증거 패키지 자체의 별도 독립 검토는 대기 중이다.

## 준비 계획과 기록 범위

`a2bcdac5a622da3babdaff27f6a2b6627b210f74`에서 깨끗한 F: 증거 작업 트리를 재사용했다. 원래 실행 산출물의 바이트와 정책 근거를 대조하고, 결과·실행 기록·비실행 텍스트 스냅숏을 이 폴더에 보존한다. 제품 소스, 체크리스트 상태, 설정, 저장 호환 쌍, 빌드·내보내기 설정은 변경하지 않는다. 커밋 후 다른 검토자가 패키지 범위와 해시를 확인한다.

원본 위치는 `F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P07-h1-event-boundaries-20261114-01`이다. 원래 계획은 [SOURCE-PLAN.md](SOURCE-PLAN.md), 원본에서 보존한 파일 14개의 경로·SHA-256과 범위는 [manifest.json](manifest.json)에 있다. `.gitattributes`는 이 폴더의 증거 바이트에 줄바꿈 변환을 적용하지 않도록 한다. `snapshots/*.txt`는 검토용 텍스트이며 활성 GDScript 파일이 아니다.

## 검증 결과와 독립 검토

- [result.json](result.json): 관측 34개, 실패 0, 모든 사례의 입력 불변 확인. 31개 고정 경계 사례 + 비사전 입력 2개 + 반환 사전 변경 후 다음 제안과 입력의 보존 1개다.
- [engine.log](engine.log), [process.json](process.json), [stderr.log](stderr.log): Godot `4.7.2.stable.official.ed1daf0bf`, 실행기 종료 0, timeout false, 엔진 진단 없음, 표준 오류 0바이트. 실행기 PID 5024와 엔진 보고 PID 15556은 별도로 기록돼 있다.
- [invocation.json](invocation.json): 원래 2026-11-14 08:29:43 UTC 실행의 인수·실행 파일 해시·격리 환경 경로. 이 문서 준비나 독립 코드 검토 과정에서 엔진 시험을 재실행하지 않았다.
- [oracle-freeze.json](oracle-freeze.json)은 원래 계획과 오라클의 고정 해시 기록이다. [오라클 텍스트](snapshots/h1_boundary_oracle.gd.txt)와 [실행 하네스 텍스트](snapshots/h1_boundary_runner.gd.txt)를 함께 보존한다. 동결 파일 안의 절대 경로는 원본 위치이며 현재 사본 대응은 manifest에 기록했다.
- 독립 검토자는 구현·오라클·하네스·34개 원시 결과를 대조했다. 같은 논리시각, 정수 범위, 잘못된 입력, 반환값 분리에 결함을 발견하지 않았다. 원본 해시 목록 17개와 정책 원문 해시 2개를 확인했다. 패키지 작성자는 이 코드 검토자와 같으므로 패키지를 자기 독립 승인한 것으로 보지 않는다.

검토한 [구현 텍스트](snapshots/h1_event_boundaries.gd.txt)의 SHA-256은 `af38f7509561ce665abf62c49889a8c5cf15601435993f6b44c7ca1af4c709ff`이다. [격리 프로젝트 설정](snapshots/project.godot.txt)도 보존했다. 새 검증이 필요하면 이 네 텍스트 사본을 별도 격리 프로젝트의 원래 경로로 복원하고 invocation의 환경·인수를 사용해야 한다. 이 증거 폴더를 제품 실행 경로에 연결하지 않는다.

## 승인된 정책과 구현 한계

근거는 [H1-EVENT-DECISION](../../../../H1-EVENT-DECISION.md)의 H1-E01/E02와 [H1-POLICY-DECISION](../../../../H1-POLICY-DECISION.md)의 H1-P02다. [reference-pins.json](reference-pins.json)은 정책 참조 커밋 `b40d2958a7331e11b17111704f93eab40a8da4bb`과 바이트 해시를 고정한다. [원래 사건 결정 사본](reference/H1-EVENT-DECISION.md), [원래 정책 결정 사본](reference/H1-POLICY-DECISION.md)을 보존했다. 두 정책의 Git 내용은 참조 커밋과 포장 기준 커밋 사이에 변하지 않았다. 정책 결정 문서의 작업 트리 CRLF 차이는 manifest에 별도 기록했고, 줄바꿈 정규화 후 텍스트가 같음을 확인했다.

| 승인된 경계 | 격리 헬퍼가 보고하는 범위 |
| --- | --- |
| 가동 완료가 출발과 같은 정확한 논리시각이면 지연 인정; 출발 뒤 소급 금지 | 완료시각이 원래 출발시각 이하일 때 외부에서 승인해 준 단일 지연량만 사용한다. 같은 바깥 tick의 다른 밀리초를 합치지 않는다. |
| 유효 지연만큼 공개 결산 시한도 연장; 시한과 같은 시각의 유효 목표·탈출 인정 | 출발과 시한에 같은 지연량을 더하고, 달성시각이 시한 이하인지 보고한다. |
| 목표·지휘 상실 동시에는 실패 우선; 명시 철수는 철수 성과만 | 정확한 동시 목표/상실에 실패 우선을 표시하며 명시 철수의 목표 성공을 금지한다. 다른 시각의 상실과 탈출/상실 관계는 별도 정책 필요로 표시한다. |

모든 시간·지연은 비음수 signed 64-bit 정수 밀리초다. 누락·추가 필드, 잘못된 자료형·종류·철수 플래그를 거부하며 덧셈 전에 두 결과의 오버플로를 차단한다. 7300ms·401ms·12000ms 등은 합성 시험 수치로서 Cross Counter 또는 제품 정책 수치가 아니다.

이 헬퍼는 분리된 제안만 반환한다. 전체 성공/실패 결산, 보상, 상태 커밋, 저장, 리플레이, RNG 또는 시나리오 기본값을 만들지 않는다. `objective_success_disallowed=false`는 성공 허가가 아니며 다른 정책 플래그와 작전 자격 확인이 필요하다.

## core/battle 반영을 보류하는 이유

`a2bcdac5`에서도 [first_operation_checkpoint.gd](../../../../../../../core/battle/first_operation_checkpoint.gd)의 `rules_digest()`는 `core/battle` 아래 모든 `.gd`를 재귀 수집한다. 호출자가 없는 새 파일도 기존 규칙 지문을 바꾼다. [first_operation_external_save.gd](../../../../../../../scripts/first_operation_external_save.gd)의 `_validate()`는 현재 지문과 엄격 비교하므로 기존 외부 저장이 `external_rules_mismatch`로 거부될 수 있다. 내부 호환 쌍만 갱신해서는 외부 저장 경로가 해결되지 않는다. Windows 빌드의 `replay_source_digests()`도 같은 소스 트리를 수집한다.

따라서 원래 `module.patch`를 제품 `core/battle`에 적용하지 않는다. 이 문서 전용 경로는 해당 지문 수집 밖이며 기준 커밋의 내보내기 설정도 `docs/*`를 제외한다. 이 커밋은 지문 수집 예외나 저장 정책을 새로 만들지 않는다.

## 별도로 남는 제품 조건

승인된 Cross Counter 설정, 권위 있는 가동·달성 자격, 같은 논리시각 사건 묶음의 완결 경계, 지연 효과 식별자와 한 번만 커밋되는 보장, 재확보·반복 지연 승인, 나머지 사건 순서, 제품 owner 연결, UI·저장 복원·리플레이 수용이 남는다. P06/P07 확장 및 A05/A06 전체 인수 상태를 변경하지 않는다. 기존 완료 검증을 반복하지 않았으며 Q67의 새 전투·밸런스 수용이나 1000시드 결과를 주장하지 않는다.
