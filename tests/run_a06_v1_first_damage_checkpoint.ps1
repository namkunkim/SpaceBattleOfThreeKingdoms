param(
    [Parameter(Mandatory=$true)][string]$Project,
    [Parameter(Mandatory=$true)][string]$OutputRoot,
    [string]$Fixture='F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/I01/a04-er-center-20261111-01/objective-recording.json',
    [string]$GodotPath='C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe'
)
$ErrorActionPreference='Stop'
$projectPath=(Resolve-Path -LiteralPath $Project).Path
$fixturePath=(Resolve-Path -LiteralPath $Fixture).Path
$enginePath=(Resolve-Path -LiteralPath $GodotPath).Path
$outputPath=[IO.Path]::GetFullPath($OutputRoot)
if(-not $outputPath.StartsWith('F:\WorkSpace\Campaign-Orchestration\',[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $outputPath)) { throw 'Use a new F: evidence directory and preserve earlier attempts' }
$fixturePin='32BE342A94824D35C923BAD15A04595D64D288DBE5EBB5E7B9F8350381C504D7'
if((Get-FileHash -LiteralPath $fixturePath).Hash -ne $fixturePin) { throw 'Frozen objective fixture differs' }
$gitSafe='safe.directory=' + $projectPath.Replace('\','/')
$commit=(& git -c $gitSafe -C $projectPath rev-parse HEAD).Trim()
if($LASTEXITCODE -ne 0) { throw 'Cannot identify checkout' }
$paths=@(& git -c $gitSafe -C $projectPath ls-files -- core/battle scripts view/fleet_render hud/ui_kit data/scenarios data/profiles data/first_operation_checkpoint_compat.json project.godot)
if($LASTEXITCODE -ne 0 -or $paths.Count -eq 0) { throw 'Cannot inventory runtime' }
$paths+=@('tests/a06_v1_first_damage_checkpoint.gd','tests/run_a06_v1_first_damage_checkpoint.ps1','native/o07_win32/o07_win32.dll','.godot/global_script_class_cache.cfg','.godot/uid_cache.bin','.godot/extension_list.cfg')
$paths=@($paths|Sort-Object -Unique)
function Inventory([string]$Root,[string[]]$Names) {
    @($Names|ForEach-Object { [ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $Root $_)).Hash} })
}
$before=Inventory $projectPath $paths
New-Item -ItemType Directory -Path $outputPath,(Join-Path $outputPath 'slots')|Out-Null
Copy-Item -LiteralPath $fixturePath -Destination (Join-Path $outputPath 'objective-recording.json')
$envNames=@('APPDATA','LOCALAPPDATA','TEMP','TMP','SBTK_A06_DAMAGE_ROOT')
$old=@{}
foreach($name in $envNames) { $old[$name]=[Environment]::GetEnvironmentVariable($name,'Process') }
$record=[ordered]@{base_commit=$commit;project=$projectPath;engine=$enginePath;engine_sha256=(Get-FileHash -LiteralPath $enginePath).Hash;fixture=$fixturePath;fixture_sha256=$fixturePin;before=$before;runs=@();start=[DateTime]::UtcNow.ToString('o')}
try {
    foreach($mode in @('control','resume-1061','resume-1062','resume-1063')) {
        $profile=Join-Path $outputPath "profiles/$mode"
        $env:APPDATA=Join-Path $profile 'roaming'
        $env:LOCALAPPDATA=Join-Path $profile 'local'
        $env:TEMP=Join-Path $profile 'tmp'
        $env:TMP=$env:TEMP
        $env:SBTK_A06_DAMAGE_ROOT=$outputPath
        New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP -Force|Out-Null
        $arguments=@('--headless','--path',$projectPath,'--quit-after','2000','--script','res://tests/a06_v1_first_damage_checkpoint.gd','--log-file',(Join-Path $outputPath "$mode-engine.log"),'--',$mode)
        Write-Output "Running A06 $mode in a separate isolated process"
        $run=[ordered]@{mode=$mode;arguments=$arguments;APPDATA=$env:APPDATA;start=[DateTime]::UtcNow.ToString('o')}
        $process=Start-Process -FilePath $enginePath -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outputPath "$mode-stdout.log") -RedirectStandardError (Join-Path $outputPath "$mode-stderr.log")
        $run.launcher_pid=$process.Id
        $watch=[Diagnostics.Stopwatch]::StartNew()
        while(-not $process.WaitForExit(1000) -and $watch.Elapsed.TotalSeconds -lt 300) {}
        $run.timeout=-not $process.HasExited
        if($run.timeout) { $process.Kill($true);$process.WaitForExit() }
        $run.exit=$process.ExitCode
        $run.finish=[DateTime]::UtcNow.ToString('o')
        $run.diagnostics=@(Get-Content -LiteralPath (Join-Path $outputPath "$mode-engine.log")|Where-Object {$_ -match 'ERROR:|SCRIPT ERROR:|WARNING:'})
        $matrixPath=Join-Path $outputPath "$mode-matrix.json"
        if(Test-Path -LiteralPath $matrixPath) { $run.matrix=Get-Content -LiteralPath $matrixPath -Raw|ConvertFrom-Json }
        $record.runs+=@($run)
        Get-Content -LiteralPath (Join-Path $outputPath "$mode-stdout.log")
        Get-Content -LiteralPath (Join-Path $outputPath "$mode-stderr.log")
        if($run.timeout -or $run.exit -ne 0 -or $run.diagnostics.Count -ne 0 -or -not $run.Contains('matrix') -or $run.matrix.checks -ne $run.matrix.passed) { throw "A06 $mode failed; preserve this attempt" }
    }
} finally {
    foreach($name in $envNames) { [Environment]::SetEnvironmentVariable($name,$old[$name],'Process') }
    $record.finish=[DateTime]::UtcNow.ToString('o')
    $record.after=Inventory $projectPath $paths
    $record.sources_unchanged=(($before|ConvertTo-Json -Compress) -eq ($record.after|ConvertTo-Json -Compress))
    $record.fixture_unchanged=(Get-FileHash -LiteralPath $fixturePath).Hash -eq $fixturePin
    $record.profile_files=@(Get-ChildItem -LiteralPath (Join-Path $outputPath 'profiles') -Recurse -File|ForEach-Object {$_.FullName})
    $record|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $outputPath 'run.json') -Encoding utf8
}
if(-not $record.sources_unchanged -or -not $record.fixture_unchanged -or $record.profile_files.Count -ne 0) { throw 'A06 source/fixture/profile preservation failed' }
Write-Output "A06 first-damage evidence verified at $outputPath"
