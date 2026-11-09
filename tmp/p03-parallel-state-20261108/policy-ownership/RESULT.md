# P03 정책·소유권 35셀 대조 결과

[원장](POLICY-LEDGER.json)은 기준 정책 필요 24개, 미분류 11개를 모두 연결했다. 기존 제한 결정과 관측, 추가 조사, 사용자 선택, 현재 호출·미래 제안·공동 인수 소유권을 구분했다. UI 관련 8셀은 실제 호출·표시 증거를 먼저 확보하도록 선택을 유보했다. 전수란 동결한 경계표의 35개 셀을 뜻한다. 임의의 동적 호출, 외부 앱 및 전체 운영 계약의 완전성은 미검증이다.

정책 선택 축은 host/owner 권위, 외부 전달 보장, 운영 복원 지원, 활성 모듈, 접촉 표시 권위, filtered 위치 필드의 6개다. 접촉 표시 권위와 DTO 허용 필드는 동시에 각기 선택할 수 있는 독립 축이다. 모든 선택지는 미채택이다. [P02 소유권 대조](P02-OWNERSHIP.md)는 제한 worker/replay/viewer, legacy 결산·준비 실패, 제품 operation의 미완 경계를 구분한다. 여덟째 K6 계약 일부의 계획 수용과 prepared V2 실행 보류가 최신 읽기 범위에 포함되며 제품 수용으로 분류하지 않았다.

| 사례 | 실제 exit | 결과 |
|---|---:|---|
| normal | 0 | 35개 exact tuple, 기준 분모, 6개 미채택 선택 축 및 근거 필드 일치 |
| row_omission | 1 | POST_FILTERED_DRAIN/ui_publish/UNCLASSIFIED 한 셀만 누락 |
| eighth_misclassification | 1 | 미완 P02 eighth의 CONTRACT_ACCEPTED 승격 한 건 탐지 |
| missing_anchor | 2 | absent.md 경로 오류, 비교 출력 없음 |

[실제 suite](attempt-01/suite.json) exit 0, 자식 4/4. 5a는 구조·근거 파일 존재와 지정 차집합을 확인했다. 선택지의 의미와 원문 적합성은 독립 사후 검토 범위다. manifest SHA256 4686403a2d90e83935dad1a1171ebe7238019868e81f1a669dff9aacad6f65ba. 정본/증거/생산 경로 37개 포함 전체 동결 입력 48개와 HEAD가 실행 전후 일치했다. Git 상태 차이 10행은 모두 전용 경로이며 P02 및 외부 동시 경로 차이 0이었다. [manifest](manifest.json) · [Git 대조](attempt-01/git-comparison.json). 상태 비교는 전체 dirty 바이트 감사와 별개다.

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 생산 코드, 공유 체크리스트, 운영 정책은 변경하지 않았다. 독립 사후 5b 대기.
