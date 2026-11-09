# P03 호스트 참조 수명 정적 인계

범위: P03 전체 C0/Cn 목록 중 호스트 참조의 소유, 갱신, 소비. 제품 변경과 실행 없음. Detection 런타임 결과는 DETECTION-UI-CLOSEOUT.md의 통제된 재현 범위를 유지한다.

- 만료 시 BattleViewModel.apply는 이전 접촉을 dead로 표시하고, root를 해제 예약하고, by_id/fleets에서 제거한다 (view/battle_view_model.gd:200). FleetBattle3D._sync는 inspect 포인터를 직접 비우지 않는다 (scripts/FleetBattle3D.gd:545).
- 입력에서 적 조사와 아군 선택은 별도 (input/battle_input.gd:50,74). 이전 조사 참조가 남아도 레거시 라벨/정보 패널과 전술 오버레이/CommandDeck은 dead를 확인한다 (hud/fleet_labels.gd:57, hud/battle_hud.gd:301, hud/ui_kit/tactical_overlay.gd:79, hud/ui_kit/command_deck.gd:708). 재등장은 by_id에 새 뷰를 만들며 이전 inspect가 자동 재결합하지 않는다.
- 일반 선택 경로는 아군을 담고 my_sel이 dead를 걸러낸다 (scripts/FleetBattle3D.gd:796). 그룹은 ID로 저장되며 불러올 때 prune을 거친다 (input/battle_input.gd:182,208; input/selection_set.gd:37). 조사 참조를 공격 대상으로 직접 사용하는 경로는 검색 범위에서 확인되지 않았다.
- 5-a: 선언, 만료, 참조 소비 및 ID 재조회 대조. 실행 시 클릭·조사 상태를 직접 관찰한 결과로 확대하지 않는다. Supply 자연 혼합은 미판정.
검증 구간 SHA-256 일치 10개
E40B067A8F9AF61A85F5FBF88B4297962F770B0191442EDE543B69B0F49BCE07 C:\WorkSpace\SpaceBattleOfThreeKingdoms\view\battle_view_model.gd
604B79308D9B3DBAB84DCED32456A4F41B28686C8EEC748073D3816892CFFC5C C:\WorkSpace\SpaceBattleOfThreeKingdoms\scripts\FleetBattle3D.gd
B54A4B6CED538B0DF26160F7CE6FBA7E1126FAC3FD259F30BFA7B3A5954306C9 C:\WorkSpace\SpaceBattleOfThreeKingdoms\input\battle_input.gd
6C4CD57AFC32B5152E5EDC6621254FBDED6A3B77D76CB665F60958BF8B4718F6 C:\WorkSpace\SpaceBattleOfThreeKingdoms\input\selection_set.gd
B227C6877F18B18079C5F04D561D6D8AB4D67069AFA483C80D608914CA4956AB C:\WorkSpace\SpaceBattleOfThreeKingdoms\input\battle_commands.gd
42ECE01D837E41487E8898AA386FA0F95AA54D53CF38D803E008D8AB215BABE9 C:\WorkSpace\SpaceBattleOfThreeKingdoms\hud\fleet_labels.gd
E8E45FD6F540999ECC100B9683EACEC8CE3ADF431D56F42B223799F540D60AFC C:\WorkSpace\SpaceBattleOfThreeKingdoms\hud\battle_hud.gd
1070FC1B282AD89AFBB6E94022BCB442E8E672F7491B2A496B9B5AE4341434B1 C:\WorkSpace\SpaceBattleOfThreeKingdoms\hud\ui_kit\tactical_overlay.gd
BB81EB1855FF0C13708648597905411663223758CCD9A54BA73DA1CAB0565CF6 C:\WorkSpace\SpaceBattleOfThreeKingdoms\hud\ui_kit\command_deck.gd
3FB9390C7A4662FD4A3A4F6E3CD7BE11600CD2D35BD5AA7332487CF4988B1A99 C:\WorkSpace\SpaceBattleOfThreeKingdoms\tmp\p03-product-resume-20261108\DETECTION-UI-CLOSEOUT.md

## 독립 5-b 및 반례

독립 검토 수용 범위는 정적 참조 추적이다. 검토자가 발견한 추가 소비 경로: 터치 드래그는 표적 뷰를 보관하고 만료 후 손을 떼도 그 ID를 order_attack으로 전달할 수 있다. order_attack은 그 뷰의 마지막 알려진 좌표에 마커를 만든다. Core attack은 표적을 처리하는 분기에서 접촉이 여전히 없으면 no_contact를 기록한다. 해당 경쟁 타이밍은 실행하지 않았다. 이 경로는 만료 이벤트가 담은 숨은 실제 좌표와 별개다.

검토자 실행 기록: gpt-6.1-terra, 01a1ba5e-d163-7532-b9ae-3770d9c4ca04, 2026-11-08 18:05:37 KST. 작업자: gpt-6.1-sol, 01a1ba53-9472-7613-bdd4-ef1aef873ef0, 18:05:18 KST.
ADB386D047C5B429E536BDE852A57938F9060908E515EECDE82866E2D49DAB31 C:\WorkSpace\SpaceBattleOfThreeKingdoms\input\touch\touch_controller.gd
B227C6877F18B18079C5F04D561D6D8AB4D67069AFA483C80D608914CA4956AB C:\WorkSpace\SpaceBattleOfThreeKingdoms\input\battle_commands.gd
670916AF166C1F67FD58F6AB3007782A598A7A8F6FEA72024042E1945BEB967A C:\WorkSpace\SpaceBattleOfThreeKingdoms\core\battle\battle_sim.gd
