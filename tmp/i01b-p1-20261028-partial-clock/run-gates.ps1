$ErrorActionPreference='Stop'
$stage='C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01b-p1-20261028-partial-clock'
$root='C:/Users/nk782/.codex/worktrees/i01a-operation-config/SpaceBattleOfThreeKingdoms'
Set-Location -LiteralPath $root
$freeze=Get-Content -Raw 'C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01b-p0-20261028-state-inventory/source-freeze.json'|ConvertFrom-Json
if((git rev-parse HEAD) -ne $freeze.observed_head){throw 'HEAD guard'}
foreach($f in $freeze.preserved_files){if((Get-FileHash -LiteralPath $f.path).Hash.ToLower() -ne $f.sha256){throw 'Preexisting six changed'}}
$target='tests/i01b_logical_clock.gd'
if(Test-Path -LiteralPath $target){throw 'New runner collision'}
if((Get-FileHash -LiteralPath "$stage/$target").Hash.ToLower() -ne 'febcbc625a32814b21ac60a10fcba389928921044711fecb95a2ada6ddaf8925'){throw 'Staged runner guard'}
$before=@(git status --porcelain=v1 --untracked-files=all)
[System.IO.File]::WriteAllLines("$stage/logs/status-before.txt",$before)
Copy-Item -LiteralPath "$stage/$target" -Destination $target
$results=@()
foreach($test in @('tests/i01b_logical_clock.gd','tests/core_rules.gd')){
    $log="$stage/logs/$([System.IO.Path]::GetFileNameWithoutExtension($test)).log"
    $started=[DateTime]::UtcNow.ToString('o')
    $ErrorActionPreference='Continue'
    & 'C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path $root --script $test *> $log
    $code=$LASTEXITCODE
    $ErrorActionPreference='Stop'
    $results += [ordered]@{test=$test;exit_code=$code;started_utc=$started;ended_utc=[DateTime]::UtcNow.ToString('o');log=$log;sha256=(Get-FileHash -LiteralPath $log).Hash.ToLower()}
    [System.IO.File]::WriteAllText("$stage/test-results.json",($results|ConvertTo-Json -Depth 8),[System.Text.UTF8Encoding]::new($false))
    Write-Output "$test exit=$code"
}
foreach($f in $freeze.preserved_files){if((Get-FileHash -LiteralPath $f.path).Hash.ToLower() -ne $f.sha256){throw 'Preexisting six changed after gates'}}
$after=@(git status --porcelain=v1 --untracked-files=all)
[System.IO.File]::WriteAllLines("$stage/logs/status-after.txt",$after)
$audit=[ordered]@{head=(git rev-parse HEAD);runner_path=$target;runner_sha256=(Get-FileHash -LiteralPath $target).Hash.ToLower();preexisting_six_unchanged=$true;status_added=@($after|Where-Object {$_ -notin $before});status_removed=@($before|Where-Object {$_ -notin $after});production_changed=$false;independent_review='Pending'}
[System.IO.File]::WriteAllText("$stage/change-audit.json",($audit|ConvertTo-Json -Depth 8),[System.Text.UTF8Encoding]::new($false))
Write-Output ($audit|ConvertTo-Json -Depth 8)
if(@($results|Where-Object exit_code -ne 0).Count -gt 0){exit 1}