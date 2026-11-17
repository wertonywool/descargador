# PowerShell script to generate Persona 5 Icon (PNG & ICO)
Add-Type -AssemblyName System.Drawing

$size = 256
$bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# Clear with transparent
$g.Clear([System.Drawing.Color]::Transparent)

# Palette
$cBlack = [System.Drawing.Color]::FromArgb(255, 15, 15, 18)
$cRed = [System.Drawing.Color]::FromArgb(255, 227, 6, 19)
$cDarkRed = [System.Drawing.Color]::FromArgb(255, 170, 0, 10)
$cWhite = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
$cYellow = [System.Drawing.Color]::FromArgb(255, 255, 220, 0)

$brushBlack = New-Object System.Drawing.SolidBrush($cBlack)
$brushRed = New-Object System.Drawing.SolidBrush($cRed)
$brushDarkRed = New-Object System.Drawing.SolidBrush($cDarkRed)
$brushWhite = New-Object System.Drawing.SolidBrush($cWhite)
$brushYellow = New-Object System.Drawing.SolidBrush($cYellow)
$penBlack = New-Object System.Drawing.Pen($cBlack, 5)
$penWhite = New-Object System.Drawing.Pen($cWhite, 4)

# 1. Base angled badge / Persona 5 skewed background card
$bgPoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(20, 45),
    [System.Drawing.PointF]::new(235, 15),
    [System.Drawing.PointF]::new(245, 205),
    [System.Drawing.PointF]::new(35, 245)
)
$g.FillPolygon($brushBlack, $bgPoints)

# Red inner border / slash
$redBorderPoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(26, 50),
    [System.Drawing.PointF]::new(229, 21),
    [System.Drawing.PointF]::new(239, 199),
    [System.Drawing.PointF]::new(41, 239)
)
$penRedOuter = New-Object System.Drawing.Pen($cRed, 6)
$g.DrawPolygon($penRedOuter, $redBorderPoints)

# Dramatic Red flame shapes (The Take Your Heart flame backdrop)
$flamePoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(128, 30),
    [System.Drawing.PointF]::new(185, 60),
    [System.Drawing.PointF]::new(215, 115),
    [System.Drawing.PointF]::new(190, 170),
    [System.Drawing.PointF]::new(128, 225),
    [System.Drawing.PointF]::new(65, 170),
    [System.Drawing.PointF]::new(40, 115),
    [System.Drawing.PointF]::new(70, 60)
)
$g.FillPolygon($brushRed, $flamePoints)

# Dramatic inner black heart shape
$heartPoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(128, 70),
    [System.Drawing.PointF]::new(170, 95),
    [System.Drawing.PointF]::new(190, 135),
    [System.Drawing.PointF]::new(128, 205),
    [System.Drawing.PointF]::new(66, 135),
    [System.Drawing.PointF]::new(86, 95)
)
$g.FillPolygon($brushBlack, $heartPoints)

# Persona 5 Phantom Mask (White sharp masquerade mask)
$maskPoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(50, 105),
    [System.Drawing.PointF]::new(90, 92),
    [System.Drawing.PointF]::new(128, 120),
    [System.Drawing.PointF]::new(166, 92),
    [System.Drawing.PointF]::new(206, 105),
    [System.Drawing.PointF]::new(185, 150),
    [System.Drawing.PointF]::new(145, 160),
    [System.Drawing.PointF]::new(128, 152),
    [System.Drawing.PointF]::new(111, 160),
    [System.Drawing.PointF]::new(71, 150)
)
$g.FillPolygon($brushWhite, $maskPoints)

# Mask Eyes (slanted sharp angular black eye cutouts)
$leftEye = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(80, 118),
    [System.Drawing.PointF]::new(110, 125),
    [System.Drawing.PointF]::new(92, 138)
)
$rightEye = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(176, 118),
    [System.Drawing.PointF]::new(146, 125),
    [System.Drawing.PointF]::new(164, 138)
)
$g.FillPolygon($brushBlack, $leftEye)
$g.FillPolygon($brushBlack, $rightEye)

# Stylized Yellow Stars / Sparks (Signature P5 battle stars)
function DrawStar($cx, $cy, $rOuter, $rInner, $brush) {
    $pts = [System.Drawing.PointF[]]::new(8)
    for ($i = 0; $i -lt 8; $i++) {
        $angle = ($i * [Math]::PI / 4) - ([Math]::PI / 2)
        $r = if ($i % 2 -eq 0) { $rOuter } else { $rInner }
        $x = $cx + [Math]::Cos($angle) * $r
        $y = $cy + [Math]::Sin($angle) * $r
        $pts[$i] = [System.Drawing.PointF]::new($x, $y)
    }
    $g.FillPolygon($brush, $pts)
}

DrawStar 205 50 18 6 $brushYellow
DrawStar 48 200 15 5 $brushYellow
DrawStar 215 190 12 4 $brushWhite

# Little download arrow in yellow
$arrowPoints = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(128, 195),
    [System.Drawing.PointF]::new(112, 172),
    [System.Drawing.PointF]::new(120, 172),
    [System.Drawing.PointF]::new(120, 155),
    [System.Drawing.PointF]::new(136, 155),
    [System.Drawing.PointF]::new(136, 172),
    [System.Drawing.PointF]::new(144, 172)
)
$g.FillPolygon($brushYellow, $arrowPoints)
$penBlackThin = New-Object System.Drawing.Pen($cBlack, 2)
$g.DrawPolygon($penBlackThin, $arrowPoints)

$destDir = "$PSScriptRoot"
$pngPath = Join-Path $destDir "icon.png"
$bmp.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)

# Convert PNG to valid multi-res ICO
$icoPath = Join-Path $destDir "icon.ico"
$pngBytes = [System.IO.File]::ReadAllBytes($pngPath)

$fs = [System.IO.File]::Create($icoPath)
$bw = New-Object System.IO.BinaryWriter($fs)

# ICONDIR header
$bw.Write([UInt16]0) # Reserved
$bw.Write([UInt16]1) # 1 = Icon
$bw.Write([UInt16]1) # Number of images

# ICONDIRENTRY
$bw.Write([Byte]0)   # Width: 0 = 256px
$bw.Write([Byte]0)   # Height: 0 = 256px
$bw.Write([Byte]0)   # Palette
$bw.Write([Byte]0)   # Reserved
$bw.Write([UInt16]1) # Color planes
$bw.Write([UInt16]32)# Bits per pixel
$bw.Write([UInt32]$pngBytes.Length) # Image size in bytes
$bw.Write([UInt32]22) # Image offset (6 + 16 = 22)

# Write PNG payload
$bw.Write($pngBytes)

$bw.Flush()
$fs.Close()

Write-Host "Icon created successfully: $pngPath and $icoPath"
