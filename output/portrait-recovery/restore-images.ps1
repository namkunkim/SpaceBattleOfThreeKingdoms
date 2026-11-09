$ErrorActionPreference='Stop'
$version=Join-Path $PSScriptRoot '../seonghanji-portraits-distinct-20261017'
$mappings=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'restored-mappings.json') | ConvertFrom-Json
$count=0
foreach($item in $mappings){
 $destination=Join-Path $version ('images/'+$item.filename)
 if(-not (Test-Path -LiteralPath $destination)) { & (Join-Path $version 'resize.ps1') -Source $item.source -Destination $destination }
 $count++
 if($count % 100 -eq 0){Write-Output "Restored $count / $($mappings.Count)"}
}
Write-Output "Restored $count image versions"
