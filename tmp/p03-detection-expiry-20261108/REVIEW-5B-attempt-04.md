# P03 접촉 만료 좌표 독립 5-b

2026-11-08. **제한 관측 수용: CURRENT_POS_OBSERVED**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인이 아니다. 심사자는 구현에 참여하지 않았다.

attempt-04 actual Godot exit0, 3명명/2461 단언(반복 advance 및 drain 포함), 오류·경고·누수0, Job 총2/active0. console/실제 본체·class map·source/fixture를 포함한 48 입력의 전후 및 현재 SHA 독립 재계산 차이0, runner snapshot 동일을 확인했다. 앞선 위치 전제 실패 01/03과 parse 실패 02는 보존됐다.

테스트가 첫 확인 뒤 foe pos와 home을 숨은 (2800,1800)으로 직접 옮긴 제한 fixture에서 tick2410의 살아 있는 lost 접촉은 seen1·마지막 공개 위치 (625,500)이고 projection도 그 위치였다. 정상 평가의 tick2411 만료 후 해당 contact는 제거되지만 raw 및 side0의 `contact` none 사건 pos는 실제 숨은 (2800,1800), side1의 해당 contact 사건은 없다. raw·side0·side1 독립 native 세 인스턴스와 owner를 비교했고, 만료 직전 packet을 복원한 뒤 같은 단일 advance로 raw/side0 결과를 재현했다. 이 테스트 위치 조작은 정상 플레이 이동 재현이 아니다.

이 관측은 표시용 사건 payload가 이 조건에서 숨은 현재 위치를 포함한다는 사실이다. 실제 UI가 그 좌표를 표시·활용하는지, 공개 정책이나 보안 위반 여부는 확인하지 않았고 별도 소유자 판단·검증이 필요하다. 공유 코드 수정 없이 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED 및 Dictionary metadata MISMATCH를 유지한다. 보존·패키지는 별도 closeout이다.
