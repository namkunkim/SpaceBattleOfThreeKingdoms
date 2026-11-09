# PC0 Windows 직접 출전 기준선 · 실행 중단 인계

2026-11-09 · PC0 **미완료, 2/2회 소진**. 첫 PC 플레이와 제품 operation은 **NOT_READY**다. 이 HEAD legacy 기준선은 여덟째 공통 native 후보를 적용하지 않았다. 그 후보의 21행 및 미실행 K6 한 회는 별도다.

| 회차 | 관측된 종료 경계 |
|---|---|
| run01 | 격리 probe는 exit 0이었다. 임포트 중 감독기의 단일 Job 멤버 가드가 예외로 중단했다. 정리 active 0을 기록했지만 임포트 root exit 및 추가 멤버의 PID·이미지는 미확인이다. 제품을 시작하지 않았다. |
| run02 | 격리 probe와 임포트가 각각 root exit 0·Job active 0이었다. 보관한 임포트 자손 핸들 두 개의 종료를 확인했다. 제품 창은 생성됐으나 관측한 foreground HWND가 대상 창과 달랐다. 브리핑 단계 180초 상한에서 감독기가 소유 Job을 정리했다. 제품 root exit 125, active 0이었다. |

run02의 최초 CUA 창 조회·캡처는 운영자 기록상 약 710초 동안 막혔다. 감독기가 제품을 종료한 뒤 상위 작업자가 그 도구 호출을 중단했다. 사용자 ESC 입력이나 사용자 취소 기록은 없다. 화면 캡처, 액션 로그, 전투 trace 및 결과 전달 증거는 생성되지 않았다. 모든 OS 입력의 부재까지 독립 증명한 것은 아니며 전경 또는 CUA 문제의 원인은 미확정이다. 전투 명령·논리시계·자연 종료·결산은 미측정이다.

run02의 기록된 원본 user/cache 목록, 격리 project 목록, 보호 Git/P03/worker 목록은 각각 전후 SHA가 일치했다. 이는 기록된 목록의 두 시점 비교다. run01 부분 임포트와 recovery lock, 두 실행의 원문, 이전 전달 ZIP을 보존한다.

PC0의 승인된 두 회를 모두 사용했다. 재시도·예산 리셋은 없다. 다음 조율에서는 이 실패를 실제 제품 동작의 실패로 집계하지 않고 첫 PC 플레이의 별도 승인 조각과 입수 가능한 실제 Windows 입력·전경 경로를 독립적으로 검토한다. P05/P07 작전 계약, P03 상태 경계, 저장·재개 및 전체 P02 인수는 각각 별도 진행 상태를 따른다.

- [run01 결과](../../../tmp/p02-first-pc-20261109/PC0-TERMINAL-RUN-01-RESULT.md) · [run01 독립 심사](../../../tmp/p02-first-pc-20261109/REVIEW-PC0-RUN-01-INDEPENDENT.md)
- [run02 독립 심사](../../../tmp/p02-first-pc-20261109/REVIEW-PC0-RUN-02-INDEPENDENT.md) · [제품 프로세스 원문](../../../tmp/p02-first-pc-20261109/run-02/product.os.tsv) · [제품 로그](../../../tmp/p02-first-pc-20261109/run-02/product.log)
