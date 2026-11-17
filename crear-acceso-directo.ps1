$appDir = $PSScriptRoot
if (-not $appDir) {
    $appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $appDir) {
    $appDir = "C:\Users\werto\Documents\antigravity\mysterious-lavoisier\p5-video-downloader"
}

$batPath = Join-Path $appDir "iniciar.bat"
$icoPath = Join-Path $appDir "icon.ico"

# Query Windows Registry for true Desktop
$regDesktop = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue).Desktop
if ($regDesktop -and $regDesktop.Contains('%USERPROFILE%')) {
    $regDesktop = $regDesktop.Replace('%USERPROFILE%', $env:USERPROFILE)
}

$candidates = @(
    $regDesktop,
    "C:\Users\werto\OneDrive\Desktop",
    "$env:USERPROFILE\OneDrive\Desktop",
    "$env:USERPROFILE\Desktop",
    "C:\Users\werto\Desktop"
) | Select-Object -Unique | Where-Object { $_ -and (Test-Path $_) }

$wshShell = New-Object -ComObject WScript.Shell
$count = 0

foreach ($desktop in $candidates) {
    try {
        $shortcutPath = Join-Path $desktop "Persona 5 - Descargador de Videos.lnk"
        $shortcut = $wshShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $batPath
        $shortcut.WorkingDirectory = $appDir
        $shortcut.IconLocation = "$icoPath,0"
        $shortcut.Description = "Descargador de Videos Persona 5 (Ultra Rapido CMD)"
        $shortcut.WindowStyle = 1
        $shortcut.Save()
        Write-Host "Acceso directo creado con exito en: $shortcutPath"
        $count++
    } catch {
        Write-Warning "No se pudo escribir en $desktop : $_"
    }
}

if ($count -eq 0) {
    Write-Error "No se encontro ninguna carpeta de Escritorio valida."
}
