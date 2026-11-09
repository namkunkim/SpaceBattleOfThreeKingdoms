$ErrorActionPreference='Stop'
$taskRoot='C:\WorkSpace\SpaceBattleOfThreeKingdoms'
$evidence=Join-Path $taskRoot 'tmp/i01b-runtime-inventory-20261028'
$results=@()
foreach($name in @('core_rules','data_rules','i01_operation_config','i01b_logical_clock','detection_rules','supply_rules')){
  $engineLog=Join-Path $evidence "logs/$name.log"
  $captureLog=Join-Path $evidence "logs/$name.captured-output.log"
  $script="tests/$name.gd"
  $started=[DateTimeOffset]::Now.ToString('o')
  $lines=@(& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path $taskRoot --script $script --log-file $engineLog 2>&1)
  $code=$LASTEXITCODE
  $raw=($lines | ForEach-Object { $_.ToString() }) -join "`n"
  [System.IO.File]::WriteAllText($captureLog,$raw,[System.Text.UTF8Encoding]::new($false))
  $results += [ordered]@{test=$name;script=$script;script_sha256=(Get-FileHash -LiteralPath (Join-Path $taskRoot $script)).Hash.ToLower();exit_code=$code;started=$started;ended=[DateTimeOffset]::Now.ToString('o');captured_output=$raw;captured_log=$captureLog;captured_sha256=(Get-FileHash -LiteralPath $captureLog).Hash.ToLower();engine_log=$engineLog;engine_sha256=(Get-FileHash -LiteralPath $engineLog).Hash.ToLower()}
  $results | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $evidence 'regression-results.json')
  Write-Output "$name exit=$code"
}
if(@($results | Where-Object {$_.exit_code -ne 0}).Count -gt 0){exit 1}
