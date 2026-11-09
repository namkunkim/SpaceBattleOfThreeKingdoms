# 직접 전환 거절 V4 attempt-01 결과 · 검토용

판정: 1/6 실패. 승인된 한 회를 기본 환경에서 실행했으며 runner exit 1이다. 전후 승인 inputs 11, source closure 1,480, 보호 경로 4, HEAD와 실제 index SHA가 일치했다. PC0 2/2 및 별도 여덟째 K6 미사용을 유지한다.

before import만 실행했다. Windows Godot GUI exe를 headless root로 직접 시작했다. 보유 root HANDLE의 실제 exit 0과 Job active 0, 보유한 keytool.exe 및 conhost.exe HANDLE signal 0/exit 0이 TSV에 있다. Godot 증거는 --log-file과 C# root/Job 원문이며 PowerShell 별도 스트림을 Godot stdout/stderr로 해석하지 않는다. 모든 단명 자손 신원은 이 수치에 포함되지 않는다.

정상 import 이후 reject 프로젝트에서 FleetBattle3D.tscn은 없었고 비교 대상의 나머지 파일이 일치했다. 실행기는 다음 broad guard에서 실제 scene rejection 호출 전에 중단했다.

    RuntimeError: Possible cached/remapped scene

검사에 걸린 단일 파일은 .godot/editor/FleetBattle3D.tscn-folding-6fc9f3aa03723dcea84c2d7516fcefec.cfg이며 SHA-256 9b34a7fc95b0f9cd640941851bbb0ebc8777e0666f5560e828143047b26c7c93이다. [folding]에는 node_unfolds, resource_unfolds, nodes_folded, animation_groups_folded만 있다. 해당 Godot build의 EditorFolding::save_scene_folding은 이 이름을 생성하고 load_scene_folding은 이미 받은 Node에 접기 상태를 적용한다. 이번 파일의 source/payload는 PackedScene 복원을 위한 것이라는 근거가 없다. 실제 PackedScene resolve나 엔진 거절을 실행하지 않았으므로 fixture 전체의 실행 성공을 미리 인정하지 않는다. [설치 build와 일치하는 EditorFolding](https://github.com/godotengine/godot/blob/ed1daf0bf/editor/settings/editor_folding.cpp#L159-L206).

추가 독립 심사 시 가능한 최소 교정은 위 exact 경로와 bytes만 known editor metadata로 명시한다. 같은 basename의 다른 경로·suffix·bytes, .import/.remap 또는 실제 resource 후보는 기존 fail-closed로 둔다. 넓은 .godot/editor 경로나 *.cfg 허용은 사용하지 않는다. 기존 검사 외 exact fixture file absence/F2/ERR_CANT_OPEN/4회 실제 로그/45행 계약도 유지한다. 이 메모는 기존 runner 또는 승인본을 바꾸거나 재시도하지 않았다.

before reject·direct·auto·title·restart와 after 전체는 미실행이다. 따라서 45행, 실제 거절, 정상 왕복, 제품 수정 효과는 미검증이다. attempt-01의 기존 raw 파일을 유지한다.

- 실행·입력 hash 증거: attempt-01/result-review-only.json
- 실제 root/Job: attempt-01/before/import/engine.os.tsv
- 엔진 원문: attempt-01/before/import/engine.log
- import 결과 manifest: attempt-01/before/post-import.json
