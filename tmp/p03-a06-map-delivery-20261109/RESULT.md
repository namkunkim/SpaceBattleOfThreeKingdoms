# A06 천하 지도 표시 완료 경계 결과

Godot headless 실제 WorldMap·WorldLink의 3개 이름/15개 단언이 최초 실행에서 통과했다. 실제 exit 0, K3 중 1회, engine diagnostics 0이다. 승인 계획과 독립 계획의 조기 이탈 조건을 사용했다.

| 사례 | 직접 관측 |
|---|---|
| 정상 유지 | 같은 `alliance_win` 테스트 DTO가 결과 카드로 게시되고 WorldLink 슬롯은 비워졌다. 결과가 유지되면 RGN-02가 `contested`에서 `wu`로 바뀌었다. |
| 조기 이탈 | 결과 게시를 관측한 뒤 6ms, 장면을 연 뒤 131ms에 실제 `천하 보기` 버튼의 연결된 pressed 신호를 보냈다. 결과 카드가 닫혀 browse로 바뀌었고 0.7초를 더 기다린 뒤에도 RGN-02는 `contested`였다. 슬롯은 이탈 전에 비어 있었다. |
| DTO 미재주입 재진입 | 기존 장면을 해제하고 새 WorldMap을 열었다. browse, outcome 없음, WorldLink 슬롯 비어 있음, RGN-02 `contested`를 확인했다. |

실행기는 canonical scene, autoload, screen, canvas 스크립트 경로와 world 원문의 매핑을 확인했다. console PID와 runtime 본체 PID를 구분했고 본체 경로와 전용 user data 디렉터리 확인이 통과했다. 실행 전후 HEAD와 입력 99개 SHA·크기가 일치했다. 실제 본체 PID, 명령과 출력은 `attempt-01/run.json`, `command.json`, stdout/stderr 원문에 있다. 입력 범위는 runner의 동결 목록에 한정된다.

이 결과는 현재 코드에서 슬롯 소비와 지도의 결과 색 상태 반영이 별도 경계라는 실행 증거다. 테스트 DTO로 결과 진입을 통제했다. 시험의 조기 이탈은 UI 버튼 신호를 headless에서 보낸 사례이며 실제 플레이어가 그 시간에 누르는 빈도, 화면 픽셀, 색 전환 애니메이션 완료 및 운영 지급·ACK·내구 저장·재전달은 검증하지 않았다. P02 공용 코드 변경 없음. 전체 P03 및 운영 A06은 NOT_READY, 외부 저장 스키마는 UNCLASSIFIED다.
