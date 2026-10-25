param(
    [ValidateSet('baseline', 'slow_only', 'large_only', 'large_slow', 'terrain')]
    [string]$Preset = 'large_slow',
    [string]$Godot = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
    throw "Godot executable was not found: $Godot"
}
& $Godot --path $projectRoot -- --pc-preset $Preset
exit $LASTEXITCODE
