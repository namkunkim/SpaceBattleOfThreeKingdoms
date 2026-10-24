# 게임 언어

타이틀의 설정 또는 전투 중 일시정지 → 설정 → 화면 → 언어에서 한국어, English, 简体中文, 日本語를 선택한다. 저장하면 현재 UI에 적용되고 `user://settings.cfg`의 `display.language`에 저장된다. 취소하면 기존 언어를 유지한다. 기본 언어와 잘못된 설정값의 대체 언어는 한국어다.

번역 원본은 `data/i18n/messages.json`이다. 키는 게임의 한국어 원문이고 값은 영어, 중국어 간체, 일본어 순서의 배열이다. 원문 식별자와 전투 데이터는 변경하지 않으며, 일반 Godot 컨트롤과 `UiDraw.text`에서 표시할 때 번역한다. 서식 문자열의 `%d`, `%s`, `%.1f` 등 자리표시자 순서는 각 번역에서도 유지한다. 조합된 함선 수·시간·지휘관 이름, 편성 알림, 보급·수리·특기 툴팁, 지도·성역 정보와 후일담도 번역한다. 줄바꿈은 완성된 문장을 번역한 뒤 수행하며, 공백이 없는 중국어·일본어도 폭에 맞게 나눈다.

새 문구가 등록되지 않은 경우에는 원문을 표시하지만, 정적 검사와 실행 검사가 이를 실패로 처리한다. `tools/audit-localization.py`는 모든 게임 GDScript 문자열(주석 제외, 실제 줄바꿈 포함)과 화면용 JSON 필드·목록을 수집해 번역 존재 여부, 세 언어 값, 미번역 한글, 자리표시자 타입·순서를 검사한다. 개발용 규칙 메모는 화면용 데이터 필드에 포함하지 않는다. 언어 선택기의 자국어 이름과 후일담 내부 치환 키만 명시적으로 제외한다. Android 빌드 CI에서도 검사를 실행한다.

편성의 장수·특성 검색은 원문과 현재 언어의 번역문을 모두 검색하고 영문 대소문자를 구분하지 않는다. 긴 번역은 편성 열 안에서 줄바꿈하며, 장수 버튼의 전체 내용은 마우스 툴팁 또는 터치 길게 누르기로 확인한다.

중국어 간체와 일본어를 위해 Noto Sans CJK SC 글꼴을 번들에 포함했다. Pretendard와 Noto Serif KR에 없는 글자를 보완하며, 라이선스는 `assets/fonts/NotoSansCJK-LICENSE.txt`에 있다.

검증:

```powershell
python tools/audit-localization.py --check --report artifacts/localization/coverage.json
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/localization.gd
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/localization_coverage.gd
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --script tests/localization_coverage.gd -- --capture
```

`localization.gd`는 네 언어의 저장·재로드·취소, 타이틀/일시정지 설정 동기화, 동적 문구와 CJK 글꼴을 검증한다. 테스트 전의 설정 파일은 종료 전에 복원한다.

`localization_coverage.gd`는 영어·중국어·일본어에서 서식이 적용된 전체 카탈로그, 줄바꿈·괄호·인용문·복합 메시지, 모든 주요 화면, 난이도별 편성, 7종 진형, 아군 함대별 특기·명령·보급·수리 탭과 툴팁, 지도 3단계·19성계·4권역과 모든 결말을 검사한다. 실제 번역 호출에서도 한국어가 남으면 실패한다. 결과는 `artifacts/localization/runtime-coverage.json`, 캡처는 같은 폴더에 저장한다. 이 검사는 설정 파일과 전투 규칙 데이터를 변경하지 않는다.
