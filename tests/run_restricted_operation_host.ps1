param(
    [string]$Godot = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$evidence = Join-Path $project ('tmp/p02-restricted-host-' + [guid]::NewGuid().ToString('N'))
$previousRoaming = $env:APPDATA
$previousLocal = $env:LOCALAPPDATA
$env:APPDATA = Join-Path $evidence 'roaming'
$env:LOCALAPPDATA = Join-Path $evidence 'local'

function Invoke-Regression($Name, $Script, $UserArgs, $Marker) {
    $log = Join-Path $evidence "$Name.log"
    & $Godot --headless --path $project --log-file $log --quit-after 2400 -s $Script -- @UserArgs | Out-Null
    $code = $LASTEXITCODE
    Set-Content -LiteralPath (Join-Path $evidence "$Name.exit") -Value $code
    if ($code -ne 0 -or
        (Select-String -Quiet -LiteralPath $log -Pattern '^ERROR:|SCRIPT ERROR') -or
        -not (Select-String -Quiet -LiteralPath $log -SimpleMatch -Pattern $Marker)) {
        Get-Content -LiteralPath $log
        throw "$Name failed (exit $code)"
    }
}

try {
    New-Item -ItemType Directory -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    Write-Output $evidence
    Invoke-Regression 'host' 'tests/restricted_operation_host.gd' @() 'RESTRICTED_OPERATION_HOST_PASS'
    $userData = Join-Path $env:APPDATA 'Godot/app_userdata/SpaceBattleOfThreeKingdoms'
    foreach ($fixture in @('poc', 'services', 'natural-150ms')) {
        foreach ($lane in @('input', 'replay')) {
            $inputFile = Join-Path $userData "$fixture-$lane.json"
            $outputFile = Join-Path $evidence "$fixture-$lane-result.json"
            Invoke-Regression "$fixture-$lane" 'tests/autoresolve.gd' @("--operation-$lane", $inputFile, '--out', $outputFile) 'OPERATION_HEADLESS_PASS'
            $hostPath = Join-Path $userData "$fixture-host-$lane.json"
            $observed = Get-Content -Raw -LiteralPath $hostPath | ConvertFrom-Json -AsHashtable
            $actual = Get-Content -Raw -LiteralPath $outputFile | ConvertFrom-Json -AsHashtable
            foreach ($key in @('summary', 'events', 'event_count')) {
                $left = ConvertTo-Json -Compress -Depth 100 -InputObject $observed[$key]
                $right = ConvertTo-Json -Compress -Depth 100 -InputObject $actual[$key]
                if ($left -cne $right) { throw "$fixture $lane differs from host in $key" }
            }
            $summary = $actual.summary
            if ($fixture -eq 'natural-150ms' -and
                ($summary.tick -ne 2 -or $summary.clock_ms -ne 150 -or $summary.end_ms -ne 150 -or
                    -not $summary.over -or -not $summary.win -or $summary.reason -ne 'annihilation')) {
                throw "$fixture $lane did not end naturally at 150 ms"
            }
            "$fixture $lane tick=$($summary.tick) clock_ms=$($summary.clock_ms) over=$($summary.over) reason=$($summary.reason) events=$($actual.event_count)" |
                Tee-Object -FilePath (Join-Path $evidence 'parity.txt') -Append
        }
    }
    Get-Content -LiteralPath (Join-Path $evidence 'host.log')
    Write-Output 'RESTRICTED_OPERATION_CLI_PARITY_PASS'
}
finally {
    $env:APPDATA = $previousRoaming
    $env:LOCALAPPDATA = $previousLocal
}

