# 다음 비충돌 후보 — 실제 호스트의 C0 준비/게시 책임표

2026-11-08 KST. 읽기 전용 제안. **독립 계획 수용 전 실행/구현 없음.** P02가 새로 검증한 실제 FleetBattle3D 준비/게시 경계를 P03의 C0·운영 Cn 및 실패 보존 계약과 대조한다. [P02 준비/게시 결과](../../docs/battle-core/pc-campaign-design/P02-HOST-PREP-RESULT-20261108.md)

정본 `scripts/FleetBattle3D.gd:93–116,137,172–227,329,456–473` 및 TickClock, UI 호출·WorldLink의 근거를 고정한다. 첫 write 전 candidate, 성공 publish의 core/view 상태, 기존 활성 유지, 명령·clock owner, G/vm/선택/카메라/trace, 초기 drain 및 게시·결산을 **core snapshot의 정본/파생/host 유지/재설정/미정**으로 나눈다. P02의 새 전투 준비 실패 검사를 운영 checkpoint 복원 실패 테스트로 집계하지 않는다.

최소 반례는 이미 활성 화면이 있는 상태에서 준비 실패, tick/clock이 다른 복원 후 기존 UI·두 host clock 유지 또는 재구성, raw/filtered 소비와 trace 및 외부 게시 중복이다. 정책 선택은 별도 공동 인수에 남긴다. 문서 SHA/출처/행 분모와 독립 대조만 수행하고 공통 파일은 읽기 전용으로 유지한다.
