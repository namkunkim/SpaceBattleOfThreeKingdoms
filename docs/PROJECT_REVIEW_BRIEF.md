# 프로젝트 리뷰 브리프 — 성한지 우주함대 3D 실시간 전투 (SpaceBattleOfThreeKingdoms)

> **과거 기록 (2026-10-03 표시):** 이 브리프는 커밋 `1416797` 시점의 상태다. 이후 레거시 2D POC(`Main.gd`, `Main.tscn`)를 삭제했고, `tests/smoke.gd`는 메인 씬(`FleetBattle3D`)을 검증하며, 런처는 `GODOT_EXE` 환경변수와 PATH로 Godot을 찾는다. 현행 계획은 `docs/battle-core/`를 본다.

> 작성일: 2026-10-03 · 대상: 다른 세션/리뷰어 · 기준 커밋: `1416797` (main)
> 이 문서는 저장소 상태(코드·커밋·문서)를 읽고 정리한 것이다. 실행·테스트는 이번 정리 중 수행하지 않았다.

## 1. 한 줄 요약

삼국지 적벽 컨셉을 은하영웅전설풍 우주함대전으로 옮긴 **실시간 전술(RTS) 3D 전투 프로토타입(POC)**. Godot 4.7 + GDScript로 만들었고, 먼저 웹(HTML)에서 규칙을 프로토타이핑한 뒤 Godot 3D로 이식했다. 상품 수준이 아닌 POC이며, 상위 프로젝트 "성한지"(턴제 캠페인)의 전투 코어 후보를 검증하는 용도다.

## 2. 사용 언어·기술 스택

| 영역 | 내용 |
|---|---|
| 엔진 | Godot 4.7(.2 stable), 렌더러 `gl_compatibility`, 1600×900, stretch `canvas_items` |
| 주 언어 | **GDScript** (`scripts/*.gd`, `tests/*.gd`) |
| 보조 언어 | **HTML/CSS/JavaScript** 단일 파일 프로토타입(`altair-corridor.html`, 852줄), **Python**(Blender 스크립트 `tools/blender/*.py`), Windows `.cmd` 런처 |
| 3D 자산 | 사용자 제공 ver3 GLB 7종(런타임, LOD 최적화), Quaternius CC0 FBX 7종(대체/레거시) |
| 2D 자산 | ImageGen(OpenAI 내장) 생성 배경·초상·VFX 시트, 사용자 제공 함선 컨셉 PNG |
| UI | 코드로 구성한 Control 노드(HUD 전부 스크립트에서 생성), `_draw` 기반 오버레이/레이더 |
| 문서 언어 | 한국어 (코드 주석·UI 문구·문서 모두 한국어) |

## 3. 저장소 구조

```
project.godot            메인 씬 = scenes/FleetBattle3D.tscn
scenes/FleetBattle3D.tscn  현재 메인(3D 전투, 스크립트 1개만 붙은 Node3D)
scenes/Main.tscn           레거시 2D 함대전 POC (비교·회귀용)
scripts/FleetBattle3D.gd   3D 전투 전체 (≈1,830줄, 핵심)
scripts/Main.gd            레거시 2D POC (≈660줄)
scripts/RadarControl.gd    레이더 컨트롤
altair-corridor.html       HTML 프로토타입(플레이 규칙의 원본 참조)
tests/                     smoke / 모델 감사 / 캡처 검증 스크립트 (SceneTree 헤드리스 방식)
tools/blender/             ver3 모델 최적화·방향 검수 Blender 스크립트
assets/                    models, backgrounds, portraits, vfx, concepts + ASSET_NOTES.md
docs/research/             은하영웅전설 III/IV/VII 조사, 성한지 적용성, POC 보고서 (한국어)
플레이하기.cmd             Godot 실행 파일 경로를 하드코딩해 게임 실행
플레이_조작법.md/.txt      조작·규칙 요약
```

## 4. 지금까지 한 일 (커밋 이력)

- `a1cc1f0 init` — Godot 프로젝트 초기 반입: 레거시 2D POC(`Main.gd`), 3D POC 1~3차(모델·VFX·HUD), 에셋 일체, 조사 문서 5건.
- `f475560 HTML 알타이르 회랑 플레이를 Godot 3D 전투로 이식` — `altair-corridor.html`의 규칙과 HUD를 `FleetBattle3D.gd`로 이식(아래 5장).
- `1416797 Merge feature/altair-corridor-gameplay` — 위 기능 브랜치를 main에 병합.

(POC 문서상의 v1.0→v1.2 진화: 2D 스프라이트 → 3D 모델 배치 → 성운 배경·보호막·레이더·VFX → 모델 바운딩박스 기준 크기 정규화 → 함선 시각 크기 1/3 축소·함대당 편제 확대. 상세는 `docs/research/visible-fleet-battle-poc-report-ko.md`.)

## 5. 현재 보이는/동작하는 것 (게임 내용)

**시나리오**: 아군 6개 함대(유비·관우·제갈량·조운·마초·장비) 대 적 7개 함대(조조 등) + 약 95초 후 측면에 나타나는 별동대 2개(하후연·장합). 기함 격침 = 패배, 적 전멸 = 승리.

**전투 규칙(실시간)**
- 커맨드 포인트(CP) 소모 특수 명령: 미사일 일제사격(2)·함재기 발진(3)·전 함대 돌격(3).
- 측면 공격 +30%, 배후 +60%, 기함 지휘 범위(`CMD_R`) 밖 함대는 화력 −25%.
- 적 AI, 증원 스폰, 사기/격침 처리, 2배속·일시정지.

**함대 구성**: 함대당 28척 가시 함선(전열 11 / 화력 6 / 항모 4 / 전자전 3 / 공성 1 / 보급 3), 함대별 고유 진형 10종(횡진·쐐기진·방진·종진·원진·학익진·사선진·어린진·안행진·장사진). 전 함대 선택 후 대형 유지 일괄 이동 지원.

**화면/HUD**: 3D 원근 카메라(고정 피치 68°), 성운 배경, 선택 함대 보호막 돔, 함대 상태 태그, CP 바, 로그, 원형 레이더(클릭 점프), 지휘관 초상 정보 패널, 그룹 탭 I–IV, 명령 패널, 엔진 발광·항적·빔·폭발·파편 VFX.

**조작**: 클릭/드래그/Shift 선택, 우클릭 이동·공격, 단축키 S/D/M/F/C/R/G/A, 숫자 그룹, 휠 줌, 방향키/우클릭 드래그 카메라, Space 일시정지. (`플레이_조작법.md`)

## 6. 개발 방식

1. **조사 → 설계 → POC** 순서. 먼저 `docs/research/`에 원작(은하영웅전설) 규칙과 성한지 적용성을 분석한 뒤, "코드로 이식 가능한가"를 POC로 검증했다.
2. **HTML로 플레이 규칙을 선행 프로토타이핑**(`altair-corridor.html`) 후 Godot로 포팅 → 규칙 튜닝 비용을 낮추려는 접근.
3. **AI 협업 개발**: 코드·문서·에셋 일부를 Claude Code 및 ImageGen이 생성(커밋에 `Co-Authored-By: Claude` 표기). 생성 프롬프트와 출처는 `assets/ASSET_NOTES.md`에 기록.
4. **단일 거대 스크립트 구조**: 시뮬레이션·렌더링·HUD·입력이 `FleetBattle3D.gd` 한 파일에 공존(내부 클래스 `Fleet/Missile/Swarm/Part/Floaty`). HUD는 씬 파일 없이 코드로 생성.
5. **2D 좌표 시뮬레이션 + 3D 표현 분리**: 시뮬레이션은 `Vector2` 월드(3400×2300)에서 돌고 `w3()`로 3D에 투영, `_sync_3d()`가 노드를 동기화.
6. **검증은 헤드리스 스크립트 + 캡처**: `tests/*.gd`는 `SceneTree` 상속 스크립트로 assert 후 `quit()`, 캡처 PNG를 `out/`에 저장(`out/`은 현재 저장소에 없음).
7. **에셋 정책**: 원본(`user_ver3`)은 보존, 런타임용은 Blender 스크립트로 삼각형 수를 2.5만~6만으로 축소한 `user_ver3_runtime`을 사용. GLB 내장 PBR 재질 유지, 모델 +X 선수를 게임 −Z 전방으로 90° 보정.

## 7. 실행·검증 방법

```
플레이하기.cmd                      # 내부에 C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe 하드코딩
godot --path . --headless -s tests/smoke.gd              # 레거시 2D(Main.tscn) 스모크
godot --path . -s tests/capture_3d_poc.gd                # 3D 전투 시작·일괄 이동 검증 + 캡처
godot --path . --headless -s tests/audit_3d_models.gd    # 모델 감사
godot --path . --headless -s tests/audit_user_ver3_models.gd
```

## 8. 리뷰어가 특히 봐줬으면 하는 지점 / 알려진 문제

사실로 확인한 것:
- `tests/smoke.gd`는 **레거시 `Main.tscn`만** 검증한다. 현재 메인인 `FleetBattle3D`에는 `capture_3d_poc.gd`의 이동 검증 외에 전투 규칙(측면 보너스, 지휘 범위, CP, AI, 증원, 승패) 단위 테스트가 없다.
- `ASSET_NOTES.md`와 레거시 코드/테스트(`smoke.gd`)는 `assets/ships/…` 시트를 가리키지만 **저장소에 `assets/ships/`가 없다**(기록과 실제 불일치 가능성; 레거시 2D 씬 로드 시 영향 확인 필요).
- 런처 `.cmd`의 Godot 경로가 개발자 PC 고정값이다. `config/features`는 `4.7`.
- 조사 문서는 작성 당시 경로(`C:\WorkSpace\Re_Legend_of_the_Galactic_Heroes`)와 `out/` 산출물을 언급하나 이 저장소에는 없다.
- 문서(`visible-fleet-battle-poc-report`)의 "함대당 34척·204척"과 현재 코드의 "함대당 28척(`MAX_VISIBLE=28`)·6 vs 7+2 함대"는 서로 다른 시점의 기록이다(문서가 최신 코드보다 뒤처짐).

검토 권장 질문:
- 단일 1,800줄 스크립트를 시뮬레이션 / 렌더 / HUD / 입력으로 분리해야 할 시점인가?
- HTML 원본과 Godot 이식본 사이 규칙 수치(보너스, CP 비용, 쿨다운, AI 행동)가 정확히 일치하는가? (`altair-corridor.html` ↔ `FleetBattle3D.gd` 대조)
- 프레임 단위 `update_sim`의 성능(함대당 28노드 × 15개 함대, 빔/파편 생성) 및 `delta` 의존성·결정성.
- 레거시 2D 코드를 유지할 가치가 있는가, 아니면 제거/격리할 것인가.
- 에셋 라이선스: Quaternius는 CC0, 사용자 제공 ver3는 "사용자 확인, 제한 없음"(문서상 구두 확인), ImageGen 생성물은 POC 한정이며 상품화 전 별도 검토 필요(`ASSET_NOTES.md`에 명시).

## 9. 한계 / 다음 단계(문서 기준)

- POC이며 상품화·성한지 본 저장소 반영은 **미승인**.
- 전용 강습항모 모델·모델 구조 수정·GLB 표준화 일부 미수행.
- 후속 후보(VII 분석 문서): 제자리 선회, 평행 이동, 전력 배분, 자동 교전 태세, 전장 이탈 등.

## 10. 핵심 파일 바로가기

- 3D 전투 본체: `scripts/FleetBattle3D.gd` (시뮬 `update_sim`, 명령 `do_cmd`, 적 AI `enemy_ai`, HUD `_build_hud`, 진형 `formation_offsets`)
- 규칙 원본(참조): `altair-corridor.html`
- 에셋 출처·정책: `assets/ASSET_NOTES.md`
- POC 보고서: `docs/research/visible-fleet-battle-poc-report-ko.md`
- 조작법: `플레이_조작법.md`
