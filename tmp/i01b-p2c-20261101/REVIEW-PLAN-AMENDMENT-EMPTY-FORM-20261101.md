# P2c F01 보완 1~3 독립 계획 심사

2026-11-01 KST / **최소 보완 계획 수용**. 이는 구현 결과의 5-b 수용이 아니다.

검토자는 `/root/independent_review` (`gpt-6-astra`), 구현 비참여다. 대상은 `tmp/i01b-p2c-resume-20261101/PLAN-AMENDMENT-EMPTY-FORM.md`의 first/last 거부·새 OUT 보강본이다. 선행 반려는 같은 폴더의 `REVIEW-5B-REJECT-EMPTY-FORM-20261101.md`이며 그대로 유지한다.

계획은 실제 소비자의 유일한 누락 분모 조건인 fleet.form nonempty를 복원 전량 검사에 추가한다. 기존 typed Array/Vector2·유한값·값/순서 보존을 유지하며 정상 route/form_t 빈 배열을 거부하지 않는다. 임의 형태/길이 상수나 자동 복구를 도입하지 않아 범위가 적절하다.

첫/마지막 fleet의 typed clear를 서로 다른 명명 거부로 검사하고 `fleet_empty_form`, owner 미반환, source·packet·정상 prepare로 만든 기존 owner의 독립 typed oracle 불변을 확인한다. 단순 첫 함대 한 사례보다 뒤늦은 실패 원자성까지 직접 검증하며, 기존 43거부를 유지한 45 완결 guard가 계획과 일치한다. 정상 70사례와 projectile suffix는 기존 양성 대조로 충분하다.

생산 변경은 P2c helper의 최소 guard, 검사 변경은 두 반례·불변/오류명 검사·완결 수·신규 OUT에 한정한다. 기존 core/data/P2b helper/allowlist/skip을 변경하지 않는다. attempt5 사전 SHA·정본 class cache 유지와 원문 진단 확인, core/data/service 최소3회귀, 나머지4 정본 회귀의 소스·입력 SHA 연속성 검토는 이 변경에 충분하다. 불일치나 새 오류가 생기면 해당 영향을 추가 검사한다. editor import는 필요하지 않다.

K6 중 현재4회, 예정5회와 별도 probe2회 구분을 유지한다. 새 OUT/스냅샷으로 옛 증거를 보존하고, 최종3660/source35/격리77 감사 및 허용 문서 역대조 뒤 별도 최종5-b로 돌아온다. 전체 I01/I01b/A04~A06 NOT_READY와 외부 schema UNCLASSIFIED 유지. 이 계획 수용은 후속 통합 구현이나 commit/push/merge 승인이 아니다.
