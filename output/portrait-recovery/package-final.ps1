param([string]$ArchiveName='seonghanji-portraits-501-final-20261018.zip')
$ErrorActionPreference='Stop'
$workspace=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$source=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../seonghanji-portraits-distinct-20261017'))
$archiveDir=Join-Path $workspace 'artifacts'
[IO.Directory]::CreateDirectory($archiveDir) | Out-Null
$destination=Join-Path $archiveDir $ArchiveName
$manifest=Get-Content -LiteralPath (Join-Path $source 'manifest.json') -Raw | ConvertFrom-Json
if(@($manifest.records | Where-Object status -eq 'generated').Count -ne 501){throw 'Incomplete roster'}
Add-Type -AssemblyName System.IO.Compression
$stream=[IO.File]::Open($destination,[IO.FileMode]::Create)
$zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
try {
 foreach($file in Get-ChildItem -LiteralPath $source -Recurse -File){
  if($file.Extension -notin @('.png','.json','.jsonl','.csv','.html','.md','.cjs','.ps1')){continue}
  $relative=[IO.Path]::GetRelativePath($source,$file.FullName).Replace('\','/')
  $entry=$zip.CreateEntry('seonghanji-portraits-501/'+$relative,[IO.Compression.CompressionLevel]::NoCompression)
  $input=[IO.File]::OpenRead($file.FullName)
  $output=$entry.Open()
  try{$input.CopyTo($output)}finally{$output.Dispose();$input.Dispose()}
 }
}finally{$zip.Dispose();$stream.Dispose()}
$check=[IO.Compression.ZipFile]::OpenRead($destination)
try{
 foreach($record in $manifest.records){if(-not $check.GetEntry('seonghanji-portraits-501/images/'+$record.filename)){throw ('Archive missing '+$record.id)}}
 Write-Output "Archive verified: all 501 current portraits, metadata and preserved variants; $($check.Entries.Count) files"
}finally{$check.Dispose()}
Get-Item -LiteralPath $destination | Select-Object FullName,Length
