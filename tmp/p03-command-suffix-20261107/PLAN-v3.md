# P03 같은 틱 절단점 계획 보완 v3

2026-11-07 KST. 독립 5-b는 attempt-01에서 Godot console 실행 파일(198152바이트)만 동결했으며 Windows 본체(180858888바이트)가 누락된 것을 발견했다. attempt-01 실제 exit0·91 checks와 그 입력 기록은 보존하며 최종 엔진 불변 증거로 쓰지 않는다. K6 사용 1.

다음 실행에서 `C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe`를 argv[0]로 유지하고, 실제 테스트 GDScript가 `OS.get_executable_path()`와 `OS.get_process_id()`를 직접 기록한다. gate는 그 PID가 Python이 시작한 console PID와 다른 양의 값이며, 실제 실행 경로가 같은 디렉터리의 `Godot_v4.7.2-stable_win64.exe`를 가리키는지 Windows 경로 비교로 강제한다. console PID/경로와 engine PID/경로를 모두 보존한다. 실행 경로를 추정으로 채우거나 양쪽 동일 PID·예상 외 실행 경로를 통과시키지 않는다.

console wrapper와 engine 본체의 입력 크기·SHA256을 실행 직전·직후 둘 다 동결하고, console `--version` 응답 및 실제 엔진의 테스트 출력과 함께 기록한다. 출발 시 두 파일의 존재를 요구한다. 양쪽 중 하나라도 변경, runtime identity 누락/불일치, 타임아웃이면 게이트 실패다. 기존 class map 정본 경로/identity guard, 나머지 입력, 6명명/4 context/2 structure 및 실제 명령 타임라인 기준은 유지한다. 독립 계획 수용 뒤에만 변경하고 새로운 attempt-02로 실행한다.
