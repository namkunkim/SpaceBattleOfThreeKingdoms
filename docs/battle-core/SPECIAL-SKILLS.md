# 장수 특기(특수기술) 정의 — P8-0

결정 근거: `BATTLE_DECISIONS.md` §U (Q88~Q91), §S-1 D4, Q63·Q68. 본편 근거: `combat.md` §9, `characters.json` traits.
데이터: `data/scenarios/red_cliffs_208_realtime.json` → `realtime_rules.special_skills` (생성기 `tools/scenario/make_red_cliffs_208.py`, JSON 직접 수정 금지).
**모든 수치는 제안값(`status: "proposed"`)이다.** UI 표시명은 "장수 특기".

## 1. 규칙 요약

- 장수당 기술 1개 = 첫 특성(`traits[0]`)에서 정해진다. 특성 없는 장수(175명 중 27명)는 기술 없음.
- 함대 슬롯 3 = 제독, 부제독, 강습 참모 순(D4). 편성 화면에서 교체, 전투 중 교체 없음. 함대만(Q73). 그룹 총사령·그룹 기술은 없음(Q90).
- 기술별 전투당 1회, 슬롯 간 쿨다운 공유 없음(Q89). 지속 효과는 `duration_s`(게임 초), 0은 즉시 효과.
- 가용 장수 175명 중 특성 보유 148명이 전원 기술을 가진다(누락 0, 생성기가 assert). 고유 12종 + 유형 7종 = 기술 19개.

## 2. 효과 표

대상: `self` 자기 함대 · `ally_fleet` 반경 안 아군 함대 하나 · `enemy_fleet` 반경 안 확인된 적 함대 하나 · `allies_in_radius` 반경 안 아군 전체 · `faction` 아군 세력 전체.

### 2-1. 유형 7종 (나머지 특성)

| ID | 유형 | 이름 | 대상 | 지속 | 효과(코어 개념) |
|---|---|---|---|---|---|
| SK-T-FIRE | firepower | 맹공 | self | 120 | 모든 무장(포격·전열·요격·뇌격) 피해 ×1.15 (`damage_mul_bp` 11500) |
| SK-T-GUARD | defense | 견수 | self | 120 | 받는 선체 피해 ×0.8 |
| SK-T-MOVE | maneuver | 질주 | self | 60 | 이동 속도 ×1.3, 진형 전환 시간 ×0.5 |
| SK-T-MORALE | morale | 격려 | self | 120 | 사기 즉시 +800bp, 120초간 사기 감소 ×0.7 |
| SK-T-DISRUPT | disrupt | 교란 | enemy_fleet 260 | 60 | 대상 사기 즉시 −800bp, 명중률 −800bp(−8%p) |
| SK-T-SCOUT | detection | 간파 | self | 120 | 센서 ×1.5, 반경 400 안 적 접촉 확인 상태 |
| SK-T-SUPPLY | supply | 조달 | self | 즉시 | 미사일(포격) 사용 횟수 +1 (기본 3회 상한, 보급함 재고 소모 없음). 이미 3회면 거부 |

### 2-2. 고유 12종 (본편 §9 발동 시점)

"기존 코어와의 관계" 열이 핵심이다. 이미 구현된 상시 효과는 **그대로 두고** 중복 효과를 만들지 않는다.

| ID | 특성(장수) | 대상·지속 | 효과 | 기존 코어와의 관계 |
|---|---|---|---|---|
| SK-U-GUANYU | 만인지적(관우) | self 60 | 강습 성공률 +3000bp, 강습 재사용 대기 초기화. 강습모함(SHP-01) 보유 함대만 | `assault.elite_ids`(관우=특급, 개방 명중 1)는 상시 유지. 그 위에 성공률을 더함. Q68: 유비군은 SHP-01이 0척이라 현재 데이터에서는 거부된다(받아들인 사항, 편성 화면에서 SHP-01을 넣으면 가능) |
| SK-U-ZHUGE | 신기묘산(제갈량) | self 120 | 진형 전환 즉시 완료(전환 중 ×0.8 없음), 진형 상성 불리 무시 | `formation_rules.master_trait`(팔진 FRM-07 사용 자격)는 그대로. 본편 "배치 재조정 1회"를 실시간에서는 진형 즉시 전환으로 옮김 |
| SK-U-ZHAOYUN | 일신시담(조운) | ally_fleet 200 / 30 | 대상(자기 포함) 받는 선체 피해 0, 지휘관 구조 판정에서 구조 함대로 인정 | `commander_casualties` 표의 "구조 장비 아군 함대 반경 안" 분기에 효과 동안 이 함대를 추가 |
| SK-U-HUANGZHONG | 강궁(황충) | self 120 | 포격(미사일) 사거리 ×1.3 | 사거리 원(P2)이 효과 중 늘어난 값을 그려야 함 |
| SK-U-ZHOUYU | 미주랑(주유) | faction 180 | 아군 화공 위력 ×1.5 | `chain_operation.power_by_range`에 곱함(최대 0.5→0.75). 발동·번짐·반격 규칙 그대로 |
| SK-U-HUANGGAI | 고육계(황개) | self, 즉시 | 위장 항복 서신 송신 | **새 효과 없음.** 기존 `letter` 명령(`feigned_surrender.letter_uses` 1)의 슬롯 단축. 사용 횟수는 `letter_uses`를 그대로 씀. 화공 운용 함대(`chain_explosion_override.host_squadron_id`)만 |
| SK-U-GUOJIA | 귀모(곽가) | self 120 | 반경 600 적 함대를 확인 상태로, 이동 목표 공개 | 진영 공유 탐지(Q46)로 진영 전체가 봄 |
| SK-U-DIANWEI | 악래(전위) | self 200 / 120 | 반경 200 안 아군 **기함 함대**가 받는 선체 피해의 50%를 대신 받음 | 같은 함대가 기함이면 거부 |
| SK-U-XUCHU | 호치(허저) | allies_in_radius 200 / 120 | 반경 안 아군 함대는 강습을 받지 않음 | `assault.flagship.escort_trait`(호치, 기함 강습 ×0.5)는 상시 유지. 이 기술은 일시적 완전 차단 |
| SK-U-CAOREN | 철벽(조인) | self 180 | 정지(이동 명령 없음) 중 받는 선체 피해 ×0.6667 | 본편 "방어 시 전열함 내구 +50%"를 피해 배율로 환산 |
| SK-U-XIAHOUYUAN | 신속(하후연) | self 90 | 이동 속도 ×1.4, 대신 받는 피해 ×1.15 | 본편 단점 "매복 피해 +30%"를 효과 중 피해 증가로 옮김 |
| SK-U-HAOZHAO | 진창(학소) | self 180 | 받는 피해 ×0.8, 사기 감소 ×0.7. 지형 구역(성운·잔해대·행성 그림자) 안이면 ×0.6·×0.5 | 적벽에 회랑이 없어 "회랑 방어"를 지형 구역으로 대체. "병력차 무시"는 피해 감소로 근사 |

학소·하후연·조인은 조조군 소속이다. 유비군 플레이어가 쓰는 고유 기술은 관우·제갈량·조운·황충, 손권군은 주유·황개 등(위임 AI 발동).

## 3. 특성 → 유형 매핑

방법: ① 12종은 고유 ② 특성 이름·본편 설명의 낱말로 키워드 매핑 ③ 낱말이 없는 이벤트·관계형 특성(33건)은 장수의 **최고 능력치**로 정한다(통솔→견수, 무력→맹공, 지력→간파, 정치→조달, 매력→격려, 동률은 이 순서). 전수 목록은 생성기 `TRAIT_TYPE`이 정본이고, 장수별 결과는 JSON `by_officer`(`basis`: unique·keyword·stat).

| 유형 | 키워드 근거 | 해당 특성 |
|---|---|---|
| 맹공 firepower | 무용·선봉·정예·토벌·포박·대장군 | 부풍, 금마초, 부자, 강동지호, 선봉, 궁요희, 포박, 산월토벌, 무릉 평정, 이릉 분전, 여강 정예, 대관출전, 대장군, 황수아 |
| 견수 defense | 방어·농성·호위·노장·수비·내구 | 무당비군, 노익장, 고수, 노장, 고절, 종자, 백모병, 만신창이, 변경, 수비, 낭고 |
| 질주 maneuver | 이동·기습·돌파·추격·항행·기동 | 반골, 불안, 소패왕, 백의도강, 주아부의 풍, 교변, 천리구, 호표기, 수군 |
| 격려 morale | 결속·안정·군기·여걸(배정 함대 사기+15%)·인덕·사기 | 인고, 장판, 집행, 조정, 효심, 인덕, 사직지기, 순절, 천하이분, 강동이교, 군기, 국태, 순직, 화평, 원로, 낙신, 내조, 사군자, 유재시거, 호가십팔박, 독안, 진무, 병주 안무, 청주 진무, 조율 |
| 교란 disrupt | 계략·이간·외교·회유·야습·위압 | 오만, 백미, 담병, 봉추, 기모, 변설, 남중 회유, 연인, 금범적, 밀서, 독사, 십이기책, 이간 |
| 간파 detection | 정보·내응·선견·정찰교란 | 내응, 선견, 의성 |
| 조달 supply | 보급·자금·재정·내정·둔전 | 거상, 탁고, 목우유마, 보급, 직백전, 교주, 중신, 청렴, 남방 경략, 교주 경략, 혹리, 왕좌지재, 가재, 관중경영, 구품관인법, 경제, 하동 경영, 염철, 둔전 운영, 둔전 창시, 둔전 호위 |
| (능력치) | 낱말 없음 | 모주, 종실지신, 인단, 호이, 강직, 선양, 은일, 봉천자, 명사, 장형, 하서, 지절, 경학, 칠보, 장자, 돈황, 종군, 청류, 양자, 이반, 직언, 숙련, 원망, 방자, 원한, 역전, 이장, 사위, 사령 |

집계(장수 148명): 고유 12, 키워드 103, 능력치 33. 유형별 장수 수는 조달 37·격려 26·맹공 18·교란 15·견수 18·간파 13·질주 9이다. 조달이 많다(내정형 특성이 많은 본편 특성 분포 때문). 비용 효과가 작은 유형이라 편성 화면에서 기본 슬롯이 조달로 채워지면 손해다 — P8b에서 슬롯 기본 채움은 직책 순이므로 영향이 없고, 밸런스는 P8a 측정에서 본다.

## 4. 데이터 스키마와 AI 조건 문법

기술 항목 키: `id`, `kind`(unique·type), `name`, `trait`(고유만)/`type`(유형만), `officer`(고유만), `target`, `radius`, `duration_s`, `effects`, `requires`, `ai_when`, `relation`, `text`, `status`.

**effects 키(코어가 해석)**: `damage_mul_bp`(내 출력), `damage_taken_mul_bp`(받는 피해, 0=무효), `speed_mul_bp`, `transition_mul_bp`(진형 전환 시간, 0=즉시), `morale_bp`(즉시 가감), `morale_loss_mul_bp`, `hit_bp`(명중률 가감), `sensor_mul_bp`, `reveal_radius`/`reveal_orders`, `range_mul_bp` + `categories`, `charges_add`, `assault_bp`/`assault_cd_reset`/`assault_block`, `chain_power_mul_bp`, `damage_redirect_bp`, `affinity_ignore`, `rescue_equipped`, `in_terrain`(지형 안 덮어쓰기), `only_while: "holding"`, `alias_command: "letter"`. 모든 배율은 bp(10000=1.0).

**requires**(발동 가능 조건, 사람·AI 공통, 미충족 거부 사유 코드로 노출): `has_ship_type`, `enemy_within`, `ally_within`, `ally_flagship_within`, `charges_below_base`, `chain_host`.

**ai_when**(Q91): `{"all": [...]}`(전부) 또는 `{"any": [...]}`(하나). 항목은 술어 하나이며 `requires`도 함께 만족해야 한다.

| 술어 | 뜻 |
|---|---|
| `enemy_in_band: b` | 확인된 적과 거리대가 b(contact·barrage·engagement·assault) 이내 |
| `enemy_within: r` | 확인된 적이 r 이내 |
| `estimated_within: r` | 추정 접촉(안개 포함)이 r 이내 |
| `enemy_flagship_within: r` / `enemy_carrier_within: r` | 적 기함/강습모함 보유 함대가 r 이내 |
| `self_hull_below_bp: x` / `self_morale_below_bp: x` | 자기 선체(척 수 비율)·사기가 x bp 미만 |
| `self_retreating: true` | 자기 후퇴 중 |
| `self_charges_zero: cat` | 해당 무장 범주 횟수 0 |
| `ally_hull_below_bp_within: [x, r]` | r 이내 아군 함대 선체 x 미만 |
| `ally_flagship_within: r` / `ally_flagship_hull_below_bp: x` | 아군 기함 r 이내 / 선체 x 미만 |
| `wind_window_open: true` | 기류 창이 열림 |
| `chain_host_ai: true` | 기존 `chain_host_ai` 규칙이 서신 시점이라 판단 |

평가: AI 결정 틱마다 함대 ID 순 → 슬롯 순, 함대당 한 틱에 하나만 발동(`ai_eval`). 난수 없음 → 결정론. 위임 아군 함대도 같은 규칙. 사람 함대는 AI 발동 대상이 아니다(위임 상태일 때만).

## 5. P8a 구현 메모

- 슬롯은 함대 `skill_slots`(길이 3, 기술 ID 또는 빈칸). 기본값 = 제독·부제독·강습 참모의 `by_officer[id].skill`. 같은 기술이 두 슬롯이면 1회를 공유한다(기술 ID 기준 전투당 1회).
- 편성 검증(`Organization.validate`): 슬롯의 기술은 그 함대 장수가 가진 기술이어야 한다. 장수가 빠지면 자동 재채움.
- 발동 명령 `skill`(슬롯 인덱스). 거부 사유: `skill_used`, `skill_no_slot`, `commander_down`(지휘 불능), `skill_requires_*`(requires 미충족).
- 기간 효과는 함대 상태의 만료 틱 목록으로 두고, 피해·사기·이동·센서 계산이 배율을 곱한다. 겹치는 같은 키 배율은 곱셈. 재생 헤더에는 편성(슬롯 포함)만 기록하고 발동은 명령 로그로 남는다.
- `SK-U-HUANGGAI`는 기존 `letter` 경로를 그대로 부른다. `SK-U-GUANYU`는 강습 `chance_bp`에 더한다(`assault.gd:66` 부근). `escort_trait`(`assault.gd:74`)·`master_trait`(`salvo.gd:118`)는 건드리지 않는다.
- 투영: 아군 함대만 슬롯·남은 횟수·활성 효과 남은 시간을 노출한다(적에게는 숨김, P9a F-8).
- 위험: 맹공·견수·조달이 표준 승률(78~85%)을 크게 흔들 수 있다. P8a에서 표준 200시드 전후 대조(탐색)로 본다. 수치 조정은 데이터(`special_skills`)만 고친다.

## 6. 열린 점 (사용자 확인 대기)

1. 유비군 관우의 만인지적은 강습모함이 0척이라 현재 편성에서 거부된다. 편성 화면에서 SHP-01을 넣었을 때만 쓴다(Q68 수용 사항과 일관). 다르게 하려면 `requires`를 지운다.
2. 유형이 7개로 조달이 37명이다. 6개로 줄이려면 조달을 격려/맹공에 합친다.
3. 장수당 기술 1개(첫 특성)로 정했다. 특성이 여러 개인 장수는 본편 데이터상 없다(「」 첫 항목만 읽는 `P()`의 기존 동작).
