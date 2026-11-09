$ErrorActionPreference = 'Stop'
$stage = 'C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/data-rules-fix-20261027-chase-fallback'
$m = Get-Content -Raw "$stage/manifest-k2.json" | ConvertFrom-Json
Set-Location -LiteralPath $m.target_root
if ((git rev-parse HEAD) -ne '8292805143f4561a4f5258d40b7b94adf4ff5802') {throw 'HEAD guard'}
$previous = Get-Content -Raw "$stage/final-change-audit.json" | ConvertFrom-Json
foreach ($f in $m.files) {
    $old = $previous.files | Where-Object path -eq $f.path
    if ((Get-FileHash -LiteralPath $f.path).Hash.ToLower() -ne $old.sha256) {throw "K1 target hash guard: $($f.path)"}
    if ((Get-FileHash -LiteralPath (Join-Path $stage $f.path)).Hash.ToLower() -ne $f.after_sha256) {throw "K2 source hash guard: $($f.path)"}
}
Copy-Item -LiteralPath "$stage/test-results.json" -Destination "$stage/test-results-k1.json"
Copy-Item -LiteralPath "$stage/final-change-audit.json" -Destination "$stage/final-change-audit-k1.json"
Copy-Item -LiteralPath "$stage/logs/data_rules.log" -Destination "$stage/logs/data_rules-k1.log"
foreach ($f in $m.files | Where-Object path -eq 'tests/data_rules.gd') {Copy-Item -LiteralPath (Join-Path $stage $f.path) -Destination $f.path}
$log = "$stage/logs/data_rules-k2.log"
$started = [DateTime]::UtcNow.ToString('o')
$ErrorActionPreference = 'Continue'
& 'C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path $m.target_root --script tests/data_rules.gd *> $log
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
$results = @(Get-Content -Raw "$stage/test-results-k1.json" | ConvertFrom-Json | Where-Object test -ne 'tests/data_rules.gd')
$results += [ordered]@{test='tests/data_rules.gd';exit_code=$code;attempt=2;started_utc=$started;ended_utc=[DateTime]::UtcNow.ToString('o');log=$log;sha256=(Get-FileHash -LiteralPath $log).Hash.ToLower()}
[System.IO.File]::WriteAllText("$stage/test-results.json", ($results | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
$diff = @(git diff -- $m.files.path)
[System.IO.File]::WriteAllLines("$stage/logs/change-k2.diff", $diff)
$check = @(git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check 2>&1)
$checkCode = $LASTEXITCODE
[System.IO.File]::WriteAllLines("$stage/logs/diff-check-k2.txt", [string[]]$check)
$beforeStatus = @(Get-Content "$stage/logs/status-before.txt")
$afterStatus = @(git status --porcelain=v1 --untracked-files=all)
[System.IO.File]::WriteAllLines("$stage/logs/status-after-k2.txt", $afterStatus)
$audit = [ordered]@{head=(git rev-parse HEAD);files=@($m.files | ForEach-Object {[ordered]@{path=$_.path;sha256=(Get-FileHash -LiteralPath $_.path).Hash.ToLower();bytes=(Get-Item -LiteralPath $_.path).Length}});diff_check_exit=$checkCode;diff_files=@(git -c core.autocrlf=false diff --name-only);status_added=@($afterStatus | Where-Object {$_ -notin $beforeStatus});status_removed=@($beforeStatus | Where-Object {$_ -notin $afterStatus});independent_review='Pending'}
[System.IO.File]::WriteAllText("$stage/final-change-audit.json", ($audit | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))
Write-Output ($audit | ConvertTo-Json -Depth 10)
Write-Output "data_rules K2 exit=$code"
if ($code -ne 0 -or $checkCode -ne 0) {exit 1}