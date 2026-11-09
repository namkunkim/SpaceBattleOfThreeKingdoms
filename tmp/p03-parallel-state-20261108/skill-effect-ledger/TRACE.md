# 기술 효과 소비 및 진입 원장

[값과 순서 oracle](oracle.json)의 19개 기술과 33개 효과 항목을 아래 24개 키의 소비와 연결한다. 하위 경로 4개는 categories[0], charges_add.artillery, in_terrain.damage_taken_mul_bp, in_terrain.morale_loss_mul_bp다. JSON 타입과 값은 oracle 및 실행 관측 기록에 보존한다. 기간 record는 기술 ID, source fleet ID, expiry tick, effect 사전, radius를 가진다. 대상이 진영이면 side_fx, 아니면 대상 f.fx에 순서대로 추가한다. `skills.gd:330–355,388–403`.

| 키 | 구분과 소비 근거 |
|---|---|
| affinity_ignore | 기간 boolean. salvo.gd:392가 상성 보정을 막는다. |
| alias_command | 발동 경로 지시. skills.gd:322–326이 chain.letter 호출, 380–386이 명령 문자열에 맞는 슬롯 탐색. stratagem.gd:445가 letter 슬롯을 요구한다. |
| assault_block | 기간 boolean. assault.gd:68의 차단. |
| assault_bp | 기간 가산. assault.gd:79–80 성공률 clamp, ai/commander_ai.gd:183 및 battle_sim.gd:1125 접근 판단. |
| assault_cd_reset | 즉시. skills.gd:344–345에서 cooldown을 현재 tick으로 바꾼다. |
| categories | 기간 효과 조건. skills.gd:48–49에서 범주 인수가 주어질 때 배열 membership 비교. 사거리 호출 salvo.gd:280이 범주 전달. |
| chain_power_mul_bp | 기간 배율. stratagem.gd:176이 연쇄 화공 세기 보정. |
| charges_add | 즉시. skills.gd:340–343에서 지정 범주가 wch에 있을 때 wmax까지 가산. |
| damage_mul_bp | 기간 배율. salvo.gd:403이 주는 피해에 적용. |
| damage_redirect_bp | 기간 분담. skills.gd:112–128이 유효 거리의 보호 함대를 찾고 비율 반환, salvo.gd:701–705가 보호 함대에 피해 배분. |
| damage_taken_mul_bp | 기간 배율. skills.gd:55–77에서 감소/증가 그룹을 따로 결합, salvo.gd:700–705에서 원 대상과 분담 대상 각각 소비. |
| hit_bp | 기간 가산. salvo.gd:355가 명중률 범위 안으로 clamp. |
| in_terrain | 기간 조건부 재정의. skills.gd:50–52에서 현재 지형 조건이 맞으면 하위 사전 값을 택한다. |
| morale_bp | 즉시. skills.gd:334–339가 사기 상승을 cap하거나 MoraleCore.lose에 위임한다. |
| morale_loss_mul_bp | 기간 배율. morale.gd:92가 사기 차감에 적용. |
| note | 설명 문자열. 고정 원문의 effect 소비 근거 미발견, UNCLASSIFIED. |
| only_while | 기간 조건. skills.gd:46–47,141–142가 holding 조건에서만 값을 소비하게 한다. |
| range_mul_bp | 기간 배율. salvo.gd:280이 범주를 넘기고 skills.gd:357–359가 효과 변경 때 사거리 재계산을 요청한다. |
| rescue_equipped | 기간 boolean. victory.gd:188이 지휘관 구조 후보 장비 조건을 대체할 수 있다. |
| reveal_orders | 기간 조건. skills.gd:130–137에서 orders=true의 추가 조건, battle_projection.gd:140에서 이동 명령을 투영할 때 소비. |
| reveal_radius | 기간 거리. skills.gd:130–137의 거리 판정, detection.gd:171과 battle_projection.gd:140에서 사용. |
| sensor_mul_bp | 기간 배율. detection.gd:94에서 센서 점수에 적용. |
| speed_mul_bp | 기간 배율. battle_sim.gd:1052가 이동 속도에 적용. skills.gd:75–76에서 max 규칙 사용. |
| transition_mul_bp | 기간 배율. salvo.gd:146의 전환 시간 계산 및 skills.gd:357–363의 즉시 전환 처리. skills.gd:77–78에서 min 규칙. |

## 외부 진입과 소비

- profile→정의. battle_sim.gd:89–90에서 특별 기술 설정과 관련 활성 조건 아래 SkillCore 생성, skills.gd:34–39가 정의를 ID로 색인한다. organization.gd:54–105,475–511은 직책과 슬롯을 정의해 profile roster로 전달하고 salvo.gd:36이 FleetState에 복사한다. org_screen.gd:142,388은 정의 및 인물 기술 표시를 읽는다.
- UI→명령. command_deck.gd:672–675가 SkillBar를 생성한다. skill_bar.gd:66–83의 길게 누르기 확인이 input/battle_commands.gd:41–46을 호출한다. 단일 선택·play 상태에서 host.issue로 slot을 가진 skill 명령을 전달한다. battle_sim.gd:642–660이 슬롯·대상 검증 뒤 SkillCore.use를 호출한다. CommandDeck의 확인 루프와 host의 표시 입력은 코어 상태 소유와 별개다.
- AI→발동. ai/commander_ai.gd:85에서 투영을 넘겨 skills.gd:365–379의 평가를 호출한다. `ai_when`과 `requires`는 별도 입력이며 효과 키 집계에 포함하지 않는다.
- 하위 걸음→만료. battle_sim.gd:963이 최초 하위 걸음에서 skills.step을 부른다. skills.gd:388–403이 fleet/side expiry를 소비하며 변경된 fleet 값을 다시 맞춘다.
- 상태→표시. battle_projection.gd:33은 아군 기술 슬롯·효과를 내고 140은 reveal_orders를 소비한다. skill_bar.gd:92,101,148의 3행은 투영 Dictionary 접근이다. 나머지 lexical 28행은 직접 모듈 접근이다. scripts/FleetBattle3D.gd:693은 core 정의에서 효과 이름을 읽고 698에서 사건 표시를 발행한다.
- 사건과 지문. skills.gd:353이 skill 사건과 대상 ID를 발행한다. FleetBattle3D.gd:691–698에서 표시 이름과 대상 문구를 만든다. battle_sim.gd:137이 skills.fingerprint를 호출한다. 테스트의 진단·통계는 고정 생산 범위 밖이다.

실행 출력의 lexical-rows.json은 31개 후보 각각에 source text와 접근 문자열을 보존한다. 같은 행의 두 접근은 별도 문자열로 기록한다. 직접 효과 호출, 전체 게임 런타임 경로, 제품 UX, 활성 SkillCore 복원은 실행하지 않았다. 기존 SkillCore 7/FleetState 3 선언 분모를 더하지 않는다.
