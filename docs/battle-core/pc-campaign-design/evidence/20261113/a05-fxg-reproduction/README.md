# A05 FX-G 준비 실험 재현

기준 커밋은 `7f138c2df7f1a55118bf9a5b7e251703049d5bb6`이고 Godot 4.7.2.stable.official.ed1daf0bf의 Windows 헤드리스 실행을 기록했다. 기준과 J=210 대조 입력을 사용한 21개 호스트·헤드리스·리플레이 실행에서 논리 시계가 0 → 100 → 150ms로 진행했다. 150ms 섬멸 종료, 정지 중 추가 advance 0회, 재개 후 입력·이벤트 동등성을 확인했다. 200ms 종료로 바꾼 결과는 검증기가 거부했다. 이 범위는 합성 wall delta를 사용하는 격리 실험이다.

## 보관한 결과 확인

이 디렉터리에서 실행한다.

~~~powershell
python verify-evidence.py .
~~~

검증기는 동결 입력의 SHA-256, 호스트·헤드리스·리플레이 결과 일치, 논리 시계와 정지·재개 결과를 검사한다. `base-host-first-natural.json`의 로컬 입력 경로를 상대 경로로 바꿨다. 동결 입력과 21개 실행 결과의 원래 바이트를 보존했다.

## Windows에서 행렬 다시 실행

Godot 프로젝트를 위 기준 커밋의 격리된 체크아웃에 준비하고 헤드리스 import를 마친다. 아래의 `$project`는 그 체크아웃, `$output`은 새 결과 디렉터리, `$godot`은 Godot 콘솔 실행 파일의 절대 경로다. 증거 디렉터리에서 PowerShell로 실행한다.

~~~powershell
Copy-Item -LiteralPath './a05_tick_probe-r2.gd.txt' -Destination "$project/tests/a05_tick_probe.gd"
Copy-Item -LiteralPath './a05_host_schedule.gd.txt' -Destination "$project/tests/a05_host_schedule.gd"
git -C $project apply --ignore-space-change (Resolve-Path -LiteralPath './schedule-probe.diff')

New-Item -ItemType Directory -Path $output | Out-Null
foreach ($variant in 'base','j210') {
    foreach ($lane in 'host','headless','replay') {
        Copy-Item -LiteralPath "./$variant-$lane.json" -Destination $output
    }
}
foreach ($name in 'fixture-freeze.json','base-host-first-natural.json','base-headless-result.json','base-replay-result.json','j210-headless-result.json','j210-replay-result.json') {
    Copy-Item -LiteralPath "./$name" -Destination $output
}
& ./run-matrix-r2.ps1 -Run $project -Out $output -GodotPath $godot
python ./verify-evidence.py $output
~~~

`a05_projection_experiment.gd.txt`에는 동결 입력 생성과 최초 호스트 실행에 사용한 GDScript가 있다. Godot이 증거용 스크립트를 프로젝트 코드로 읽지 않도록 `.gd.txt`로 저장했다.
