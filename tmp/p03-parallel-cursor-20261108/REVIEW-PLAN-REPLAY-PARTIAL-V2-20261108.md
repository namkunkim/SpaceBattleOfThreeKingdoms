# P03 fresh replay 부분 처리 경계 v2 독립 계획 재심사

2026-11-08. **PASS — v2 계획에 한함.** 심사 대상 SHA-256은 `186D68D56785176DBF19AEC9A4CD3A851623759E8F073B876400D7963B92786A`다. v2 절을 우선 적용한다.

- 기존 입력 SHA-256 19/19와 추가 P02 fixture·oracle 입력 6/6을 재계산해 일치했다. 기존 무명령 oracle의 자연 종료 summary.tick 및 end_tick 1221, clock_ms 및 end_ms 122050, over=true와 terminal battle_end를 확인했다. F=17999, max_ticks=18000이다. A를 넣은 oracle은 계획 통과 후 별도 원문으로 검증·동결하며, 예상과 다르면 스펙 재심사다.
- 네 이름에 각 8개 고유 단언, 합계 32개를 사전등록했다. 실패 및 단언 누락·중복은 runner 비정상 종료를 요구하며, 외부 게이트도 실제 exit, 마커, 고정 분모, 진단 및 입력 SHA로 독립 판정한다.
- 네 번째 검사는 `helper_close_error`로 정정되어 내부 `_play_and_close`의 정리와 오류 DTO 범위를 검증한다. 시나리오 4의 일부 DTO 단언이 중복되므로 32는 단언 실행 수다. 독립 시나리오 수는 4다.

심사는 `/root/p03_review`가 수행했다. 사용자 인정 배정 근거는 명시적 `gpt-6.1-sol` 지정과 구현 담당과 별개인 에이전트 ID이며 실제 서빙 모델은 별도 미검증이다. 심사에서 코드를 작성하거나 엔진을 실행하지 않았다. 전용 tmp 범위, 입력·dirty 보존, K=6 및 환경/사용량 제한 즉시 중단과 별도 5-b를 적용한다. P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED를 유지한다.
