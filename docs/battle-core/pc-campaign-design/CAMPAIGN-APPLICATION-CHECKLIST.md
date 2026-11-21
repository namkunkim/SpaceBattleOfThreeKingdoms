# 캠페인 적용 통합 체크리스트

2026-11-21 기준. 캠페인 적용의 현재 상태와 남은 작업은 이 문서에서만 조회·갱신한다. 기존 캠페인 적용 체크리스트와 이관서는 검증 근거로 보관한다.

- [ ] **P05·P06·P07 확장.** 일반 선체·진형과 추가 작전 규칙을 검증하고 후속 작전 승계 및 A05 리플레이·A06 저장/복원 종합 검증을 마친다. 제한 FX-G 리플레이의 결산 데이터 누락도 확인한다.
  - **P06 A05/A06 공개 경로 종합 인수.** 제한 FX-G의 내부 영수증 재생과 Windows 릴리스의 열린 도약로 호위 단계 593틱 복원은 기존 검증을 재사용한다. 3D 정지 복원 수정은 F: 최종 후보에서 8/8·종료 0 및 독립 검토를 통과했다. 공개 불러오기로 593틱과 상태 지문을 2.012초 동안 유지하고, 계속 버튼 신호 후 첫 진행이 594틱임을 확인했다. 원본과 격리 저장은 그대로다. 한 파일 수정은 [main 3f913ee0](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/3f913ee0245e2df74103d8b3901fb1b8e1c476ff)에 반영했다. 수정된 Windows 릴리스의 패키지 지문과 공개 메뉴의 593틱 정지·계속 경계 인수가 남았다. 추가 작전은 승인 시 그 작전의 공개 호스트·리플레이와 저장 전후 상태·후속 명령만 인수한다. [정지 복원 검증 결과](F:/WorkSpace/Campaign-Orchestration/A06-OpenJump-pause-d8c9b76b-20261122/RESULTS.md)
- [ ] **P09 실제 장치 청취.** Windows 공개 적벽 v1을 지정 출력 장치에서 실행해 종료 직전 배경음과 종료 후 3초를 확인하고 기록한다.
- [ ] **P08·P09·O07 종합 인수.** Windows 1600×900 대표 플레이·성능을 종합 판정하고, 설정·지도 효과음과 배경음악의 전경 종료 및 전체 TRACE를 검증한다. 운영 전환과 외부 지급을 인수한다. 독립 Windows 호스트 두 대 전환과 실기기 전원 차단 시험은 이번 마감 범위에서 제외한다.

범위와 판정 근거는 [원격 main 기준 문서](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/c5af94ba400e145d11bfabb394212f8b19049a4d/docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md)를 참조한다.

제품 반영과 검증 근거는 [〈적벽 · 열린 도약로〉 반영 커밋](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/48c6383a66c8591a38ffaf75d6ccb072caba809c)과 [통합 검증 결과](F:/WorkSpace/Campaign-Orchestration/OpenJump-main-9551e385-20261121/RESULT.md)에 기록했다.
