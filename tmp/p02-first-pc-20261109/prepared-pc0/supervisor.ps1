param(
    [Parameter(Mandatory)][string]$AcceptedManifestSha
)
$ErrorActionPreference = 'Stop'
$prep = $PSScriptRoot
$run = Join-Path (Split-Path $prep -Parent) 'run-01'
$entry = Join-Path $prep 'REVIEW-MANIFEST.json'
if ((Get-FileHash -LiteralPath $entry).Hash -ine $AcceptedManifestSha) { throw 'Accepted manifest digest mismatch' }
$review = Get-Content -LiteralPath $entry -Raw | ConvertFrom-Json
foreach ($part in $review.parts.PSObject.Properties) {
    if ((Get-FileHash -LiteralPath (Join-Path $prep $part.Name)).Hash -ine $part.Value) { throw "Manifest mismatch $($part.Name)" }
}
if (Test-Path -LiteralPath $run) { throw 'Run path must be absent' }
$null = New-Item -ItemType Directory -Path $run
$root = Split-Path (Split-Path (Split-Path $prep -Parent) -Parent) -Parent
$project = Join-Path $run 'project'
$source = Get-Content (Join-Path $prep 'source-manifest.json') -Raw | ConvertFrom-Json
$engineDir = 'C:\Tools\Godot'
$engine = Join-Path $engineDir 'Godot_v4.7.2-stable_win64.exe'
$originalRoots = @(
    (Join-Path $env:APPDATA 'Godot\app_userdata\SpaceBattleOfThreeKingdoms'),
    (Join-Path $env:LOCALAPPDATA 'Godot\app_userdata\SpaceBattleOfThreeKingdoms'),
    (Join-Path $root '.godot')
) | Select-Object -Unique

function Inventory([string]$directory) {
    if (!(Test-Path -LiteralPath $directory)) { return @{ exists = $false; sha = @{} } }
    $files = @{}
    Get-ChildItem -LiteralPath $directory -File -Recurse -Force | ForEach-Object {
        if ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Unexpected link $($_.FullName)" }
        $files[$_.FullName.Substring($directory.Length + 1)] = (Get-FileHash -LiteralPath $_.FullName).Hash
    }
    return @{ exists = $true; sha = $files }
}

function ProtectedInventory {
    $all = @{}
    foreach ($p in $originalRoots) { $all[$p] = Inventory $p }
    return $all
}

function AssertInventorySame($first, $second) {
    if ($first.exists -ne $second.exists -or $first.sha.Count -ne $second.sha.Count) { throw 'Inventory path set changed' }
    foreach ($path in $first.sha.Keys) {
        if ($first.sha[$path] -ne $second.sha[$path]) { throw "Inventory bytes changed $path" }
    }
}

function Launch([string]$lane, [string[]]$flags, [int]$ms, [string]$laneProject = $project) {
    foreach ($image in $source.engines.PSObject.Properties) {
        if ((Get-FileHash -LiteralPath (Join-Path $engineDir $image.Name)).Hash -ine $image.Value) { throw "Image digest drift $($image.Name)" }
    }
    $log = Join-Path $run "$lane.log"
    $argv = @($engine, '--path', $laneProject, '--log-file', $log) + $flags
    $argv | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $run "$lane.argv.json") -Encoding utf8
    if ($argv | Where-Object { $_ -match '["\r\n]' -or $_.EndsWith('\') }) { throw 'Argument cannot use the frozen quoting form' }
    $cmd = ($argv | ForEach-Object { '"' + $_ + '"' }) -join ' '
    $code = [Pc0Job]::Run($engine, $cmd, $laneProject, (Join-Path $run "$lane.os.tsv"), (Join-Path $run 'abort'), $ms, ($lane -eq 'product'))
    if ($code -ne 0 -or !(Test-Path -LiteralPath $log)) { throw "$lane engine exit $code or log absent" }
    if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR|Parse Error|(^|\s)ERROR:' -Quiet) { throw "$lane engine error" }
}

$originalBefore = ProtectedInventory
$originalBefore | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run 'original-before.json') -Encoding utf8
try {
    & python (Join-Path $prep 'stage.py') $run
    if ($LASTEXITCODE -ne 0) { throw 'Frozen staging failed' }
    Add-Type -Path (Join-Path $prep 'Pc0Job.cs')
    $env:APPDATA = Join-Path $run 'appdata'
    $env:LOCALAPPDATA = Join-Path $run 'localappdata'
    $env:TEMP = Join-Path $run 'temp'
    $env:TMP = $env:TEMP
    $null = New-Item -ItemType Directory -Path @($env:APPDATA, $env:LOCALAPPDATA, $env:TEMP, (Join-Path $run 'screens'))
    $probeProject = Join-Path $run 'isolation-project'
    $null = New-Item -ItemType Directory -Path $probeProject
    $probe = Join-Path $probeProject 'pc0-user.gd'
    $app = [regex]::Match((Get-Content -LiteralPath (Join-Path $project 'project.godot') -Raw),
        '(?ms)^\[application\]\r?\n.*?(?=^\[)')
    if (!$app.Success -or $app.Value -match 'config/use_custom_user_dir|config/custom_user_dir_name') {
        throw 'Unexpected project application settings'
    }
    ("config_version=5" + "`n`n" + ($app.Value -replace '(?m)^run/main_scene=.*\r?\n', '')) |
        Set-Content -LiteralPath (Join-Path $probeProject 'project.godot') -Encoding utf8NoBOM
    @'
extends SceneTree

func _initialize() -> void:
	print("PC0_USER ", JSON.stringify({
		"user": ProjectSettings.globalize_path("user://"),
		"project": ProjectSettings.globalize_path("res://"),
		"pid": OS.get_process_id(), "engine": Engine.get_version_info().string}))
	quit()
'@ | Set-Content -LiteralPath $probe -Encoding utf8NoBOM
    Launch 'isolation' @('--headless', '--script', 'res://pc0-user.gd') 30000 $probeProject
    $rows = @(Select-String -LiteralPath (Join-Path $run 'isolation.log') -Pattern '^PC0_USER (.*)$')
    if ($rows.Count -ne 1) { throw 'Cannot prove headless user directory' }
    $location = $rows[0].Matches[0].Groups[1].Value | ConvertFrom-Json
    $userPath = [IO.Path]::GetFullPath($location.user).TrimEnd('\')
    $userRoot = [IO.Path]::GetFullPath($env:APPDATA).TrimEnd('\') + '\'
    if (!$userPath.StartsWith($userRoot, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFullPath($location.project).TrimEnd('\') -ine $probeProject) { throw 'Engine path escaped the isolated run' }
    Launch 'import' @('--headless', '--editor', '--import') 300000
    if (Test-Path -LiteralPath $userPath) {
        if (Get-ChildItem -LiteralPath $userPath -File -Recurse -Force) { throw 'Product user directory is not fresh' }
    }
    & python (Join-Path $prep 'stage.py') $run --after-import
    if ($LASTEXITCODE -ne 0) { throw 'Import did not match frozen inputs' }
    $frozen = Inventory $project
    $frozen | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run 'project-before.json') -Encoding utf8
    Launch 'product' @('res://scenes/WorldMap.tscn') 1920000
} finally {
    $after = ProtectedInventory
    $after | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run 'original-after.json') -Encoding utf8
    foreach ($p in $originalRoots) { AssertInventorySame $originalBefore[$p] $after[$p] }
    if ($frozen) {
        $after = Inventory $project
        $after | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $run 'project-after.json') -Encoding utf8
        AssertInventorySame $frozen $after
    }
    & python (Join-Path $prep 'stage.py') $run --protected
    if ($LASTEXITCODE -ne 0) { throw 'Protected source drift' }
}
