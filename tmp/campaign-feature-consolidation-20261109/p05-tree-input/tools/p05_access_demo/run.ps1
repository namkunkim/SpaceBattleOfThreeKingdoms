param(
    [ValidateSet('Headless','WindowsAuto','WindowsManual')]
    [string] $Mode = 'Headless',
    [string] $Godot = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe',
    [string] $EvidenceDir
)
$ErrorActionPreference = 'Stop'
if (!(Test-Path -LiteralPath $Godot -PathType Leaf)) { throw "Godot executable not found: $Godot" }
$scratch = Join-Path ([IO.Path]::GetTempPath()) ("p05-access-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
foreach ($name in 'project.godot','main.tscn','guard.gd','demo.gd') {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $scratch
}
$manifest = Join-Path $scratch 'manifest.json'
& python (Join-Path $PSScriptRoot 'build_manifest.py') $manifest
if ($LASTEXITCODE -ne 0) { throw "P05 manifest build failed: $LASTEXITCODE" }
if (!$EvidenceDir) { $EvidenceDir = $scratch }
New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null
$EvidenceDir = (Resolve-Path -LiteralPath $EvidenceDir).Path
Copy-Item -LiteralPath $manifest -Destination (Join-Path $EvidenceDir "$Mode.manifest.json")
$log = Join-Path $EvidenceDir "$Mode.log"
$argsForRun = @('--path', $scratch, '--log-file', $log)
if ($Mode -eq 'Headless') { $argsForRun += '--headless' }
$argsForRun += @('--', "--mode=$Mode", "--evidence=$EvidenceDir")
$invocation = @{
    executable = (Resolve-Path -LiteralPath $Godot).Path
    arguments = $argsForRun
    manifest_sha256 = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash
}
$invocation | ConvertTo-Json -Depth 3 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $EvidenceDir "$Mode.command.json")
& $Godot @argsForRun
$result = $LASTEXITCODE
[IO.File]::WriteAllText((Join-Path $EvidenceDir "$Mode.exit.txt"), [string]$result)
Write-Output "P05 evidence: $EvidenceDir"
exit $result
