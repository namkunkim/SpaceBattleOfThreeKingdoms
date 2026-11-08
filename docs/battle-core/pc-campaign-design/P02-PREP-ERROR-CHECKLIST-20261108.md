# P02 전투 준비 실패 표시 전용 체크리스트

- [x] 지정 profile patch의 실패 반환과 로그를 유지하고 초기 화면·기존 전투 안내를 구분한다.
- [x] ally/foe 중립 문구, 반복 경고 한 개, 성공 시 제거, 최초 구형 출격 입력 차단을 확인했다.
- [x] 별도 Windows 마우스/Return 프로세스와 실제 종료·WorldMap 복귀를 대조했다. Escape 중단과 재개, 입력 교차를 보존했다.
- [x] 고정 후속 init_game 시작 행을 엄격 비교하고 변조 거절을 확인했다. 최초 randomize strict 7/8 불일치는 별도 기록이다.
- [x] 현재 제품 WorldMap의 자동 viewport 입력 완료/취소, 같은 resolver join과 결산 경계를 확인했다. WorldLink clean 기존 단일 실패와 returning 통과를 분리했다.
- [x] K1~K6 원문과 타임아웃, ObjectDB/리소스 진단, 현재 입력과 미귀속 차이를 보존했다. 독립 구현 5-b 한정 수용.
- [ ] 새 전달 ZIP 독립 마감. ZIP 생성 시점 상태는 마감 대기다.
- [ ] 전체 P02 인수, 적벽 및 제품 operation 지원과 제품 replay 연결. 외부 save schema UNCLASSIFIED.

[결과](P02-PREP-ERROR-RESULT-20261108.md) · [인계](SESSION-HANDOFF-P02-PREP-ERROR-20261108.md)
