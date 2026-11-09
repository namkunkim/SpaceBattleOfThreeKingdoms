Add-Type -AssemblyName System.Drawing
$manifestPath=Join-Path $PSScriptRoot 'manifest.json'
$manifest=Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
$completed=@($manifest.records | Where-Object {$_.status -eq 'generated'})
$errors=@()
foreach($record in $completed){
 $imagePath=Join-Path (Join-Path $PSScriptRoot 'images') $record.filename
 if(-not (Test-Path -LiteralPath $imagePath)){ $errors+='Missing: '+$record.id;continue }
 $portraitImage=[System.Drawing.Image]::FromFile($imagePath)
 try {if($portraitImage.Width -ne 561 -or $portraitImage.Height -ne 701){$errors+='Wrong dimensions: '+$record.id}}finally{$portraitImage.Dispose()}
}
$tags=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'tags.json') | ConvertFrom-Json
if(@($tags).Count -ne $manifest.total){$errors+='Metadata count mismatch'}
Write-Output ('Verified dimensions and metadata: {0}/{1} portraits generated' -f $completed.Count,$manifest.total)
if($errors.Count){$errors | Write-Output;exit 1}
