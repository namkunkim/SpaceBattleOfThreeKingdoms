# 이어받기 프롬프트: 방공·함재기 대응 발진 (2026-10-18)

아래를 새 세션에 그대로 붙여 넣는다.

---

방공·함재기 대응 발진을 피처 브랜치에서 컨셉 검토부터 구현까지 이어서 진행해. main에는 반영하지 않는다. 확인 없이 진행하고, 결정이 필요한 것만 묻는다.

- 작업 위치: worktree `C:\WorkSpace\SpaceBattleOfThreeKingdoms\worktrees\air-defense`, 브랜치 `feature/air-defense`(main e921d7d에서 분기). 공유 폴더(원래 폴더)는 main에 두고 건드리지 않는다. 브랜치만 푸시한다.
- 요구(사용자, `CHECKLIST-OPEN.md` 맨 끝 대기열 항목): ① 요격함(SHP-07)·강습모함(SHP-01)·고속정(SHP-08)이 있으면 전투기·미사일에 대한 방공이 가능하다. ② 아군이 전투기를 발진하면 적 함대도 전투기 발진으로 대응할 수 있다(양쪽 모두). 선행: 적 함대 규모를 파악하고, 아군에 비해 적절한지 검토한다.

## 이미 파악한 것

- 본편(`C:\WorkSpace\Seonghanji\data`)에는 방공 규칙이 없다. `ship-types.json`에는 함종마다 `근접 방어` 기수만 있다(요격함·강습모함 16, 나머지 6~12). `red-cliffs-interception-rules.json`은 경로 교차·기회 사격 규칙이라 방공과 무관하다. 그래서 수치는 `proposed`로 둔다.
- 사격 구조(`core/battle/salvo.gd`): 범주 `artillery, line_fire, intercept, torpedo, fighter`. 미사일 명령 = `artillery` 범주, 함재기 = `fighter` 범주(SHP-01). 둘 다 횟수 범주(`charges`, 3회)이고, 60초 주기마다 자동 사격한다. 명중 판정은 일제사격당 한 번이다(`hit_bp` → `_plan_shot` → `_resolve`). `evasion_bp`(Q72)가 `hit_bp`의 방어항에 더해지는 선례다.
- `data/profiles/combat_m3.json`은 `tools/scenario/make_combat_m3.py`로 만들지만 **생성기가 이미 JSON과 어긋나 있다**(PoC 적용 때 JSON만 고침: movement `flip_over_deg` 등, detection `view_r`·`radar_r`). 재생성하지 말고 JSON과 생성기를 둘 다 직접 고친다.
- 실제 전투 편성(자동 편성 `Organization.auto_fill`, 측정 스크립트 `scratchpad/dump_roster.gd`와 같은 방식):
  - 연합 6함대, 비용 4022: 모함 35, 포격 70, 전열 143, 보급 35, 전자전 33, 요격 71, 고속정 24(정찰 23·뇌격 1)
  - 조조 입문 9함대 5912(1.47배), 표준 10함대 6395(1.59배), 상급·극한 14함대 8604(2.14배). 함대당 규모는 양쪽이 비슷하다(약 650). 비율은 함대 수에서만 나온다.
  - `auto_fill`이 모든 함대를 같은 MIX 비율(전열4·포격2·요격2·보급1·모함1·전자전1)로 다시 채운다. 그래서 거의 모든 함대가 모함 약 6척·요격함 약 12척을 가진다. 방공은 "있다/없다"가 아니라 **비율 기반**이어야 의미가 있다.
  - **발견(사용자 결정 필요, 이번 범위 밖):** `auto_fill`이 시나리오의 함대 개성을 지운다. 황개 화공대의 뇌격 고속정 24척은 1척으로, 조순 호표 고속대(요격함 18·요격 고속정 30)는 일반 혼성 함대로 바뀐다. 방공 전문 함대가 사라진다.
  - 규모 적절성: 비용비는 난이도 목표와 같다. 기존 측정은 입문 무명령 연합 승률 70.8%(96시드), 표준 43%다. O3c 재측정은 아직 대기 중이다. 역사적으로 조조 우세라 비율 자체는 타당하다.

## 정한 설계(구현 직전에 멈춤, 코드 변경 없음)

1. **방공 bp** `air_defense_bp(tgt, cat)`(salvo.gd, `evasion_bp` 옆). `hit_bp`에서 `defense += air_defense_bp(tgt, cat)`.
   - 대상 범주: `fighter`, `artillery`(미사일). 뇌격(`torpedo`) 포함 여부는 미결이다(사용자 문구는 전투기·미사일).
   - 값 = min(max_bp, Σ(유효 척 수 `effective_of` × 함종 가중 bp) / `present_ships`). 고속정은 장비가 `FAST-EQ-INTERCEPT`일 때만 센다.
   - 제안값(`combat.air_defense`): SHP-07 4000, SHP-01 2000, SHP-08(요격) 3000, max_bp 1500. 보통 함대는 (12×4000 + 6×2000) / 68 ≈ 880bp(약 −9%p)이고, 요격 전문 함대는 상한 1500에 닿는다.
2. **대응 발진**: `_resolve`에서 `fighter` 일제사격의 표적이 살아 있고 퇴각 중이 아니면 `pull(tgt, "fighter")`로 다음 주기를 당긴다(그 함대의 횟수·사거리 규칙을 그대로 따른다). 당겨졌으면 `say`를 낸다(연합 "fighter", 조조 "ai_fighter", 기존 키).
   - **연쇄 방지:** 대응 발진으로 쏜 일제사격은 다시 대응 발진을 부르지 않는다(salvo에 `countered` 사전, 쏠 때 `erase`하고 shot에 `counter: true`). 이것이 없으면 양쪽 3회가 즉시 핑퐁으로 바닥난다.
   - 데이터 `combat.air_defense.counter_launch: true`. 미결: 플레이어 쪽 자동 대응 발진이 횟수를 마음대로 쓰는 것을 허용할지(기본은 양쪽 자동).
3. 테스트 `tests/air_defense.gd`(`tests/evasion.gd` 틀, `SalvoFixture`): 데이터 존재, 범주 제한, 비율 계산·상한, 요격 장비 고속정만 계산, `hit_bp` 감소, 대응 발진(next_fire 당김·횟수 소비), 연쇄 없음, 같은 시드 지문 동일.
4. 회귀: 헤드리스 전체(`salvo_compare`는 `--runs 10`, 단독·순차. 새 class_name 없음). 지문이 바뀌므로 기준선 측정은 대기열(O3c와 묶음).
5. 문서: `BATTLE_DECISIONS.md`에 새 Q 번호로 제안값·미결 기록, `CHECKLIST-OPEN.md` 항목 갱신. 다른 모델로 리뷰한다(구현 모델과 다르게).

## 마지막 상태

- 브랜치 커밋: b7b73a6(대기열 기록) + 이 프롬프트 파일.
- worktree에는 `--import` 때문에 `*.import` 파일 변경이 많다. 커밋하지 않는다. 필요한 파일만 `git add`한다.
- Godot: `C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/<name>.gd`. 종료는 자기 PID만 한다.
