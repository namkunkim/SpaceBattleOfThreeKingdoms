$ErrorActionPreference = 'Stop'
$stage = 'C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/data-rules-fix-20261027-chase-fallback'
$m = Get-Content -Raw -LiteralPath "$stage/manifest.json" | ConvertFrom-Json
Set-Location -LiteralPath $m.target_root
if ((git rev-parse HEAD) -ne '8292805143f4561a4f5258d40b7b94adf4ff5802') { throw 'HEAD guard failed' }
New-Item -ItemType Directory -Force -Path "$stage/logs" | Out-Null
$beforeStatus = @(git status --porcelain=v1 --untracked-files=all)
[System.IO.File]::WriteAllLines("$stage/logs/status-before.txt", $beforeStatus)
foreach ($f in $m.files) {
    if ((Get-FileHash -LiteralPath $f.path -Algorithm SHA256).Hash.ToLower() -ne $f.before_sha256) { throw "Before hash mismatch: $($f.path)" }
    if ((Get-FileHash -LiteralPath (Join-Path $stage $f.path) -Algorithm SHA256).Hash.ToLower() -ne $f.after_sha256) { throw "Staging hash mismatch: $($f.path)" }
}
foreach ($f in $m.files) {
    Copy-Item -LiteralPath (Join-Path $stage $f.path) -Destination $f.path
    if ((Get-FileHash -LiteralPath $f.path -Algorithm SHA256).Hash.ToLower() -ne $f.after_sha256) { throw "After hash mismatch: $($f.path)" }
}
$results = @()
foreach ($test in $m.tests) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($test)
    $log = "$stage/logs/$name.log"
    $started = [DateTime]::UtcNow.ToString('o')
    $ErrorActionPreference = 'Continue'
    & 'C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path $m.target_root --script $test *> $log
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $results += [ordered]@{test=$test;exit_code=$code;started_utc=$started;ended_utc=[DateTime]::UtcNow.ToString('o');log=$log;sha256=(Get-FileHash -LiteralPath $log -Algorithm SHA256).Hash.ToLower()}
    [System.IO.File]::WriteAllText("$stage/test-results.json", ($results | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
    Write-Output "$test exit=$code log=$log"
}
$afterStatus = @(git status --porcelain=v1 --untracked-files=all)
[System.IO.File]::WriteAllLines("$stage/logs/status-after.txt", $afterStatus)
$diff = @(git -c core.autocrlf=false diff -- $m.files.path)
[System.IO.File]::WriteAllLines("$stage/logs/change.diff", $diff)
$check = @(git -c core.autocrlf=false diff --check 2>&1)
$checkCode = $LASTEXITCODE
[System.IO.File]::WriteAllLines("$stage/logs/diff-check.txt", [string[]]$check)
$allDiff = @(git -c core.autocrlf=false diff --name-only)
$audit = [ordered]@{head=(git rev-parse HEAD);files=@($m.files | ForEach-Object {[ordered]@{path=$_.path;sha256=(Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash.ToLower();bytes=(Get-Item -LiteralPath $_.path).Length}});diff_check_exit=$checkCode;diff_files=$allDiff;status_added=@($afterStatus | Where-Object {$_ -notin $beforeStatus});status_removed=@($beforeStatus | Where-Object {$_ -notin $afterStatus});independent_review='Pending'}
[System.IO.File]::WriteAllText("$stage/final-change-audit.json", ($audit | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))
Write-Output ($audit | ConvertTo-Json -Depth 10)
if (@($results | Where-Object {$_.exit_code -ne 0}).Count -gt 0 -or $checkCode -ne 0) { exit 1 }