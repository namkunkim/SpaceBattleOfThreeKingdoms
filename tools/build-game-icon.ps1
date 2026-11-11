param(
    [string]$Source = "$PSScriptRoot/../assets/branding/game-icon-source.png"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$outputDir = [IO.Path]::GetFullPath("$PSScriptRoot/../assets/branding")
[IO.Directory]::CreateDirectory($outputDir) | Out-Null
$original = [Drawing.Image]::FromFile([IO.Path]::GetFullPath($Source))
function Get-IconPng([int]$size) {
    $bitmap = [Drawing.Bitmap]::new($size, $size)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($original, 0, 0, $size, $size)
    $stream = [IO.MemoryStream]::new()
    $bitmap.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
    $bytes = $stream.ToArray()
    $stream.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
    return ,$bytes
}
try {
    [IO.File]::WriteAllBytes("$outputDir/game-icon.png", (Get-IconPng 1024))
    [IO.File]::WriteAllBytes("$outputDir/game-icon-192.png", (Get-IconPng 192))
    $sizes = @(16, 24, 32, 48, 64, 128, 256)
    $images = @($sizes | ForEach-Object { ,(Get-IconPng $_) })
    $writer = [IO.BinaryWriter]::new([IO.File]::Create("$outputDir/game-icon.ico"))
    try {
        $writer.Write([uint16]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]$sizes.Count)
        $offset = 6 + 16 * $sizes.Count
        for ($i = 0; $i -lt $sizes.Count; $i++) {
            $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
            $writer.Write([byte]$dimension)
            $writer.Write([byte]$dimension)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]32)
            $writer.Write([uint32]$images[$i].Length)
            $writer.Write([uint32]$offset)
            $offset += $images[$i].Length
        }
        foreach ($bytes in $images) { $writer.Write([byte[]]$bytes) }
    } finally { $writer.Dispose() }
} finally { $original.Dispose() }
Write-Output 'Built game-icon.png (1024), game-icon-192.png (192), and game-icon.ico (16-256).'
