# 홈 화면 재디자인 인수 메모 (2026-10-04, 클라우드 세션)

요청: 본편(`namkunkim/seonghanji`) 스펙의 홈 화면·은하 지도를 파악하고, 상세 전투 화면과 연동되도록 홈 화면을 **상품화 수준**으로 새로 디자인해 **HTML**로 작성한다. **v1 작성 완료:** `docs/ui/mockup-home-v1.html` (생성기 `tools/ui/build_home_mockup.py` + 템플릿 `tools/ui/home_v1_template.html`). 상태 ①~④는 주소 끝 `#pre` `#open` `#entry` `#result`로 바로 연다.

## 본편 스펙 근거 (namkunkim/seonghanji)
- `docs/06-tech/map-ux-concept.md` §3 연속 확대 Z0~Z4, §4 지형 색(검정=통행, 녹색 농도=장애물), §5 항로 표시, **§6 화면 배치**(상단 좌 세력·자원·천명 / 중앙 시각·위치 / 우 일시정지·재개·변경 대기 n, 좌 접이식 필터, 우 함대 목록→상세, 하단 대상 요약·명령), §9.1 함대전(같은 위치·지형·함대가 상세 전장으로), §12 인수 기준
- `docs/06-tech/screens.md` §1.2 시각 바(「건안 십삼년 시월 ▶▶ ×2 대기 결정 3 ⚑ 2」), §1 비차단 규약, §2 SC-L2 성역 뷰, **§11 SC-INT 배너**(시각 바 아래 1행, 기한 카운트다운, 만료 시 기본 처리→브리핑 로그)
- `docs/06-tech/ui-design.md` §3.3 성도 표시 규칙, §4.1 복귀 브리핑, §4.3 전투 화면
- `docs/01-world/star-map.md` §1 성계 19, §1.3 태양계(구지·형혹·태음)=형주, §6.1 적벽 전야 208 세력 배치
- `docs/01-world/galaxy-map-coordinates.md`, `data/maps/galaxy-map.json`(권역 경계·항로 곡선·지형 밀도 field·천체 245) — 지도는 실제 데이터로 그린다
- `docs/07-production/visual-direction-guide.md` §2.1 색(배경 #0E1116, 패널 #161B23/#1E2634, 본문 #D9DFE8, 금 #D8B46A는 주권역·지휘 권위·확정에만, 고속항로 #5FB6BD, 회랑 #C2705C 이중선, 기저항로 #55606F 실선, 위험 #C8544A), §3 UI 원칙, §4.5 아이콘(색만으로 구분 금지, 점선은 관측 신선도 전용, 아이콘에 한자 금지), Noto Sans KR 400/700
- `docs/07-production/red-cliffs-active-battle-contract.md` §5 상태(pending→active→resolved/invalidated), §6 필드, §9 HomeMapSnapshot 소비 계약, §10 배너·진입(battle_id + can_open만 넘김)
- `g10-ui02/03/04`: 배너 「적벽 전투 개전 · 전투 진입」, 전투 셸, 「천하도로 돌아가기」로 동일 홈 복원. canonical ID `SCN-03-E09-RED-CLIFF-01`, 표시 ID `BATTLE-RED-CLIFF`, 「적벽 대회전」, 「구지 궤도」
- `demo-rc-01`/`05`: 1차 데모는 유비 플레이, 홈 생략·결과 화면이 종료점. 상품 홈 설계는 전체 루프(홈→전투→결과→홈)를 다루고 데모 경로는 별도 표시
- 본편 구현: `scripts/Main.gd`(메뉴 01 천하도~08 기록, 자원 바, 시맨틱 줌 천하도→형주성역→태양계권→구지 궤도→적벽, 적벽 조건 ✓✕…), `app/home_map_snapshot.gd`(개전 조건 5종 키), `app/views/ui_palette.gd`

## 전투 쪽 (이 저장소)
- 상세 전투 목업 `docs/ui/mockup-battle-v2.html`: 상단 양측 전력%·5국면(접적·포화·교전·강습·결착)·07:42/20:00, 좌 교신 기록, 하단 선택 함대 패널, 우하 명령 덱, 전술도, 작전 목표
- 흐름: 타이틀(전투 허브)→브리핑→전투→일시정지·설정→결과 (`docs/ui/UI-FLEET-VISUALS.md`)
- 테마 `hud/ui_kit/ui_theme.gd`(금 #c9a45c, 아군 #5fe0cf, 적 #ff7550), 세력 `factions.gd`(촉 사각·위 마름모·오 원, 한자 글리프), 서체 Pretendard·본명조

## 발견한 정합 문제 (설계에서 해결·명시할 것)
1. 세력 색이 세 곳에서 다르다: `galaxy.json`(위 청·촉 녹·오 적), 본편 `ui_palette`(조조 #6f8fd0·손권 #6fc08a, 유비 없음), 전투 `factions.gd`(촉 청록·위 주황·오 보라). 홈·전투 공용 세력 표를 제안해야 한다.
2. 금색·본문색·서체가 홈(#D8B46A, Noto Sans KR)과 전투(#c9a45c, Pretendard)에서 다르다 → 공용 토큰 제안.
3. 전투 HUD의 한자 글리프는 본편 가이드(아이콘 한자 금지)와 충돌.
4. 본편 홈은 손권 시점, 데모는 유비 시점.
5. 본편 홈 배경 이미지(성운 페인팅)는 지도 UX(검정+녹색 밀도)와 다르다.

## 다음 할 일
1. `data/maps/galaxy-map.json`에서 권역 경계·항로·회랑·성계·지형 밀도를 줄여 뽑는 스크립트(`tools/ui/` 등)를 만들고 HTML에 넣는다.
2. `docs/ui/mockup-home-v1.html` 작성: 천하도(Z0, 208 소유) + 시각 바 + 적벽 배너 + 개전 조건 + 전투 진입 시트(참가 함대·지휘관·지형·승리 조건) + 결과 복귀 상태(손실·장수·권역 변화) + 공용 토큰. 16:9·16:10, PC 우선·태블릿 대응.
3. Playwright로 1회 렌더 확인(`node` 전역 playwright 사용), 브랜치 `claude/beautiful-fermat-9g85wv`에 커밋·푸시, 아티팩트 게시.

## v2 (2026-10-04)
- `docs/ui/mockup-home-v2.html` (템플릿 `tools/ui/home_v2_template.html`). v1 검토 결과를 반영해 본편 홈 구현 요소를 빼고 스펙만 따랐다.
- 지도 전체 화면 + 가장자리 네 자리(상단 띠, 우측 함대 띠, 좌하 확대 3단계, 선택 시 하단 상황 카드). 터치 48px, 두 손가락 확대·두 번 탭.
- 지도: 밀도 등고선 40%·70%, 통과 불가 빗금, 좌표 격자, 세력 테두리, 조조 대 손유 전선, 보급선, 관문 협착 기호, 성계 소유 파이, 전장 단계 태양계 천체.
- 페이지 아래 문서에 v1→v2 반영표와 범례가 있다.
