# 캠페인 적용 통합 체크리스트

2026-11-21 기준. 캠페인 적용의 현재 상태와 남은 작업은 이 문서에서만 조회·갱신한다. 기존 캠페인 적용 체크리스트와 이관서는 검증 근거로 보관한다.

- [ ] **O07 구조 공적 릴리스 확인.** 완료 결산을 열어 구조 공적 1건 표시를 확인한다.
  - **O07 구조 공적 릴리스 전경 확인 대기.** 원격 [main ac26e618](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/commit/ac26e618d8e2785bf579bb66abbfaa1eed9092c9)의 Windows 릴리스 빌드, 운영 슬롯 CLI 교체, 새 프로세스의 공개 6틱 정지 복원과 보호 파일 SHA 보존은 독립 검토까지 통과했다. 완료 결산의 구조 공적 표시는 격리 소스 후보에서 통과했으며 릴리스 전경에서는 사용자 입력 중단 전까지 확인되지 않았다. 같은 릴리스와 격리 완료 프로필로 결산을 열어 공적 1건 표시만 확인하면 재개 조건이 충족된다. [릴리스 빌드](F:/WorkSpace/Campaign-Orchestration/O07-Lantern-main-release-20261121/release-output.json) · [운영 복구](F:/WorkSpace/Campaign-Orchestration/O07-Lantern-main-release-20261121/release-operational-restore.json) · [공개 복원](F:/WorkSpace/Campaign-Orchestration/O07-Lantern-main-release-20261121/release-foreground-active.json)
- [ ] **P05·P06·P07 확장.** 일반 선체·진형과 추가 작전 규칙을 검증하고 후속 작전 승계 및 A05 리플레이·A06 저장/복원 종합 검증을 마친다. 제한 FX-G 리플레이의 결산 데이터 누락도 확인한다.
- [ ] **P09 실제 장치 청취.** Windows 공개 적벽 v1을 지정 출력 장치에서 실행해 종료 직전 배경음과 종료 후 3초를 확인하고 기록한다.
- [ ] **P08·P09·O07 종합 인수.** Windows 1600×900 대표 플레이·성능을 종합 판정하고, 설정·지도 효과음과 배경음악의 전경 종료 및 전체 TRACE를 검증한다. 운영 전환과 외부 지급을 인수한다. 독립 Windows 호스트 두 대 전환과 실기기 전원 차단 시험은 이번 마감 범위에서 제외한다.

범위와 판정 근거는 [원격 main 기준 문서](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/c5af94ba400e145d11bfabb394212f8b19049a4d/docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md)를 참조한다.
