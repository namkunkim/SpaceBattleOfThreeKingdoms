# 새 장수 초상의 Godot 연결

2026-10-18. 런타임 초상은 `assets/portraits/seonghanji/`의 승인본 501장을 사용한다. 제작 원본/태그는 `output/seonghanji-portraits-distinct-20261017/`에 유지한다. `output/.gdignore`는 제작·복구 출력물이 게임 리소스로 중복 포함되는 것을 막으며 HTML 목록에는 영향을 주지 않는다.

## 연결

- `catalog.json`: SHJ ID·이름·소속·현재 이미지 경로·CHR ID·표시용 번호. 정본 인물 492개 레코드 중 단일 인물 482개를 연결했다. 나머지 10개는 무명 집단 또는 복수 인물이 묶인 레코드이므로 특정 한 사람의 얼굴을 임의로 배정하지 않는다. 각 구성원의 SHJ 초상은 모두 존재한다.
- `catalog.gd`: 위 정보를 표시 계층에서 참조하는 생성 파일. 기존 UI의 0~5번 호환을 유지하고 인물 ID·이름·SHJ ID로 검색한다. 동명이인 조자·유기·진복은 원 소속으로 구분한다.
- `Commanders`가 인물 조회와 경로를 제공하고 `FleetBattle3D`는 공개된 투영에만 초상을 연결한다. 코어 프로필/전투 상태의 숫자는 변경하지 않는다. 추정·상실 적 접촉에는 이름이나 얼굴을 추가하지 않는다.
- 브리핑/편성표, 전투 패널, 함대 라벨, 결산, 결정 카드와 컷인은 공통 `_portrait_tex()`를 사용한다. 필요한 텍스처만 불러와 캐시한다. 정사각형 슬롯과 가로형 컷인은 비율을 보존해 잘라 사용한다. 알 수 없는 인물은 다른 사람 얼굴 대신 빈 배경을 사용한다.
- 서방권 SHJ-F090~102는 `-western-v2.png` 교체본 13장을 사용한다.

## 재생성

`node tools/generate_portrait_catalog.cjs [정본 characters.json 경로]`

기본 정본 경로: `C:/WorkSpace/Seonghanji/data/characters.json`. 제작 manifest의 현재 파일만 복사한다. 이후 Godot의 `--headless --path . --editor --import`로 새 리소스를 가져온다.

## 검증

- Godot 4.7.2 import 완료.
- `tests/portraits.gd`: **PORTRAITS_PASS** — 501개 경로, 서방권 교체본, ID/동명이인 매핑, 실제 아군 함대별 다른 얼굴, 브리핑, 비율·캐시, 무명 집단의 대체 표시, 코어 상태 보존.
- `tests/roster.gd`: **ROSTER_PASS** — 기존 편성표 흐름 및 시나리오 회귀.
- Windows 실제 OpenGL 실행(Intel Arc 130V): 브리핑과 전투 선택 패널을 캡처해 새 얼굴을 확인했다. 캡처: `out/portraits-20261018/brief.png`, `select.png`. 최종 전투 캡처에는 script error가 없다.
- 종료 시 기존 테스트 구조에서 ObjectDB/resource 잔존 경고가 출력된다. 두 테스트는 exit 0과 통과 문구를 확인했다. Android APK 빌드/기기 화면은 이번 검증에 포함하지 않았다.
