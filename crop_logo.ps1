Add-Type -AssemblyName System.Drawing
$imgPath = "c:\MINI PROJECT-SGMSA\assets\images\logo.png"
$img = [System.Drawing.Image]::FromFile($imgPath)
$bmp = New-Object System.Drawing.Bitmap($img)

# Find content bounds (very simple approach: assuming white/transparent border)
# We look for first and last non-white pixels
$minX = $bmp.Width
$maxX = 0
$minY = $bmp.Height
$maxY = 0

for ($y = 0; $y -lt $bmp.Height; $y++) {
    for ($x = 0; $x -lt $bmp.Width; $x++) {
        $p = $bmp.GetPixel($x, $y)
        # Check if NOT white (assuming background is exactly 255,255,255 or transparent)
        if ($p.A -gt 0 -and ($p.R -lt 250 -or $p.G -lt 250 -or $p.B -lt 250)) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}

$width = $maxX - $minX + 1
$height = $maxY - $minY + 1

if ($width -gt 0 -and $height -gt 0) {
    # Add a tiny bit of padding (5%)
    $paddingX = [int]($width * 0.05)
    $paddingY = [int]($height * 0.05)
    
    $rect = New-Object System.Drawing.Rectangle($minX, $minY, $width, $height)
    $cropped = $bmp.Clone($rect, $bmp.PixelFormat)
    
    $img.Dispose()
    $bmp.Dispose()
    
    $cropped.Save($imgPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $cropped.Dispose()
    Write-Host "Cropped image to $minX, $minY, $width, $height"
} else {
    $img.Dispose()
    $bmp.Dispose()
    Write-Host "Could not find content to crop"
}
