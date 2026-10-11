# P7 리뷰 (수리·보급 메뉴: 자동 보급 위의 수동 층)

2026-10-11, 5-b 외부 리뷰(Opus, 구현자 Sonnet과 다른 모델). 대상: 브랜치 `p7-supply-menu` @ `3dcf786`, merge-base `77b92c8`(main `ce73d0e`은 그 뒤 문서 커밋 1개뿐), 14파일 +593/−2. 코드는 고치지 않았다.

**판정: 수정 후 병합.** 코어는 기준선 불변·공개 경계·재생이 모두 맞고 차단 버그가 없다. UI에 중간 3건(F-1 전장 입력 가림, F-2 수리 탭 내용, F-3 "수리 도크" 수치)이 있다. F-1·F-2는 작은 수정이고, F-3은 표기만 바꾸거나 결정(Q61 계열)으로 넘기면 된다. 코어만 먼저 병합해도 결과는 바뀌지 않는다.

## 1. 기준선 불변 (최우선)

| 검증 | 규모 | 결과 |
|---|---|---|
| `autoresolve --profile red_cliffs --policies none --rows 1`, merge-base `77b92c8` vs `3dcf786` 별도 worktree | 표준 시드 0~11(12판) + 입문 시드 0~3(4판) = 16판 짝 | **16/16 행 전체 일치**(fp·승패·`t`·사유·supply·curve 등 모든 키). 표준 5/12 승, 입문 4/4 승 양쪽 동일 |
| 지문 문자열 | 코드 대조 | 수동 상태가 기본값(`sup_hold=false`, `sup_first=-1`)이면 `"|man…"` 꼬리가 붙지 않아 `supply.fingerprint()`가 이전과 같다. `BattleFingerprint`는 필드를 반사(reflection)하지 않아 새 변수가 끼지 않는다 |
| 정렬·배정 | 코드 대조 | `_prior` 양쪽 false → 기존 비교로 내려감. 거리 `-1.0`은 `sup_first == f.id`일 때만. `serviceable`의 `sup_hold` 검사·`_complete`의 해제도 기본값에서 무동작 |

결론: 수동 명령을 쓰지 않으면 결과가 비트 단위로 같다. 기존 재생 헤더·기대 지문은 깨지지 않는다(`supply_menu.gd` 첫 검사 + 위 16판).

## 2. 공개 경계

**통과.** `battle_projection.gd:16-20`: `supply`·`menu`는 `f.side == side`일 때만 붙는다. 적 접촉·미탐지 항목에는 `supply` 키 자체가 없다(안개 켜짐/꺼짐 공통, `squadron()` 바깥 분기). `menu.targets`는 같은 진영·동맹만 담고 적 위치·재고는 없다. `public_sources`·`supply_sources`는 이번에 바뀌지 않았다. `battle_source.supply_view()`도 `side == 0 and contact == ""`로 한 번 더 거른다. `fog_ui`·`detection_rules` 통과.

## 3. 발견

| # | 심각도 | 위치 | 내용 |
|---|---|---|---|
| F-1 | 중간 | `hud/ui_kit/supply_menu.gd:20` · `deck_widgets.gd:13` | 배경 `DrawPanel`이 `MOUSE_FILTER_STOP`이다. 패널 루트는 IGNORE지만 배경이 440×252를 덮어, 보급·수리 탭을 연 동안 **전장 중앙 하단(1280×800에서 화면의 약 27%×31%)의 클릭·탭이 막힌다**(함대 선택·이동 명령). 캡처에서 패널이 관우 함대 사거리 고리 아래쪽을 덮는다. 수정: `_bg.mouse_filter = IGNORE`(먼저 버튼만 STOP), 또는 패널을 줄이거나 명령 덱 쪽으로 옮긴다 |
| F-2 | 중간 | `supply_menu.gd:9`, `_build` · `need_text` | 수리 탭이 보급 탭과 **같은 목록**(가까운 순, 최대 3행)에 문구만 "수리 필요 N척/수리 불필요"로 바꾼다. 수리가 필요한 함대가 4번째면 "외 N개 함대"로 숨는다. 캡처(1920×1080 수리 탭)는 두 행 모두 "수리 불필요". 수정: 수리 탭은 `repair > 0` 먼저 정렬(또는 필터), 보급 탭은 결손 있는 대상 먼저 |
| F-3 | 중간(표시·결정) | `supply.gd:361` · `supply_menu.gd` `dock_text` | "수리 도크 a/b"의 b = 보급함 수 × `capacity_per_ship`(1). 관우 함대는 "0/6"으로 나온다. 본편은 SHP-05 한 척에 **수리 도크 2기**(`Seonghanji/data/ship-types.json:68`)라 같은 이름으로 다른 수(본편이면 12)를 보인다. 게다가 이 슬롯은 수리 전용이 아니라 보급·보충·수리 전체 동시 처리 자리다. 수정: 문구를 "처리 자리"(동시 보급 수)로 바꾸고, 본편 도크 2기 반영 여부는 CHECKLIST에 결정 항목으로 남긴다(바꾸면 밸런스 변경 → 기준선 재측정) |
| F-4 | 낮음 | `supply.gd:230` `_prior` · `:289` | "먼저" 지정이 풀리지 않는 경우: 대상이 **다른 공급원**에서 처리되거나, 결손이 없거나, 반경 밖이거나, 죽었거나, 지정한 보급함이 죽은 경우. 반경 밖이면 행이 사라져 UI에서 "먼저 해제"도 못 누른다. 또 `_prior`는 지정한 보급함이 그 대상을 처리할 수 없어도 전역 후보 맨 앞으로 올려 다른 공급원(기지 등) 자리를 먼저 가져간다. 수정: 대상 사망·완료(어느 공급원이든) 때 해제, `_prior`에 `serviceable(f, 지정 보급함)` 조건, 메뉴에 반경 밖 지정 대상도 한 줄 표시 |
| F-5 | 낮음 | `command_deck.gd:1041` `_place_supply` · `:151`·`:180` | 패널 위치가 선택 패널(L1/L2) 높이만 본다. 결정 카드가 뜨면 선택 패널이 숨고 되돌리기 줄이 카드 위로 올라가지만(`:180`) 보급 패널은 그대로라 **결정 카드와 겹칠 수 있다**. 로컬 확인 필요(`capture_ui decision` + 보급 탭) |
| F-6 | 낮음 | `supply_menu.gd:8` | 높이 넘침: 수리 탭 + 중지 표시 + 3행(48) + "외 N" = 약 268px > 내부 236px. VBox가 패널 아래로 넘친다. 행 버튼을 40으로 줄이면 48dp 위반이니 SIZE.y를 늘리거나 MAX_ROWS 2 |
| F-7 | 낮음(UI) | `supply_menu.gd:135` | "먼저" 버튼(`MenuButton2`)이 캡처에서 테두리 없는 큰 글자로만 보여 버튼으로 읽히지 않는다. 48dp 크기는 충족 |
| F-8 | 낮음(문구) | `supply_menu.gd` `level_text` | "보급 레벨 3/3 (처리량 100%, 보충 3회) · 보급대장 마량 정치 90": 정치가 레벨에 반영되는 것처럼 읽히지만 표시 전용이다(Q61(c) 미결). "보충 3회"는 레벨 숫자와 중복. 정치는 레벨 밖 별도 줄로 |
| F-9 | 낮음(설계 확인) | `battle_sim.gd:141` `DIRECT_KINDS` | 보급 명령은 직접 지휘로 바꾸지 않는다. 설정 성격이라 타당하나, 위임 중이면 AI가 보급함 함대를 움직여 손님이 반경 밖으로 빠지고 진행이 0으로 돌아간다. 사용자 안내(또는 "보급 위치 고정" 옵션)는 후속 결정 |
| F-10 | 낮음 | `battle_sim.gd:585` | `supply_first`의 `target_id`가 존재하지 않는 ID면 `by_id`가 null → **해제로 처리**(거부 아님). UI 경로에서는 안 생기지만 재생 로그 오염 시 조용히 통과 |
| F-11 | 낮음(성능) | `supply.gd:197-198` | 정렬 비교마다 `_prior`가 전 함대를 돈다(O(후보 log 후보 × 함대)). 지정이 하나도 없을 때도 매 틱 실행. O3/C1 코어 성능 작업 대상이면 "지정 있음" 플래그로 단락 |

확인만 하고 문제없음:

- 메뉴 값: 레벨(`charge_refill(rate)` 3/2/1), 재고·최대, 사용 중 슬롯(`sup_src == key` 집계), 대상 반경(`S.ship_radius` = 공급원 `r`), 남은 초(`ceil((need − prog)/rate)/hz`)가 코어와 일치.
- 중지: `serviceable`에서 빠져 다음 틱 진행 중 손님을 놓는다(진행 0). 재개 뒤 60초 후 보급(테스트). 보급 중 이동하면 0으로 돌아가는 기존 규칙 유지(`step` 진행 루프 불변).
- 거부: 보급함 없음 `supply_none`, 자기 자신·적 `supply_target`, 토스트 문구 추가됨.
- 여러 보급함 선택: 메뉴·명령 모두 첫 보급함 하나(`supply_view`가 id를 고정해 `[sup_id]`로 보냄). 패널 제목에 함대 이름이 있어 오해는 작다.
- 명령 경로: `issue` → `command_log` 기록, 재생 지문 일치(`supply_menu.gd` 재생 검사). 일시정지 중에는 다른 명령과 같이 무시(`G.state != "play"`).
- 적벽 자동 편성은 모든 아군 함대에 보급함이 있어 어느 함대를 골라도 탭 5개가 보인다. 사용자 요구("보급함이 있을 때")와 조건은 맞지만 사실상 항상 보인다. HUD 혼잡은 탭 줄 두 개 추가 수준(캡처상 넘치지 않음).

## 4. 테스트 (별도 worktree `3dcf786`, `--import` 후 개별 실행, 제한 300초)

| 결과 | 테스트 |
|---|---|
| 통과(42) | audit_3d_models, audit_user_ver3_models, battle_flow, bench_density, core_rules, data_rules, decision_flow, detection_rules(414초, 590초 제한 재실행), fleet_follow, fog_ui, formation_display, formation_rules, formation_ui, fx_follow_formation, ground_ring_proj, info_panel, mouse_input, order_undo, pacing, range_rings, roster, rule_text, rule_text_salvo, safe_area, salvo_rules, selection_groups, smoke, squadron_strip, stratagem_rules, succession_rules, **supply_menu**, supply_rules, terrain_display, touch_hold, touch_input, touch_targets, ui_flow, ui_sound, **ui_wording**, victory_rules, weapon_charges, world_link(466초, 재실행. merge-base 459초) |
| 기존 실패 | boundary: `battle_source.gd:176 BattleRules.BP` 1건만(알려진 것, P7 새 위반 없음) |
| 미종료(기존과 같음) | commander_ai: p7·merge-base 모두 590초 제한 초과(기기 부하). capture_ui·capture_formation·capture_world: 헤드리스에서 미종료, merge-base도 같음(화면 있는 실행 전용) |
| 제외 | autoresolve·salvo_compare(통계, §1에 사용), capture_3d_poc(알려진 미종료), organization_rules(668초짜리 정상 테스트, 이번 변경과 무관해 생략) |

새 실패 없음. `.uid`: `hud/ui_kit/supply_menu.gd.uid`, `tests/supply_menu.gd.uid` 포함, 누락 없음.

화면: `capture_ui supply`·`supply_repair`를 1280×800·1920×1080(화면 있는 실행)으로 직접 떴다. 패널은 정보 패널·미니맵·명령 덱과 겹치지 않는다. 전장 중앙 하단을 크게 가린다(F-1). 12px·48dp 충족, "전대" 문구 없음.

## 5. 병합 충돌 예측

`git merge-tree --write-tree main p7-supply-menu` → 트리 `c7c6bc8`, **충돌 없음**. main은 merge-base 뒤로 문서 커밋 1개(`ce73d0e`)뿐이다. 편성 O4 화면 등이 먼저 병합되면 `command_deck.gd`(탭 구성 `TABS`·`_set_tab`·`_refresh_cmds`)와 `battle_projection.gd` 아군 분기에서 다시 확인해야 한다.

## 6. 사용자 로컬 확인 체크리스트

- [ ] 보급 탭을 연 채 패널 아래 전장을 클릭·탭해 함대 선택·이동이 되는지(F-1)
- [ ] 수리 탭에서 손상 함대가 맨 위에 오는지(F-2), "수리 도크 0/6" 표기가 납득되는지(F-3)
- [ ] 결정 카드가 뜰 때 보급 패널과 겹치는지(F-5)
- [ ] "먼저" 누른 뒤 한 주기 후 표시가 "먼저"로 돌아오는지, 대상이 반경 밖으로 나가면 어떻게 보이는지(F-4)
- [ ] 보급 중지 → 재개 토글 표기, 다른 함대 선택 시 탭이 태세로 돌아가는지
- [ ] 태블릿 APK에서 "먼저" 버튼이 버튼으로 보이고 누르기 쉬운지(F-7)
