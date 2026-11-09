# P03 실제 호스트 C0/Cn 읽기 대조 계획

2026-11-08 KST. **독립 계획 심사 대기, 문서만.** Sol 실행 / Terra 독립 심사 명시 배정, Astra 제외. [사용자 전용 진행표](../p03-progress-20261108/P03-CHECKLIST-REVISION-20261108.md)

P02 여섯째 조각의 정본 독립 마감은 `tmp/p02-sixth-20261108/closeout-v2/REVIEW-CLOSEOUT-INDEPENDENT.md`의 한정 수용이다. ZIP/결과/인계의 대기 표기는 생성 당시 상태이며 이전 closeout ZIP은 superseded다. 본 조사에서는 P02 제한 준비/게시 수용과 현 소스 SHA를 읽는다. 실제 운영 checkpoint 실패, HUD 오류, thread/callback/await, 외부 ack/지급 또는 적벽 operation을 검증했다고 해석하지 않는다. P02 chat idle에도 공유 owner 쓰기 이관 근거는 없다.

문서 5-a 분모를 8개 호스트 묶음으로 고정한다. **①** candidate의 입력·seed/편성/프로필과 publish 전 실패, **②** sim/roster 및 최초 controls·logical tick, **③** 두 TickClock과 pause/placement, **④** projection G와 vm/FX, **⑤** 선택/검사/그룹 및 카메라, **⑥** 즉시 명령과 trace/초기·후속 필터 drain, **⑦** deck/편성 화면 및 새 후보 성공·실패의 후속 호출, **⑧** WorldLink/BattleOutcome 게시·소비. 각 묶음에서 실제 타입/선언·갱신·소비·소유·C0/Cn capture/recompute/유지/reset 후보와 근거 source:line을 분리한다. 운영 복원의 유지/reset 정책은 정하지 않는다.

별도 반례는 A 기존 활성 상태에서 준비 실패와 실제 checkpoint 복원 실패의 분리, B tick2/clock150 및 서로 다른 host accumulator를 현재 clock/배속 규칙과 분리, C 동일 core packet의 raw/표시용 drain 뒤 trace·외부 게시가 이미 소비됐는지 분리다. 미실행 운영 반례를 P02 기존 증거로 재집계하지 않는다.

정본 host·TickClock·ViewModel·trace/호출자·WorldLink/결산 및 P02 closeout, H2/D04/I01 K06–08과 P03 제한 관측의 입력 SHA를 작성 전후 재해시한다. 8묶음·3반례, 원문 링크/refs/index, 정본 마감 상태를 검증하고 독립 내용 심사를 받는다. 전용 문서 폴더 외 쓰지 않는다. 새 문서 K3, 사용량 제한 즉시보고·반복 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
