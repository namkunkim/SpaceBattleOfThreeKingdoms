# S1 필드별 읽기 원장과 oracle 후보

상태는 NOT_READY / UNCLASSIFIED다. 각 행의 이름은 선언 분모 후보다. 경로와 소비 설명이 여러 행에 반복되는 곳은 책임 묶음이며 모든 쓰기/읽기의 행별 확정은 미완료다. 독립 심사자가 원문으로 이름 목록을 대조하기 전 검증 oracle로 사용하지 않는다. SHA는 READONLY-SOURCES.sha256에 기록했다.

BattleState의 처음 23개 scalar는 STATE capture/복원 목록이다. FleetState 121은 FLEET 목록이며 기본은 값을 새 객체에 복사한다. 서비스 복원 예외와 런타임 구조 조건은 아래에 명시했다.

| 클래스 | 필드 | 근거 경로 | 갱신·소비 및 복원 책임 |
|---|---|---|---|
| BattleState | `hz` | battle_sim.gd:40–95; operation_private_state.gd:425–429 | 초기 컨텍스트. hz는 틱 환산에 소비, seed_id는 컨텍스트 동일성 검사 |
| BattleState | `seed_id` | battle_sim.gd:40–95; operation_private_state.gd:425–429 | 초기 컨텍스트. hz는 틱 환산에 소비, seed_id는 컨텍스트 동일성 검사 |
| BattleState | `tick` | battle_sim.gd:923–989 | step/하위 걸음 시간, AI 카운트다운. 시간/AI/종료에 소비 |
| BattleState | `clock_ms` | battle_sim.gd:923–989 | step/하위 걸음 시간, AI 카운트다운. 시간/AI/종료에 소비 |
| BattleState | `ai_timer` | battle_sim.gd:923–989 | step/하위 걸음 시간, AI 카운트다운. 시간/AI/종료에 소비 |
| BattleState | `cp` | battle_sim.gd:450–459,923–932 | 비용 소비 및 회복량과 나머지. 명령 비용과 다음 회복에 소비 |
| BattleState | `ecp` | battle_sim.gd:450–459,923–932 | 비용 소비 및 회복량과 나머지. 명령 비용과 다음 회복에 소비 |
| BattleState | `cp_rem` | battle_sim.gd:450–459,923–932 | 비용 소비 및 회복량과 나머지. 명령 비용과 다음 회복에 소비 |
| BattleState | `ecp_rem` | battle_sim.gd:450–459,923–932 | 비용 소비 및 회복량과 나머지. 명령 비용과 다음 회복에 소비 |
| BattleState | `killed` | battle_sim.gd:264–307; battle_projection.gd | 피해/손실 집계와 결산·투영 |
| BattleState | `lost` | battle_sim.gd:264–307; battle_projection.gd | 피해/손실 집계와 결산·투영 |
| BattleState | `reinf` | battle_sim.gd:252–258,949–989; operation_private_state.gd:427 | 증원 표지 및 발동 시각. 다음 증원 억제. 제한 복원은 기본값 요구 |
| BattleState | `reinf_ms` | battle_sim.gd:252–258,949–989; operation_private_state.gd:427 | 증원 표지 및 발동 시각. 다음 증원 억제. 제한 복원은 기본값 요구 |
| BattleState | `next_id` | battle_sim.gd:218–258,320–356; battle_state.gd:101–104 | 생성 ID·진형 번호 및 공격/RNG 사건 ID 카운터 |
| BattleState | `form_counter` | battle_sim.gd:218–258,320–356; battle_state.gd:101–104 | 생성 ID·진형 번호 및 공격/RNG 사건 ID 카운터 |
| BattleState | `next_event_id` | battle_sim.gd:218–258,320–356; battle_state.gd:101–104 | 생성 ID·진형 번호 및 공격/RNG 사건 ID 카운터 |
| BattleState | `over` | battle_sim.gd:923–945,1215–1226; operation_private_state.gd:256–266 | 종료 상태·결과·실제 종료 시각. substep 탈출 및 summary 소비 |
| BattleState | `win` | battle_sim.gd:923–945,1215–1226; operation_private_state.gd:256–266 | 종료 상태·결과·실제 종료 시각. substep 탈출 및 summary 소비 |
| BattleState | `end_reason` | battle_sim.gd:923–945,1215–1226; operation_private_state.gd:256–266 | 종료 상태·결과·실제 종료 시각. substep 탈출 및 summary 소비 |
| BattleState | `end_tick` | battle_sim.gd:923–945,1215–1226; operation_private_state.gd:256–266 | 종료 상태·결과·실제 종료 시각. substep 탈출 및 summary 소비 |
| BattleState | `end_ms` | battle_sim.gd:923–945,1215–1226; operation_private_state.gd:256–266 | 종료 상태·결과·실제 종료 시각. substep 탈출 및 summary 소비 |
| BattleState | `army_ev` | morale.gd:41–48,185–200; victory.gd:139–167 | 진영별 사기 사건과 결산 Dictionary. 참조는 S4 |
| BattleState | `result` | morale.gd:41–48,185–200; victory.gd:139–167 | 진영별 사기 사건과 결산 Dictionary. 참조는 S4 |
| BattleState | `fleets` | operation_private_state.gd:272–283,462–473 | 별도 순서 행, roster 객체에 위치별 값 적용/투사체 새 객체 생성 |
| BattleState | `missiles` | operation_private_state.gd:272–283,462–473 | 별도 순서 행, roster 객체에 위치별 값 적용/투사체 새 객체 생성 |
| BattleState | `swarms` | operation_private_state.gd:272–283,462–473 | 별도 순서 행, roster 객체에 위치별 값 적용/투사체 새 객체 생성 |
| BattleState | `_idx` | battle_state.gd:58–69; operation_private_state.gd:474–475 | 제외·무효화 후 지연 재계산. ID→객체, 배열 길이 |
| BattleState | `_idx_n` | battle_state.gd:58–69; operation_private_state.gd:474–475 | 제외·무효화 후 지연 재계산. ID→객체, 배열 길이 |
| FleetState | `id` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `side` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `name` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `role` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `portrait` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `form` | battle_sim.gd:244–248; salvo.gd:209–224 | 생성 및 진형 전환 시 좌표 배열 설정. 전투 위치와 투영에서 순서대로 소비, Vector2 순서 보존 |
| FleetState | `form_id` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `ships` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `max_ships` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `shown` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `lv` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `xp` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `pos` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `heading` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `target_id` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `has_move` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `move_to` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `missile_cd` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `fighter_cd` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `counter_launch` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `counter_pending` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `fighter_fired_tick` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `charge` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `flank_msg` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `defense` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `dead` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `fire_id` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `in_cmd` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `spd` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `wait` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `is_flag` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `home` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `spawn` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `range_r` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `ranges` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `sq_id` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `morale_group` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `start_morale_bp` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `faction` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `commander_id` | battle_sim.gd:218–258,264–356,460–808,991–1123 | 생성 입력·기동·피해·POC 전투. 대상 ID는 by_id/live_target이 읽고 표시 소비는 battle_projection.gd. id/side/faction/sq_id는 roster 동일성 검증. |
| FleetState | `cmd_stat` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `morale_bp` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `stats` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `formation_id` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `equip` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `comp0` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `stages` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `hull` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `max_hull` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `lost_ships` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `loss_total` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `loss_exposed` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `ammo` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `energy_m` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `energy_rem` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `heat_m` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `heat_rem` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `wch` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `wmax` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `next_fire` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `supp` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `moving` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `speed` | salvo.gd:26–82,282–295,531–570,609–653,675–790 | 편성에서 초기화 후 피해·사격·회복·속도 판정. comp0/max_hull은 초기값, 범주 구조와 순서는 별도 검증. moving은 행동 소비가 있으므로 지문 생략과 값 복원을 구분. |
| FleetState | `mstate` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `out` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `retreat_order` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `retreat_counted` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `loss_mul_until` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `loss_mul_bp` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `cost0` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `chain_sunk` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `died_pos` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `arrived` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `fired` | morale.gd:70–185; battle_sim.gd:295–319; salvo.gd:609–674; victory.gd:29–170 | 사기·이탈/만료·피해 표지와 결산. fired는 범주별 첫 사격 여부, 사기 배율은 tick 경계에서 소비. |
| FleetState | `form_to` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `form_left` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `route` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `strafe` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `face_set` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `speed_cap` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `move_grp` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `face_to` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `flip` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `flip_wait` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `traits` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `shape_to` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `form_t` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `shape` | battle_sim.gd:373–379,460–808,882–922,991–1160; salvo.gd:150–224 | 기동 경로 및 진형 전환. route와 form_t는 배열 순서 보존. shape_to/form_t는 표시 파생이지만 현재 값 복사. |
| FleetState | `control` | battle_sim.gd:104–115,165–170,460–808; ai/commander_ai.gd; decisions.gd | 명령 및 AI·결정 카드에 의해 설정되고 다음 AI 평가에서 소비. pursue_id는 roster 참조 검증. |
| FleetState | `posture` | battle_sim.gd:104–115,165–170,460–808; ai/commander_ai.gd; decisions.gd | 명령 및 AI·결정 카드에 의해 설정되고 다음 AI 평가에서 소비. pursue_id는 roster 참조 검증. |
| FleetState | `bias_mod` | battle_sim.gd:104–115,165–170,460–808; ai/commander_ai.gd; decisions.gd | 명령 및 AI·결정 카드에 의해 설정되고 다음 AI 평가에서 소비. pursue_id는 roster 참조 검증. |
| FleetState | `bias_until` | battle_sim.gd:104–115,165–170,460–808; ai/commander_ai.gd; decisions.gd | 명령 및 AI·결정 카드에 의해 설정되고 다음 AI 평가에서 소비. pursue_id는 roster 참조 검증. |
| FleetState | `pursue_id` | battle_sim.gd:104–115,165–170,460–808; ai/commander_ai.gd; decisions.gd | 명령 및 AI·결정 카드에 의해 설정되고 다음 AI 평가에서 소비. pursue_id는 roster 참조 검증. |
| FleetState | `pursue_until` | battle_sim.gd:104–115,165–170,460–808; ai/commander_ai.gd; decisions.gd | 명령 및 AI·결정 카드에 의해 설정되고 다음 AI 평가에서 소비. pursue_id는 roster 참조 검증. |
| FleetState | `ai_seen` | battle_sim.gd:104–115,165–170,460–808; ai/commander_ai.gd; decisions.gd | 명령 및 AI·결정 카드에 의해 설정되고 다음 AI 평가에서 소비. pursue_id는 roster 참조 검증. |
| FleetState | `hit_tick` | salvo.gd:675–790; supply.gd; p03-supply-ledger | 명중 및 회복 카운터, 다음 손상 배분에 소비. 실제 수리와 소유 분담은 보급 원장. |
| FleetState | `healed_wound` | salvo.gd:675–790; supply.gd; p03-supply-ledger | 명중 및 회복 카운터, 다음 손상 배분에 소비. 실제 수리와 소유 분담은 보급 원장. |
| FleetState | `healed_mod` | salvo.gd:675–790; supply.gd; p03-supply-ledger | 명중 및 회복 카운터, 다음 손상 배분에 소비. 실제 수리와 소유 분담은 보급 원장. |
| FleetState | `sup_src` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `sup_prog` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `sup_since` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `sup_still` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `sup_pos` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `sup_n` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `sup_ammo` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `sup_mat` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `sup_hold` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `sup_first` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `supplied` | supply.gd; operation_service_state.gd; p03-supply-ledger | 보급 배정·정지·시간·재고·통계. 서비스 위임 여부는 Service.SUP_FIELDS가 결정하며 supplied는 별도 집계. |
| FleetState | `level` | salvo.gd:26–82,375,692–694; command.gd:55–100; assault.gd:43–116; victory.gd:197–209 | 프로필 지휘관 자료, 승계/혼선·강습. fr_hits 순서와 tick 창, boarded 보정, cmdr_sub 외부 인물 ID. |
| FleetState | `vice` | salvo.gd:26–82,375,692–694; command.gd:55–100; assault.gd:43–116; victory.gd:197–209 | 프로필 지휘관 자료, 승계/혼선·강습. fr_hits 순서와 tick 창, boarded 보정, cmdr_sub 외부 인물 ID. |
| FleetState | `staff` | salvo.gd:26–82,375,692–694; command.gd:55–100; assault.gd:43–116; victory.gd:197–209 | 프로필 지휘관 자료, 승계/혼선·강습. fr_hits 순서와 tick 창, boarded 보정, cmdr_sub 외부 인물 ID. |
| FleetState | `cmdr_state` | salvo.gd:26–82,375,692–694; command.gd:55–100; assault.gd:43–116; victory.gd:197–209 | 프로필 지휘관 자료, 승계/혼선·강습. fr_hits 순서와 tick 창, boarded 보정, cmdr_sub 외부 인물 ID. |
| FleetState | `cmdr_sub` | salvo.gd:26–82,375,692–694; command.gd:55–100; assault.gd:43–116; victory.gd:197–209 | 프로필 지휘관 자료, 승계/혼선·강습. fr_hits 순서와 tick 창, boarded 보정, cmdr_sub 외부 인물 ID. |
| FleetState | `confuse_until` | salvo.gd:26–82,375,692–694; command.gd:55–100; assault.gd:43–116; victory.gd:197–209 | 프로필 지휘관 자료, 승계/혼선·강습. fr_hits 순서와 tick 창, boarded 보정, cmdr_sub 외부 인물 ID. |
| FleetState | `fr_hits` | salvo.gd:26–82,375,692–694; command.gd:55–100; assault.gd:43–116; victory.gd:197–209 | 프로필 지휘관 자료, 승계/혼선·강습. fr_hits 순서와 tick 창, boarded 보정, cmdr_sub 외부 인물 ID. |
| FleetState | `assault_cd` | salvo.gd:26–82,375,692–694; command.gd:55–100; assault.gd:43–116; victory.gd:197–209 | 프로필 지휘관 자료, 승계/혼선·강습. fr_hits 순서와 tick 창, boarded 보정, cmdr_sub 외부 인물 ID. |
| FleetState | `boarded` | salvo.gd:26–82,375,692–694; command.gd:55–100; assault.gd:43–116; victory.gd:197–209 | 프로필 지휘관 자료, 승계/혼선·강습. fr_hits 순서와 tick 창, boarded 보정, cmdr_sub 외부 인물 ID. |
| FleetState | `skill_slots` | skills.gd; p03-skill-effect-ledger | 편성 슬롯, 발동 횟수, 기한 효과. 기존 원장에 위임. 활성 SkillCore는 지원 밖. |
| FleetState | `skill_used` | skills.gd; p03-skill-effect-ledger | 편성 슬롯, 발동 횟수, 기한 효과. 기존 원장에 위임. 활성 SkillCore는 지원 밖. |
| FleetState | `fx` | skills.gd; p03-skill-effect-ledger | 편성 슬롯, 발동 횟수, 기한 효과. 기존 원장에 위임. 활성 SkillCore는 지원 밖. |
| Missile | `id,pos,target_id,src_id,dmg,v,wob,age,side,dead` | battle_state.gd:6–16, battle_sim.gd:320–335,1172–1191 | 발사 시 ID·좌표·속도·피해 및 참조 생성. 이동/명중/나이·사망 갱신 뒤 제거. 새 객체로 복사하고 참조는 논리 ID로 탐색 |
| Swarm | `id,src_id,target_id,life,side,dps,pts,striking` | battle_state.gd:18–26, battle_sim.gd:336–356,1192–1212 | 발진 시 ID·참조·수명·공격점 배열 생성. 연속 피해·수명·striking 갱신. 새 객체와 배열 순서 보존 |
| TickClock | `hz,speed,acc,dropped` | tick_clock.gd:11–33 | hz·speed로 acc에 delta 환산, 정수 틱 반환 후 초과량 dropped, alpha는 acc 소비. 제한 packet의 논리 시간과 분리 |
| BattleRng | `profile_id` | battle_rng.gd:9–30 | init으로 고정. tick/event_id/sub와 SHA 입력 구성. derived 비교 및 재생성 |

## 참조와 동적 키

- FleetState의 `target_id,pursue_id,fire_id,sup_first`는 -1 또는 roster ID를 허용한다. 살아 있는 대상 여부와 저장 ID의 존재는 별도 판단이다. Missile/Swarm의 src_id와 target_id는 roster에 있어야 하고 공격 ID는 두 종류에서 합쳐 고유해야 한다. Swarm.pts의 4키는 pos:Vector2, a/r/w:float다. 근거 operation_private_state.gd:397–454.
- 8개 key 배열 검사 대상은 `comp0,stages,ammo,wch,wmax,next_fire,supp,stats`다. comp0/stages의 키는 함종, ammo/wch/wmax/next_fire/supp는 무기 범주, stats는 지휘관 수치다. stages의 순서는 무손상/경파/중파/대파/격침이다. `ranges,fired,vice,staff,fx`는 같은 8개 key 배열 검증의 대상이 아니며 키의 개별 폐합은 후속 원장 대상이다.
- 과거 31파일·294개는 전체 감사의 분모다. 이번 172개는 core의 네 스크립트와 두 중첩 클래스에만 해당한다. 172개에 capture 목록과 참조/Dictionary 하위키를 더하지 않는다. 과거 oracle과 현재 행의 동등성 및 파일별 차집합은 미확정이다.


