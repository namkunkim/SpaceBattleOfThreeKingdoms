param(
    [Parameter(Mandatory=$true)][string]$Project,
    [Parameter(Mandatory=$true)][string]$OutputRoot,
    [string]$RecordSource='F:/WorkSpace/Campaign-Orchestration/A05-J210-terminal-receipt-20261114/attempt-02',
    [string]$GodotPath='C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe'
)
$ErrorActionPreference='Stop'
$projectPath=(Resolve-Path -LiteralPath $Project).Path
$sourcePath=(Resolve-Path -LiteralPath $RecordSource).Path
$enginePath=(Resolve-Path -LiteralPath $GodotPath).Path
$outputPath=[IO.Path]::GetFullPath($OutputRoot)
if(-not $outputPath.StartsWith('F:\WorkSpace\Campaign-Orchestration\',[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $outputPath)) { throw 'Use a new F: evidence directory; preserve every attempt' }
if((Get-FileHash -LiteralPath (Join-Path $sourcePath 'record.json')).Hash -ne 'FD014EC38DD11FD7739D30F305C37F176E1E6F21D7ACB5044A907D49B1BA3D0B') { throw 'Reviewed J210 record pin differs' }
$test='tests/a05_j210_receipt_replay.gd'
$gitSafe='safe.directory=' + $projectPath.Replace('\','/')
$commit=(& git -c $gitSafe -C $projectPath rev-parse HEAD).Trim()
if($LASTEXITCODE -ne 0) { throw 'Cannot read revision' }
$paths=@(& git -c $gitSafe -C $projectPath ls-files -- core/battle scripts native/o07_win32 project.godot scenes/RestrictedOperationHost.tscn)
if($LASTEXITCODE -ne 0 -or $paths.Count -eq 0) { throw 'Cannot inventory runtime' }
$paths+=@('scripts/a05_j210_receipt_replay.gd',$test,'tests/run_a05_j210_receipt_replay.ps1','native/o07_win32/o07_win32.dll')
$paths=@($paths|Sort-Object -Unique)
$recordPaths=@(Get-ChildItem -LiteralPath $sourcePath -Recurse -File | ForEach-Object { [IO.Path]::GetRelativePath($sourcePath,$_.FullName) } | Sort-Object)
function Inventory([string]$Root,[string[]]$Names) {
    @($Names | ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $Root $_)).Hash} })
}
$before=Inventory $projectPath $paths
$recordBefore=Inventory $sourcePath $recordPaths
New-Item -ItemType Directory -Path $outputPath | Out-Null
$environment=@('APPDATA','LOCALAPPDATA','TEMP','TMP','SBTK_A05_RECORD_SOURCE','SBTK_A05_REPLAY_ROOT')
$old=@{}
foreach($name in $environment) { $old[$name]=[Environment]::GetEnvironmentVariable($name,'Process') }
$arguments=@('--headless','--path',$projectPath,'--quit-after','2000','--script',('res://' + $test),'--log-file',(Join-Path $outputPath 'engine.log'))
$record=[ordered]@{commit=$commit;project=$projectPath;record_source=$sourcePath;engine=$enginePath;engine_sha256=(Get-FileHash -LiteralPath $enginePath).Hash;arguments=$arguments;before=$before;record_before=$recordBefore;start=[DateTime]::UtcNow.ToString('o')}
try {
    $env:APPDATA=Join-Path $outputPath 'profile/roaming'
    $env:LOCALAPPDATA=Join-Path $outputPath 'profile/local'
    $env:TEMP=Join-Path $outputPath 'profile/tmp'
    $env:TMP=$env:TEMP
    $env:SBTK_A05_RECORD_SOURCE=$sourcePath
    $env:SBTK_A05_REPLAY_ROOT=$outputPath
    New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP -Force | Out-Null
    $record.profile=@{APPDATA=$env:APPDATA;LOCALAPPDATA=$env:LOCALAPPDATA;TEMP=$env:TEMP}
    $process=Start-Process -FilePath $enginePath -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outputPath 'stdout.log') -RedirectStandardError (Join-Path $outputPath 'stderr.log')
    $record.launcher_pid=$process.Id
    $record.timeout=-not $process.WaitForExit(45000)
    if($record.timeout) { $process.Kill($true); $process.WaitForExit() }
    $record.exit=$process.ExitCode
} finally {
    foreach($name in $environment) { [Environment]::SetEnvironmentVariable($name,$old[$name],'Process') }
    $record.finish=[DateTime]::UtcNow.ToString('o')
    $record.after=Inventory $projectPath $paths
    $record.record_after=Inventory $sourcePath $recordPaths
    $record.sources_unchanged=(($before|ConvertTo-Json -Compress) -eq ($record.after|ConvertTo-Json -Compress))
    $record.record_unchanged=(($recordBefore|ConvertTo-Json -Compress) -eq ($record.record_after|ConvertTo-Json -Compress))
    $record.created_authority_files=@(Get-ChildItem -LiteralPath (Join-Path $outputPath 'profile') -Recurse -File | Where-Object { $_.Name -match '\.(save|lock|pcopreplay)(\.|$)|settlement|supply' } | ForEach-Object { $_.FullName })
    $record | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $outputPath 'run.json') -Encoding utf8
}
Get-Content -LiteralPath (Join-Path $outputPath 'stdout.log')
Get-Content -LiteralPath (Join-Path $outputPath 'stderr.log')
$diagnostics=@(Get-Content -LiteralPath (Join-Path $outputPath 'engine.log') | Where-Object { $_ -match 'ERROR:|SCRIPT ERROR:|WARNING:' })
if($record.timeout -or $record.exit -ne 0 -or -not $record.sources_unchanged -or -not $record.record_unchanged -or $record.created_authority_files.Count -ne 0 -or $diagnostics.Count -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $outputPath 'matrix.json'))) { throw 'J210 replay validation failed; retain and inspect attempt' }
Write-Output "A05 J210 read-only replay verified at $outputPath"
