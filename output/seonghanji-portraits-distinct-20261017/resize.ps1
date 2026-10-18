param([Parameter(Mandatory=$true)][string]$Source,[Parameter(Mandatory=$true)][string]$Destination)
Add-Type -AssemblyName System.Drawing
$sourceImage=[System.Drawing.Image]::FromFile($Source)
$bitmap=New-Object System.Drawing.Bitmap(561,701)
$graphics=[System.Drawing.Graphics]::FromImage($bitmap)
try {
 $graphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $graphics.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
 $graphics.DrawImage($sourceImage,0,0,561,701)
 $bitmap.Save($Destination,[System.Drawing.Imaging.ImageFormat]::Png)
} finally { $graphics.Dispose();$bitmap.Dispose();$sourceImage.Dispose() }
