# 직접 전환 거절 V5 · 편집기 folding 오인 정정 검토본

상태: 정적 검토용. attempt-01은 1/6 소진이며 원문과 승인본을 유지한다. attempt-02 및 Godot 실행을 만들지 않았다. PC0 2/2, 별도 여덟째 K6 미사용. 이번 새 회차도 독립 계획 수용이 선행된다.

- runner-v5-review.diff에서 run-direct.py와 새 run-direct-v5.py를 비교한다. 유일하게 확인된 편집기 파일의 **정확한 상대 경로**, **SHA-256** 및 **[folding] 전체 여섯 줄**이 일치할 때만 진단 기록에 포함하고 계속한다. 폴더 전체, *.cfg, basename 일치만으로 허용하지 않는다. Godot 해당 버전의 EditorFolding::save_scene_folding은 이 이름과 키를 쓰며 load_scene_folding은 이미 받은 Node의 편집기 속성을 적용한다. [Godot EditorFolding](https://github.com/godotengine/godot/blob/ed1daf0bf/editor/settings/editor_folding.cpp#L159-L206).
- 실제 대상 scene 파일 부재와 나머지 복제 inventory의 전 byte 일치가 선행된다. 알려진 folding 외에는 .tscn- prefix, .tscn.remap, .tscn.import를 계속 거부한다. 매 .import/.remap 파일의 원문에서 대소문자 무시 대상 scene 참조를 검사한다. 모든 .godot 프로젝트 설정을 읽고 root project.godot의 원래 run/main_scene 한 줄만 허용한다. 추가 project override/compiled 설정을 차단한다. 읽기 불가나 새 참조도 런처 전에 중단한다.
- attempt-01 실제 reject 복제본에 **읽기 전용으로** 새 verifier를 적용했다. 편집기 folding 한 항목과 기존 project.godot 한 참조, .import/.remap 621개 검사가 v5-static-guard-evidence.json에 있다. 동일 이름의 .godot/imported 사본, .scn suffix, .tscn.remap/.tscn.import, 같은 정확 경로의 다른 SHA 다섯 반례를 합성 inventory로 거부했다. 기존 복제본에서 Godot 실행·파일 수정은 하지 않았다.
- F1/F2/F3, 제품 실제 ERR_CANT_OPEN, loader 로그 네 쌍, 45행, 정상 direct/auto/title/restart, 실제 exit 및 Job cleanup 계약은 동일하다. 후보 두 파일과 준비 테스트, C# 및 PowerShell 런처, source closure, 엔진 바이너리는 그대로다. 새 실행에 필요한 class cache는 새 import가 만든 뒤 고정한다.
- DIRECT-MANIFEST-V5-REVIEW-ONLY.json SHA-256 a27803d6f6c1cc3bf426fe27f9e131bf6fda9aa2c7c265e92a982d635814ca3d는 attempt-02의 14개 exact argv/env와 새 runner SHA를 포함한다. 상태값은 검토 전용이며 실행기가 거절한다. 독립 수용 시 승인본에서만 상태를 바꾸고 SHA를 명시한다. 새 runner·후보·보호 경로·HEAD/index·engine SHA를 재확인하기 전 시작하지 않는다.
