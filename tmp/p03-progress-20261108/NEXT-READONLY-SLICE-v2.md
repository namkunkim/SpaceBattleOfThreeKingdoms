# P03 책임표 계획 보완

[읽기 전용 계획](NEXT-READONLY-SLICE.md)에 다음 확인을 추가한다. fresh owner가 먼저 생성되지만, 전체 명령 배열의 구조·순서 검증이 끝나야 첫 queue가 호출된다. 각 tick에서 모든 예정 행 enqueue→advance 성공→지역 consumed 갱신→raw drain→summary를 구분한다. 종료 시 미소비 행은 error/path로 반환하고 성공 DTO는 CLI 출력 함수에 전달되지 않는다. 내부 fresh owner 정리와 외부 효과·디스크/소비자 원자성은 다른 주장이다. 입력 source SHA, exact 행 근거와 공개 결과/제한을 독립 대조한다.
