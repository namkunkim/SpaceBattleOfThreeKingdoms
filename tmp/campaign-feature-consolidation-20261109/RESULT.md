# 캠페인 feature 통합 기록

수용된 캠페인 후속 구현 27개 경로를 codex/feature-i01b-not_remove의 25879eedd22bcf9c7c258630cfef8dd23a991175에 통합했다. 부모는 0be09755b70378286105972f35ac5b7031715664이며 독립 5b에서 수용한 트리 6165f3756ac21b1a6d1d8004b48e6b2cdb7fe5fa와 같다.

- P02 직접 출격 거절, 천하 복귀 거절과 화면 안내, 직접 출격 난이도 적용을 포함한다. 난이도 원본은 focused-edges-01 사후 독립 심사 SHA와 일치했다.
- P03 typed Dictionary 비교와 활성 DecisionBoard 복원 거부, 기존 P2b/P2c 및 제한 활성 교체 회귀 코드를 포함한다. 독립 수용 원문과 SHA는 validation-evidence.json에 기록했다.
- 후보 트리에서 추출한 P05 접근 검증은 실제 Godot 4.7.2 headless 19/19, exit 0, 오류·경고 0이다. 최종 게임 화면과 자연 전투 종료는 통합 실행하지 않았다. P05 전용 검증은 제품 통합 완료로 보지 않는다.
- 선택 범위와 다른 tracked 변경 43경로의 작업 바이트 SHA 및 열거된 기존 미추적 파일의 보존을 확인했다. 별도 UI·HTML·설정·공유 증거와 첫 작전 미완료 후보는 커밋에서 분리했다.
- 체크아웃되지 않은 조상 로컬 참조 codex/i01a-operation-config를 git branch -d로 정리했다. 커밋 8292805143f4561a4f5258d40b7b94adf4ff5802는 main과 통합 feature 역사에 보존됐다. 별도 PC 페이싱 실험 브랜치와 작업트리는 이번 통합 범위와 별도로 유지했다. 로컬 커밋이며 푸시는 미실행이다.

전체 첫 PC 캠페인 및 저장·재개는 미완료다. I01/I01b/A04~A06 NOT_READY, 외부 저장 스키마 UNCLASSIFIED.
