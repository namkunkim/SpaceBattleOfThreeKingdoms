param(
    [Parameter(Mandatory)][string]$CommandFile,
    [Parameter(Mandatory)][string]$SourceSha
)
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'P02DirectJob.cs'
if ((Get-FileHash -LiteralPath $source).Hash -ine $SourceSha) { throw 'Supervisor source SHA drift' }
$record = Get-Content -LiteralPath $CommandFile -Raw -Encoding utf8 | ConvertFrom-Json
$argv = @($record.argv)
$engine = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe'
if ($argv[0] -ine $engine -or $argv[1] -cne '--headless' -or $argv[2] -cne '--path' -or
    $argv[3] -ine $record.cwd -or $argv[4] -cne '--log-file') { throw 'Unexpected direct Godot command' }
if ($argv | Where-Object { $_ -match '["\r\n]' -or $_.EndsWith('\') }) { throw 'Unsupported quoting input' }
foreach ($entry in $record.env.PSObject.Properties) {
    [Environment]::SetEnvironmentVariable($entry.Name, [string]$entry.Value, 'Process')
}
$quoted = ($argv | ForEach-Object { '"' + $_ + '"' }) -join ' '
Add-Type -Path $source
$actual = [P02DirectJob]::Run($engine, $quoted, $record.cwd, $record.os_log, $record.abort,
    [int]$record.timeout_seconds * 1000, [uint32]$record.expected_engine_exit)
if ($actual -ne $record.expected_engine_exit) { throw 'Unexpected supervisor return' }
