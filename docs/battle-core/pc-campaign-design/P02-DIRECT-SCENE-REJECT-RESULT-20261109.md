# P02 직접 출격 장면 전환 거절 결과

2026-11-09 KST · 기존 직접 출격의 즉시 전환 오류 복구 한정 수용. 전체 P02/첫 PC 캠페인/I01/I01b **NOT_READY**, 외부 저장 스키마 **UNCLASSIFIED**.

WorldLink는 기존처럼 전환 호출 전에 전투 명세와 선택값을 게시하고, 장면 전환이 즉시 오류를 반환하면 기존 brief/outcome 참조와 난이도·모드 값을 되돌린다. WorldMap은 출격 직전의 browse 또는 result, 기존 brief와 표시·입력·지역 소유 표현을 복구한다. 결산 카드에서 시작한 경우 같은 결산 객체와 다시 출격 버튼이 남고 오류가 표시된다. 새 결산 게시나 결산 타이머를 만들지 않는다. 장면이 수락된 뒤의 내부 준비 실패와 귀환은 별도 경계다. [제품 변경](../../../tmp/p02-pc-next-20261109/apply-verified-legacy/production-applied.diff).

승인된 세 번째 격리 실행은 before/after 각 7개, 총 14개 lane을 완료했다. 실제 누락 씬 로더 오류는 각 reject에서 4쌍이며, 원본은 예상 28개 실패를 포함한 45개 행 전체를 기록했다. 후보는 45/45와 ERR_CANT_OPEN 반환을 확인했다. 정상 왕복 C1–C4, 자동 해결 14/14 및 취소 15/15, 타이틀·재시작은 양쪽을 통과했다. 자동 결산 fingerprint와 결산 1회도 일치했다. 14개 실제 root 종료와 Job active 0을 확인했다. 원본 reject만 예상 exit 1, 나머지는 exit 0이다. [실행 기록](../../../tmp/p02-pc-next-20261109/ATTEMPT-03-RESULT.md) · [독립 5-b](../../../tmp/p02-pc-next-20261109/REVIEW-5B-INDEPENDENT.md).

적용한 두 제품 파일은 격리 after 실행 입력 및 검토 후보와 바이트 단위로 일치한다. 적용 후 Godot 실행과 실제 Windows 입력은 미수행이다. 정상 왕복의 두 번째 호출은 같은 프레임의 handler 재진입이며, 끝맺음은 테스트의 강제 종료다. PC 자연 종료나 캠페인 operation의 수용 근거로 집계하지 않는다. 원본 테스트 overlay는 적용하지 않았다. [원본 반영](../../../tmp/p02-pc-next-20261109/apply-verified-legacy/APPLY-RESULT.md) · [적용 후 독립 검토](../../../tmp/p02-pc-next-20261109/REVIEW-POST-APPLY-INDEPENDENT.md).

첫 시도는 편집기 접기 설정 검사에서, 두 번째는 테스트가 이미 분리된 버튼에 보낸 인위 신호의 오디오 오류에서 중단됐다. 이 조각은 3/6회 사용했다. PC0 2/2 소진과 별도 여덟째 K6 미사용을 유지한다. [첫 실패](../../../tmp/p02-pc-next-20261109/ATTEMPT-01-RESULT.md) · [두 번째 실패](../../../tmp/p02-pc-next-20261109/ATTEMPT-02-RESULT.md).
