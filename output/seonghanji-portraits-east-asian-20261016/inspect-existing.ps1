Add-Type -AssemblyName System.Drawing
$manifest=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'source-inventory.json') | ConvertFrom-Json
$qa=Join-Path $PSScriptRoot 'qa-existing'
[System.IO.Directory]::CreateDirectory($qa) | Out-Null
$font=New-Object System.Drawing.Font('Arial',10)
try {
 for($offset=0;$offset -lt $manifest.Count;$offset+=30){
  $canvas=New-Object System.Drawing.Bitmap(1122,1295)
  $g=[System.Drawing.Graphics]::FromImage($canvas)
  try {
   $g.Clear([System.Drawing.Color]::FromArgb(12,20,28))
   $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
   for($n=0;$n -lt 30 -and $offset+$n -lt $manifest.Count;$n++){
    $r=$manifest[$offset+$n];$img=[System.Drawing.Image]::FromFile($r.file)
    $x=($n%6)*187;$y=[math]::Floor($n/6)*259
    try {$g.DrawImage($img,[int]$x,[int]$y,187,234)}finally{$img.Dispose()}
    $g.DrawString($r.id,$font,[System.Drawing.Brushes]::White,[single]$x,[single]($y+236))
   }
   $canvas.Save((Join-Path $qa ('sheet-{0:D2}.jpg' -f (1+$offset/30))),[System.Drawing.Imaging.ImageFormat]::Jpeg)
  } finally {$g.Dispose();$canvas.Dispose()}
 }
} finally {$font.Dispose()}
Write-Output ('Contact sheets created for {0} existing portraits' -f $manifest.Count)
