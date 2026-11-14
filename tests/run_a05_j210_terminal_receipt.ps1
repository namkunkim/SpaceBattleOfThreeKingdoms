param(
    [Parameter(Mandatory=$true)][string]$Project,
    [Parameter(Mandatory=$true)][string]$OutputRoot,
    [string]$GodotPath='C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe',
    [string]$FixtureRoot='F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/A05-fxg-projection-run-7f138c2d-03',
    [string]$HistoricalRoot='F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/O07/o07-terminal-receipt-authority-01a1c7a8'
)
$ErrorActionPreference='Stop'
$projectPath=(Resolve-Path -LiteralPath $Project).Path
$enginePath=(Resolve-Path -LiteralPath $GodotPath).Path
$fixturePath=(Resolve-Path -LiteralPath $FixtureRoot).Path
$historicalPath=(Resolve-Path -LiteralPath $HistoricalRoot).Path
$outputPath=[IO.Path]::GetFullPath($OutputRoot)
if(-not $outputPath.StartsWith('F:\WorkSpace\Campaign-Orchestration\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Evidence must use a new F:/WorkSpace/Campaign-Orchestration directory' }
if(Test-Path -LiteralPath $outputPath) { throw 'Output directory already exists; preserve every attempt' }
$test='tests/a05_j210_terminal_receipt.gd'
if(-not (Test-Path -LiteralPath (Join-Path $projectPath $test))) { throw 'Recorder is missing' }
$gitSafe='safe.directory=' + $projectPath.Replace('\','/')
$commit=(& git -c $gitSafe -C $projectPath rev-parse HEAD).Trim()
if($LASTEXITCODE -ne 0) { throw 'Cannot read exact checkout revision' }
$runtimePaths=@(& git -c $gitSafe -C $projectPath ls-files -- core/battle scripts native/o07_win32 project.godot scenes/RestrictedOperationHost.tscn)
if($LASTEXITCODE -ne 0 -or $runtimePaths.Count -eq 0) { throw 'Cannot inventory runtime sources' }
$runtimePaths+=@($test,'tests/run_a05_j210_terminal_receipt.ps1','native/o07_win32/o07_win32.dll')
$fixtureRelative='docs/battle-core/pc-campaign-design/evidence/20261113/a05-fxg-reproduction'
$fixtures=@('j210-host.json','j210-replay.json','j210-replay-result.json')
$runtimePaths+=@($fixtures|ForEach-Object { "$fixtureRelative/$_" })
$runtimePaths=@($runtimePaths|Sort-Object -Unique)
function Inventory([string]$Root,[string[]]$Paths) {
    return @($Paths|ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $Root $_)).Hash} })
}
$historicalFiles=@('terminal.json','run-03/matrix.jsonl')
$historicalFiles+=@(Get-ChildItem -LiteralPath (Join-Path $historicalPath 'run-03') -Recurse -File | Where-Object { $_.Name -in @('operation-supply.save','operation-supply.save.previous') } | ForEach-Object { [IO.Path]::GetRelativePath($historicalPath,$_.FullName) })
if($historicalFiles.Count -ne 10) { throw 'Expected historical input, matrix and eight retained native slots' }
$before=Inventory $projectPath $runtimePaths
$oldBefore=Inventory $historicalPath $historicalFiles
$fixtureBefore=Inventory $fixturePath $fixtures
New-Item -ItemType Directory -Path $outputPath -ErrorAction Stop|Out-Null
New-Item -ItemType Directory -Path (Join-Path $outputPath 'fixtures')|Out-Null
foreach($name in $fixtures) { Copy-Item -LiteralPath (Join-Path $fixturePath $name) -Destination (Join-Path $outputPath "fixtures/$name") }
$environment=@('APPDATA','LOCALAPPDATA','TEMP','TMP','SBTK_A05_RECEIPT_ROOT')
$oldEnvironment=@{}
foreach($name in $environment) { $oldEnvironment[$name]=[Environment]::GetEnvironmentVariable($name,'Process') }
$arguments=@('--headless','--path',$projectPath,'--quit-after','2000','--script',('res://' + $test),'--log-file',(Join-Path $outputPath 'engine.log'),'--','--o07-supply')
$record=[ordered]@{commit=$commit;project=$projectPath;engine=$enginePath;engine_sha256=(Get-FileHash -LiteralPath $enginePath).Hash;arguments=$arguments;before=$before;fixture_root=$fixturePath;fixture_before=$fixtureBefore;historical_root=$historicalPath;historical_before=$oldBefore;start=[DateTime]::UtcNow.ToString('o')}
try {
    $env:APPDATA=Join-Path $outputPath 'profile/roaming'
    $env:LOCALAPPDATA=Join-Path $outputPath 'profile/local'
    $env:TEMP=Join-Path $outputPath 'profile/tmp'
    $env:TMP=$env:TEMP
    $env:SBTK_A05_RECEIPT_ROOT=$outputPath
    New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP -Force|Out-Null
    $record.profile=@{APPDATA=$env:APPDATA;LOCALAPPDATA=$env:LOCALAPPDATA;TEMP=$env:TEMP;TMP=$env:TMP}
    $process=Start-Process -FilePath $enginePath -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outputPath 'stdout.log') -RedirectStandardError (Join-Path $outputPath 'stderr.log')
    $record.launcher_pid=$process.Id
    $record.timeout=-not $process.WaitForExit(45000)
    if($record.timeout) { $process.Kill($true); $process.WaitForExit() }
    $record.exit=$process.ExitCode
} finally {
    foreach($name in $environment) { [Environment]::SetEnvironmentVariable($name,$oldEnvironment[$name],'Process') }
    $record.finish=[DateTime]::UtcNow.ToString('o')
    $record.after=Inventory $projectPath $runtimePaths
    $record.fixture_after=Inventory $fixturePath $fixtures
    $record.fixtures_unchanged=(($record.fixture_before|ConvertTo-Json -Compress -Depth 4) -eq ($record.fixture_after|ConvertTo-Json -Compress -Depth 4))
    $record.historical_after=Inventory $historicalPath $historicalFiles
    $record.sources_unchanged=(($record.before|ConvertTo-Json -Compress -Depth 4) -eq ($record.after|ConvertTo-Json -Compress -Depth 4))
    $record.historical_unchanged=(($record.historical_before|ConvertTo-Json -Compress -Depth 4) -eq ($record.historical_after|ConvertTo-Json -Compress -Depth 4))
    $record|ConvertTo-Json -Depth 7|Set-Content -LiteralPath (Join-Path $outputPath 'run.json') -Encoding utf8
}
Get-Content -LiteralPath (Join-Path $outputPath 'stdout.log')
Get-Content -LiteralPath (Join-Path $outputPath 'stderr.log')
$diagnostics=@(Get-Content -LiteralPath (Join-Path $outputPath 'engine.log') | Where-Object { $_ -match 'ERROR:|SCRIPT ERROR:|WARNING:' })
if($record.timeout -or $record.exit -ne 0 -or -not $record.sources_unchanged -or -not $record.fixtures_unchanged -or -not $record.historical_unchanged -or $diagnostics.Count -gt 0 -or -not (Test-Path -LiteralPath (Join-Path $outputPath 'record.json'))) { throw 'J210 receipt run failed; preserve this attempt and inspect its manifest/logs' }
Write-Output "A05 receipt recorded at $outputPath; sources and historical records unchanged"