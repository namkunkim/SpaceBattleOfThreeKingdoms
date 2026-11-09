# P03 표시용 사건 packet 결과

2026-11-08 KST. 안개가 켜진 제한 fixture에서 **표시용 drain 전에 저장한 A는 raw 사건 4개를 복원했고, 표시용 drain 직후의 B는 숨긴 사건까지 소진된 빈 큐를 복원했다.** 실제 추가 advance 뒤 A로 복원해 raw 전부를 읽었고, A를 다시 복원했을 때 반대쪽 진영의 표시 결과 2개를 정확히 확인했다. raw·side0·side1 각각 별개의 native BattleSim과 수기 spawn/stop 순서·ID·타입·payload를 비교했다. 같은 handle의 새 sim과 contacts/clock, packet 불변을 확인했다. [독립 5-b](REVIEW-5B-attempt-01.md)

attempt-01/K6 실제 Godot exit0, 명명4·47 단언. 정본 Script/클래스 맵, console/본체 및 실행 입력47 전후 SHA 일치, 오류/경고/누수 진단0. 시작 dirty 16800 재해시 누락0, P02 작업 폴더의 audit 스크립트 변경1과 신규 17을 분리했다. 실행 입력 현재 drift0. status는 동시 변동이 있었다. 전체 diff-check의 기존 P2c exit2와 새 소유 경로 공백 검사 결과를 분리했다. [실제 실행](attempt-01/run.json) · [보존 감사](preservation.json)

전체 P03/I01/I01b/A04~A06은 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED다. 이 결과는 동일 owner의 packet 시점 큐 복원이며 외부 표시/효과의 ack·dedup, 동시 호출, 제품 호스트 게시 또는 모든 안개 상태를 검증하지 않는다.
