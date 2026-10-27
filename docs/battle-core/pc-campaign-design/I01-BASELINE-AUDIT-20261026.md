# I01 준비 — O06 최신 로컬 기준·변경 경계 읽기 감사

2026-10-26 / handoff_execution / **읽기 감사·미확인 소유/PC 작업 상태 OPEN / 게임 코드 착수 승인 아님**.

입력: [플레이북](../../../워크플로우-플레이북.md), [구현 준비 스펙 I01](IMPLEMENTATION-SPEC-20261026.md), [사전 측정 계획 PR01](MEASUREMENT-PLAN-20261026.md), [준비 문서 독립 검토](REVIEW-IMPLEMENTATION-PREP-20261026.md), [H2](H2-DECISION.md). 사용자는 최신 코드/변경 소유의 읽기 확인·I01 공간/상태 입력 계약·측정 사전등록 준비를 승인했다. 이번 실행자는 지정 감사 문서 하나만 쓰며 코드·데이터·게임/테스트·브랜치/설정 변경·fetch·병합·커밋·푸시는 하지 않는다.

## 1. 관측 시점과 재현 근거

정상 조회 시각은 PowerShell `Get-Date -Format o`의 **2026-10-26T14:47:33.1659388+09:00**이다. 아래는 그 시점부 로컬 관측이며 최종 실행 직전에 다시 유효성을 확인해야 한다. 이후 다른 세션의 변경 가능성을 배제하지 않는다.

| ID | 읽기 명령·근거 | 관측과 해석 |
|---|---|---|
| B01 | `git branch --show-current`, `git rev-parse HEAD origin/main` | 현재 checkout은 `main`. HEAD와 로컬 `origin/main` 참조 모두 `93e60e6a957ffdb002a1cb06bc796c4c46496736`. fetch하지 않았으므로 원격 서버 최신성 증거가 아니다. |
| B02 | `git log -5 --oneline` | main 최근 3개는 `93e60e6` 결과 UI, `e1afc3a` 적 후방 편성/역할, `ce6eb51` 다국어. 공통조상 `254e056` 이후 변경이다. 구 PC 15판을 현재 밸런스 기준선으로 사용하지 않는다. |
| B03 | `git status --short --untracked-files=no`, `git diff --cached --name-status`, `git diff --numstat` | tracked dirty 15개, staged 출력 없음, 합계391추가/44삭제. untracked도 다수 관측됐지만 이번 감사에서 전 파일 소유·완전 목록을 확정하지 않았다. |
| B04 | `git worktree list --porcelain` | 현재 경로 외 PC checkout 등록: `C:/Users/nk782/.codex/worktrees/pc-ten-minute-battle-review/SpaceBattleOfThreeKingdoms`, 등록 HEAD `5264543b58919f906bcc8cf81a6be08dc55acc2a`, branch `codex/pc-ten-minute-battle-review`. 등록 메타데이터이지 실제 작업 내용 청결 증거가 아니다. |
| B05 | `git merge-base HEAD codex/pc-ten-minute-battle-review`, `git rev-list --left-right --count HEAD...codex/pc-ten-minute-battle-review` | 공통조상 `254e056f133e50aff8773d0a8209c98b2a4c1d6c`, main쪽3/PC쪽1 커밋. 브랜치 분기 정보이며 병합 가능 판정이 아니다. |
| B06 | `git diff --name-status HEAD...codex/pc-ten-minute-battle-review` | PC쪽 고유 변경14파일. 새 실험 모듈/보고서/JSON/검사/실행 도구와 기존 host·pacing·trace 수정. 삼중점 비교는 공통조상→PC쪽 변화이며 전체 현재 checkout 차이가 아니다. |
| B07 | I01 후보 경로를 명시한 `git status --short --untracked-files=all -- <paths>` | §3의 명시 후보에는 출력 없음. 이번 경로 집합의 tracked/untracked 변경 부재만 의미하며 저장소 전체 청결·소유 해결을 뜻하지 않는다. |
| B08 | `git diff -- project.godot core/battle/bundle_layout.gd tests/bundle_layout.gd` | project는 아이콘 경로2줄 추가. BundleLayout은 선택 수별 전체 진형 슬롯·전환 진형 외곽·전장 맞춤 축소 변경, 해당 검사도 변경. 공간/진형 측정의 간접 영향이 있다. 기능 시험은 하지 않았다. |

PC의 `git -C <PC경로> rev-parse HEAD`와 `status --short --untracked-files=no`는 **Permission denied**로 정상 조회하지 못했다. `.git` 텍스트는 main의 `.git/worktrees/SpaceBattleOfThreeKingdoms`를 가리킨다. 이 실패를 기존의 `core.bare` 원인으로 단정하지 않았다. 중요한 읽기 명령의 권한 실패에 따라 `require_escalated`로 동일 status를 요청했으나 **526.2초 승인/도구 대기 후 중단됐고 정상 결과는 없다**. 거부됐다고 단정하거나 다른 방식으로 승인을 우회하지 않았다. 이번에는 추가 진단·재시도를 중단하고 PC 실제 HEAD/status·청결·미커밋 소유를 OPEN으로 남긴다.

## 2. dirty 변경과 소유 근거

| 묶음 | 관측 경로 | 소유 판정·처리 |
|---|---|---|
| 진형 공간 | `core/battle/bundle_layout.gd`, `tests/bundle_layout.gd` | **unknown**. 실제 diff로 공간 영향은 확인. 이름이 비슷한 다른 채팅이 있다는 이유로 작성자를 확정하지 않는다. 측정 시 이 diff 포함/제외를 명시해야 한다. |
| 진형 가이드/UI | `data/fleet-role-layout.md`, `hud/ui_kit/formation_guide.gd`, `tests/formation_guide_ui.gd`, `docs/ui/FLEET-ROLE-LAYOUT.md`, `FORMATION-TAB-SPEC.md`, `fleet-formations.fragment.html`, `fleet-formations.html` | **unknown**. 기존 외부 변경 보존, 이번 I01 코드 변경으로 묶지 않는다. |
| 화면 참고/검토 | `docs/battle-core/VIDEO-LOGH7-FLEET-MOTION.md`, `docs/poc/fleet-motion-ref/index.html`, `플레이_조작법.md` | **unknown**. 문서·참고 구현 변경은 읽기 상태만 확인. |
| 프로젝트/내보내기 | `project.godot`, `export_presets.cfg` | **unknown**. project 아이콘2줄은 정적 diff 확인. 향후 설정/host 작업과 겹칠 수 있으므로 보존·별도 hunk 경계 필요. |
| 체크리스트 | `docs/battle-core/CHECKLIST-OPEN.md` | 이번 대화에서 기록한 PC 캠페인 블록은 결정 원본/앞선 기록으로 추적 가능. 파일 전체 변경의 배타적 소유는 **unknown**. |
| untracked | 산출물·브랜딩·실행 파일·다수 `.import`/`.uid`/번역 파일·새 검사·`tmp/`·본 캠페인 문서 등 | 일부 문서 출처를 알아도 전체 소유는 **unknown**. 무시·삭제·일괄 add·restore·clean하지 않는다. |

`list_artifacts`는 현재 채팅의 attachment를 빈 배열로 반환했다. `list_threads(limit:12)`에서 같은 저장소의 「(TODO) 선택 함대 진형 정렬 검토」, 「(TODO) PC 플레이용 맵 확장 검토」 등은 notLoaded였고 현재 캠페인 채팅은 active였다. **notLoaded는 변경 소유 해제나 파일 잠금 보장이 아니며**, 이 목록은 모든 실행자·외부 편집을 증명하지 않는다. 다른 채팅으로 메시지를 보내거나 앱 상태를 바꾸지 않았다.

## 3. I01 직접·간접 겹침

출력 없는 명시 경로: `core/battle/profile_loader.gd`, `scenario_profile.gd`, `scripts/FleetBattle3D.gd`, `core/battle/battle_sim.gd`, `terrain.gd`, `detection.gd`, `view/camera_rig.gd`, `hud/ui_kit/tactical_overlay.gd`, `battle_state.gd`, `fleet_state.gd`, `battle_fingerprint.gd`, `data/scenarios/`, `data/profiles/`, `tools/scenario/make_combat_m3.py`, `tests/data_rules.gd`, `terrain_display.gd`, `pacing.gd`, `battle_flow.gd`, `boundary.gd`, `battle_trace.gd`。

- 현재 I01 명시 후보와 직접 dirty 경로 겹침은 이 관측에서 없었다. 그러나 새 파일 이름·최종 공유 변경 목록은 아직 확정되지 않았다.
- BundleLayout 변경은 최대 진형·전환 중 외곽·그룹 공간 측정의 **간접 겹침**이다. HEAD만으로 측정할지 현재 diff를 포함할지 명시하지 않고 O03/A04를 판정할 수 없다.
- PC 커밋쪽의 공유 변경은 `scripts/FleetBattle3D.gd`, `hud/ui_kit/battle_pacing.gd`, `scripts/battle_trace.gd`다. 새 파일은 `core/battle/pc_battle_experiment.gd`, PC검사2개, `tools/run_pc_battle.ps1`, 검토/원시결과 문서7개다. 이 목록은 재사용 검토 후보이지 복사/병합 승인 목록이 아니다.
- 별도 작전의 opt-in 입력 계약을 문서화하는 데 PC 실험 전체 병합은 선행 조건이 아니다. 실험의 확대/감속 변환·측정 패턴을 비교할 수 있지만, 기존 규칙 보존과 새 공통 변환 계약을 먼저 정해야 한다.

## 4. 권고 경계와 후속 선택

| 항목 | 권고·지금 가능한 것 | 차단/필요한 확인 |
|---|---|---|
| 현재 준비 | 현재 HEAD와 관측 diff를 입력 출처로 명시한 **문서 계약·사전등록 초안**은 계속 작성 | dirty를 모두 이번 작업 것으로 취급하거나 전체 baseline PASS 불가 |
| I01 변경 목록 | 기본은 신규 opt-in 정의/검증·실효설정과 최소 공유 분기 후보. 현재 외부 dirty hunk는 건드리지 않는 경계 권고 | 정확 경로·공유 hunk·정본/생성물 책임, 사용 작업트리·소유를 코드 착수 전에 확정 |
| 공간 기준 | BundleLayout의 HEAD판과 현재 dirty판을 후보 기준으로 구분하고 채택 근거 기록 | 소유·편성/진형 기준 없이 최신판이라고 자동 채택 금지. 측정/코드 실행은 미승인 |
| PC 활용 | 커밋 메타데이터와 기존 정적 실험 근거 활용, 통합은 보류 | 실제 PC 작업상태·공유 변경 대조·원격 최신성/통합 확인이 남음 |
| 작업 경로 | 현재 checkout은 외부 변경을 전부 보존. 기존 PC checkout을 재설정하거나 정리하지 않음 | 새/기존 작업트리 선택은 후속 승인된 변경 범위와 소유 확인 뒤 결정. attachment 없음만으로 새 checkout을 만들지 않음 |

이번 감사는 O06의 로컬 기준·직접 겹침을 일부 해소했지만 **소유 불명·PC 실제 상태·원격 최신성·실제 통합 가능성을 해소하지 않았다**. 코드 착수는 계속 차단된다. 사용자 판단이 필요하면 위 근거를 제시해 ‘진형 dirty 포함/제외 기준’과 ‘소유 확인된 허용 변경 경계’를 정하며, 읽기 근거 조사 없이 전체 작업을 중단하는 질문부터 만들지 않는다. 미확인 외부 변경은 유지한다.

## 5. 자체 5-a·독립 인계

문서 K=3. 확인 항목은 관측 시각·HEAD/로컬 추적 구분, dirty15개와 stage 없음, PC3/1 분기·삼중점의 의미, I01 직접/간접 겹침, unknown 소유·실패/중단 상태, 허용 쓰기1문서·게임 비승인·O06 잔여 게이트다. 링크·수치·공백은 문서상 검사하며 게임·로그·저장·성능·1000시드·사람 플레이 시험은 실행하지 않는다.

독립 검토자는 관측과 단정의 경계·현재 입력 계약에 연결할 수 있는 범위를 확인한다. 작성자가 자기 정확성을 5-b 수용으로 선언하지 않는다. 원격·브랜치·설정·기존 파일은 변경하지 않았고, 본 감사 문서만 작성했다.
