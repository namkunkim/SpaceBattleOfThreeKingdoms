# 읽기 전용 선언 검사 5b

판정: **PASS (172개 선언 튜플의 제한된 누락 감지에 한함)**. 상태 원장 전체 및 런타임 복원은 이 PASS의 범위가 아니다.

- 별도 원문 추출로 oracle의 고유 172개를 대조했다: BattleState 28, Missile 10, Swarm 8, FleetState 121, TickClock 4, BattleRng 1. 파일·소속·이름 차집합은 양쪽 모두 0이다. 이는 수동 전수 검독이 아닌 별도 스크립트 대조다.
- manifest SHA가 별도 값과 일치하고, 13개 기록 입력과 Python 실행 파일의 현재 SHA가 manifest와 일치한다. suite 자체 기록 exit는 0이다.
- 일곱 자식의 기록 exit는 baseline 0, omission 1, rename 1, missing 2, nested 1, ignored 0, duplicate 2다. 각 stdout 차집합은 기대대로이며 두 입력 오류의 stdout은 비어 있다. nested는 Missile 10개 누락과 MissileProbe 10개 추가다. suite가 stderr 진단도 확인한다.
- 원본과 후보를 별도로 비교해 다섯 후보의 변형이 계획의 한 줄 삭제·교체·복제 또는 지정된 두 줄 추가와 일치함을 확인했다.
- 실행 전후 Git 상태 스냅샷의 차이는 전용 tmp 아래 새 산출물뿐이다. 이 스냅샷은 무시된 파일 등 Git이 표시하지 않는 모든 부수효과를 증명하지는 않는다. runner를 읽은 범위에서 prepare와 suite의 쓰기 대상은 전용 폴더다.

S1/S4의 책임 분류 원장은 미완이며 선언 집합 일치가 capture/restore 또는 동적 키의 안전성을 입증하지 않는다. 시간, RNG 값, 증원, 복원 원자성 및 활성 모듈 런타임 검증은 미실행이다. 원래 런타임 계획의 REJECT와 P03 NOT_READY는 유지한다.
