# 정적 5-a 확인

- Detection: 접촉 제거는 detection.gd:200. 호스트 drain은 side0 고정. BattleSim은 detect 활성 시 side1 contact 사건을 건너뛴다. 화면 분기와 trace 목록에 contact 소비 없음. 화면은 projection 누락 시 기존 접촉 제거.
- Supply: sup_prog는 fleet_state.gd:116의 일반 필드. _take와 capture_partial은 같은 함대 필드를 동기로 읽고 await나 signal 발행을 하지 않는다. advance는 step 전체를 busy로 감싼다. busy는 스레드 잠금이 아니므로 owner를 외부에서 교차 스레드로 공유하는 가설에는 이 보장이 적용되지 않는다. 조사한 워커는 자체 owner를 스레드 내부에서 만들고 닫는다. 정상 제품 호출 경로의 capture 호출 없음.
- 런타임 UI 검증은 기존 제품 실행 금지로 생략. 이 문서는 정적 대조만 판정한다.
- 다음 SHA는 이 게이트 직전과 기록 직후의 검증 입력에 한정한다. 최초 조사 시작 상태와 전체 공유 작업공간의 바이트 보존은 입증하지 않는다.

DF34CEE4A225683D6BC1C9005DC7760C365CE3A61AE68E106449CB2E7154253B C:\WorkSpace\SpaceBattleOfThreeKingdoms\core\battle\detection.gd
670916AF166C1F67FD58F6AB3007782A598A7A8F6FEA72024042E1945BEB967A C:\WorkSpace\SpaceBattleOfThreeKingdoms\core\battle\battle_sim.gd
04C146B3F7AABC67A9119F604FF839EAB8F2EFA69BE9B45D654556679C969F30 C:\WorkSpace\SpaceBattleOfThreeKingdoms\core\battle\battle_projection.gd
00B39729582CEA9F7B66FECD5396C44BDC4B0FA0B2F57516BC4D94CF12D04D6E C:\WorkSpace\SpaceBattleOfThreeKingdoms\core\battle\fleet_state.gd
1F762BFEA77ABB57795C87AF619E2D6B48210377CC6E04B9463D021BE6E2D5BE C:\WorkSpace\SpaceBattleOfThreeKingdoms\core\battle\supply.gd
AC59A7547469C705D33854742E9503B08422770B01956A47861B45735AB8C1C6 C:\WorkSpace\SpaceBattleOfThreeKingdoms\core\battle\operation_private_state.gd
18F1381A330D6F33163CC94F678FA624F8500DD415F5D35EE4A4B4BFD5EE44A0 C:\WorkSpace\SpaceBattleOfThreeKingdoms\core\battle\operation_service_state.gd
604B79308D9B3DBAB84DCED32456A4F41B28686C8EEC748073D3816892CFFC5C C:\WorkSpace\SpaceBattleOfThreeKingdoms\scripts\FleetBattle3D.gd
76BB319B96A1835087FF48F3C8CA268549A9906D2F658F605065ADF74FAF5E8F C:\WorkSpace\SpaceBattleOfThreeKingdoms\scripts\battle_trace.gd
85EC124DF59C0C50CEE616565E88BCDD978588F28BAF36180F8EC2C92EEBD9EB C:\WorkSpace\SpaceBattleOfThreeKingdoms\scripts\world\auto_resolver.gd
E40B067A8F9AF61A85F5FBF88B4297962F770B0191442EDE543B69B0F49BCE07 C:\WorkSpace\SpaceBattleOfThreeKingdoms\view\battle_view_model.gd
E0CD8D7770788CFAEDF094CF6A78D0D46DC492ABE851ADE7C50A9B64972D6CB0 C:\WorkSpace\SpaceBattleOfThreeKingdoms\tmp\p03-product-resume-20261108\STATIC-TRACE.md
