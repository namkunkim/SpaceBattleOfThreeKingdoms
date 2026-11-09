# P02 전장 → 천하 전환 거절 복구 결과

2026-11-09 KST · 기존 즉시 로더 거절 복구 한정 수용 · P02 및 첫 PC 캠페인 **NOT_READY**.

`WorldLink.back_to_world`는 기존 Brief·Outcome 참조를 보관한다. WorldMap으로의 장면 전환 요청이 즉시 거절되면 두 참조를 복원하고 엔진 로그에 오류 코드를 남긴다. 현재 전장 화면과 기존 복귀 버튼을 그대로 사용할 수 있다. 성공 시 기존 WorldMap 초기화와 결산의 일회 전달을 사용한다.

격리 2회차에서 20개 실행과 순서가 지정된 210개 단언을 통과했다. 기준선 세 호출부에서 실제 로더 거절 3회로 출격 정보 손실을 재현했다. 후보는 결과·일시정지·최초 준비 실패 화면에서 각 2회, 총 6회의 실제 로더 거절과 경고 6건을 기록했다. 이전 Brief와 대기 Outcome 참조, 전장·sim·화면·상태 키를 보존했고, 씬 파일을 복구한 뒤 같은 전장과 버튼으로 재시도해 WorldMap에 도착했다. 완료 결과는 한 번 전달되고 중도·초기 실패는 결과 없이 복귀했다. [실행 결과](../../../tmp/p02-pc-next2-20261109/ATTEMPT-02-RESULT.md) · [독립 5-b](../../../tmp/p02-pc-next2-20261109/REVIEW-5B-INDEPENDENT.md)

1회차는 최초 준비 실패 검사에서 없는 상태 키를 읽어 중단했다. 2회차 검사는 키 존재와 Variant 값을 구분했고 정상 경로·기존 직접 출격 왕복을 대조했다. clean WorldLink의 기존 서막 편차로 양쪽 각각 exit 1 한 건, 다른 실행은 자연 root exit 0이었다. 모든 2회차 Job이 active 0으로 정리됐다. [1회차 기록](../../../tmp/p02-pc-next2-20261109/ATTEMPT-01-RESULT.md) · [2회차 원문 판정](../../../tmp/p02-pc-next2-20261109/attempt-02/results.json)

원본에는 `back_to_world` 한 함수만 반영했다. 승인 격리 후보와 원본 적용 바이트가 일치하고 직전 출격 hunk와 다른 동결 소스를 보존했다. 원본 반영 후 Godot은 미실행이다. 검증은 기존 버튼의 pressed signal과 강제 종료 fixture를 사용했다. Windows OS 입력과 자연 전투 종료는 미검증이며, 개발 로그 경고에 대응하는 사용자 화면 오류 표시는 제공하지 않는다. 제품 operation과 첫 PC는 미인수, PC0 2/2 소진, 별도 여덟째 K6 미실행이다. [적용 기록](../../../tmp/p02-pc-next2-20261109/apply-result.json) · [독립 적용 확인](../../../tmp/p02-pc-next2-20261109/REVIEW-POST-APPLY-INDEPENDENT.md)
