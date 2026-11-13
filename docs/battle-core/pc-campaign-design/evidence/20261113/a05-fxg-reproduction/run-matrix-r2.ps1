param(
    [Parameter(Mandatory)][string]$Run,
    [Parameter(Mandatory)][string]$Out,
    [Parameter(Mandatory)][string]$GodotPath
)
$ErrorActionPreference='Stop'
$godot=(Get-Item -LiteralPath $GodotPath -ErrorAction Stop).FullName
$matrix="$Out/matrix-r2"
New-Item -ItemType Directory $matrix | Out-Null
foreach ($scenario in 'base','j210') {
  $speeds=if ($scenario -eq 'base') { @(1,2,4) } else { @(1) }
  $pauses=if ($scenario -eq 'base') { @(0,1) } else { @(0) }
  foreach ($speed in $speeds) {
    foreach ($pause in $pauses) {
      foreach ($lane in 'host','headless','replay') {
        $case="$matrix/$scenario-$lane-x$speed-p$pause"
        New-Item -ItemType Directory "$case/profile" | Out-Null
        $env:APPDATA="$case/profile"
        $env:A05_PROBE_SPEED="$speed"
        $env:A05_PROBE_PAUSE="$pause"
        $env:A05_PROBE_PATH="$case/ticks.json"
        $inputFile="$Out/$scenario-$lane.json"
        if ($lane -eq 'host') {
          $argsList=@('--headless','--quit-after','60','--path',$Run,'--script','tests/a05_host_schedule.gd','--',$inputFile,"$case/result.json")
        } else {
          $option=if ($lane -eq 'headless') { '--operation-input' } else { '--operation-replay' }
          $argsList=@('--headless','--quit-after','60','--path',$Run,'--script','tests/autoresolve.gd','--',$option,$inputFile,'--out',"$case/result.json")
        }
        & $godot @argsList 2>&1 | Set-Content "$case/stdout.log"
        $code=$LASTEXITCODE
        if ($code -ne 0 -or !(Test-Path "$case/ticks.json") -or !(Test-Path "$case/result.json")) {
          Get-Content "$case/stdout.log"
          throw "Scenario failed $case, exit $code"
        }
        Write-Output "$scenario-$lane-x$speed-p$pause exit=$code"
      }
    }
  }
}
