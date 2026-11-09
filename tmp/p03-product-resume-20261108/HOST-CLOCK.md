# P03 호스트 첫 프레임 경계

소스 대조 + 독립 산술 oracle. 제품 실행 없음.

acc=0 delta=0.05 speed=1 hz=10 ticks=0 remainder=0.5
acc=0.75 delta=0.05 speed=1 hz=10 ticks=1 remainder=0.25

호스트 _process는 clock.advance(delta)만큼 sim.step하고 clock.alpha()를 보간에 사용한다. 새 전장 게시는 새 clock을 만든다. update_sim은 별도 _sim_acc_clock을 쓴다. 같은 core tick/clock에서도 누산기 초기화 여부가 첫 프레임 step 수를 바꾼다. 첫 프레임 등가성이 요구되면 실제 프레임 clock phase를 보존·복원하거나 명시된 정렬 절차가 필요하다. 논리 tick 경계 재개가 계약이라면 phase 초기화를 별도 정책으로 정할 수 있다. tests/i01b_logical_clock.gd의 pause/부분 논리 tick 관측과 구분한다.
DFB9CD4A070995D9ACA44F77BF08CAB18AE87EB4C678A341CCDDC34C5A7FF74E C:\WorkSpace\SpaceBattleOfThreeKingdoms\core\battle\tick_clock.gd
604B79308D9B3DBAB84DCED32456A4F41B28686C8EEC748073D3816892CFFC5C C:\WorkSpace\SpaceBattleOfThreeKingdoms\scripts\FleetBattle3D.gd
FEBCBC625A32814B21AC60A10FCBA389928921044711FECB95A2ADA6DDAF8925 C:\WorkSpace\SpaceBattleOfThreeKingdoms\tests\i01b_logical_clock.gd
A32A0AD0645B181B9C00FF98E89022BB1D5682A13A66B6FD618B1D5A803AA7FB C:\WorkSpace\SpaceBattleOfThreeKingdoms\tmp\p03-host-responsibility-20261108\HOST-STATE-LEDGER.md

## 독립 정적 5-b 및 마감

Terra 검토자 별도 Python 산술: hz10, 배속1, delta .04에서 acc .25는 0틱, acc .75는 1틱이다. 별도 입력으로 같은 반례를 확인했다. 기존 core_rules 배속·정지·상한 검사와 i01b_logical_clock 부분 논리 틱은 제품 호스트의 잔여량 복원을 다루지 않는다.

작업자 gpt-6.1-sol, 세션 01a1ba53-9472-7613-bdd4-ef1aef873ef0, 19:29:57 KST. 독립 검토자 gpt-6.1-terra, 세션 01a1ba5e-d163-7532-b9ae-3770d9c4ca04, 19:30:12 KST. 검증 입력 4개 전후 SHA 일치. 제품 실행 없음. P02 쓰기 창과 호스트 재개 정책은 미결. Supply 자연 혼합 미판정. P03/I01/I01b/A04~A06 NOT_READY.
