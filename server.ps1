# Persona 5 Video Downloader - Native PowerShell Server (Zero Dependencies)
# Runs natively on ANY Windows 10/11 system without Node.js or Python!

$port = 5050
$rootDir = $PSScriptRoot
if (-not $rootDir) { $rootDir = (Get-Location).Path }
$publicDir = Join-Path $rootDir "public"
$binDir = Join-Path $rootDir "bin"
$ytdlpBin = Join-Path $binDir "yt-dlp.exe"
$ffmpegBin = Join-Path $binDir "ffmpeg.exe"

$downloadsDir = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads\Persona5_Descargas"
if (-not (Test-Path $downloadsDir)) {
    try { New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null } catch {}
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://127.0.0.1:$port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    $port = 5055
    $prefix = "http://127.0.0.1:$port/"
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix)
    $listener.Start()
}

Write-Host "===========================================================" -ForegroundColor Red
Write-Host "   ★ PERSONA 5 PHANTOM THIEVES - SERVIDOR POWERSHELL ★   " -ForegroundColor Yellow
Write-Host "   Servidor activo en: $prefix" -ForegroundColor White
Write-Host "   Carpeta destino:   $downloadsDir" -ForegroundColor Gray
Write-Host "===========================================================" -ForegroundColor Red

# Open browser
Start-Process $prefix

$activeJobs = @{}

function Get-ContentType($path) {
    $ext = [System.IO.Path]::GetExtension($path).ToLower()
    switch ($ext) {
        ".html" { return "text/html; charset=utf-8" }
        ".png"  { return "image/png" }
        ".ico"  { return "image/x-icon" }
        ".css"  { return "text/css; charset=utf-8" }
        ".js"   { return "application/javascript; charset=utf-8" }
        default { return "application/octet-stream" }
    }
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $req = $context.Request
    $res = $context.Response
    $urlPath = $req.Url.AbsolutePath

    # Allow CORS
    $res.AddHeader("Access-Control-Allow-Origin", "*")
    $res.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    $res.AddHeader("Access-Control-Allow-Headers", "Content-Type")

    if ($req.HttpMethod -eq "OPTIONS") {
        $res.StatusCode = 200
        $res.Close()
        continue
    }

    # Static routes
    if ($urlPath -eq "/" -or $urlPath -eq "/index.html") {
        $filePath = Join-Path $publicDir "index.html"
        if (Test-Path $filePath) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $res.ContentType = "text/html; charset=utf-8"
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
            $res.Close()
            continue
        }
    }

    if ($urlPath -eq "/icon.png") {
        $filePath = Join-Path $publicDir "icon.png"
        if (Test-Path $filePath) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $res.ContentType = "image/png"
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
            $res.Close()
            continue
        }
    }

    if ($urlPath -eq "/icon.ico" -or $urlPath -eq "/favicon.ico") {
        $filePath = Join-Path $publicDir "icon.ico"
        if (Test-Path $filePath) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $res.ContentType = "image/x-icon"
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
            $res.Close()
            continue
        }
    }

    # API Status
    if ($urlPath -eq "/api/status") {
        $json = @{
            ok = $true
            ytdlp = (Test-Path $ytdlpBin)
            ffmpeg = (Test-Path $ffmpegBin)
            downloadsDir = $downloadsDir
            activeJobsCount = $activeJobs.Count
            serverType = "PowerShell Native"
        } | ConvertTo-Json
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $res.ContentType = "application/json"
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
        continue
    }

    # Read body for POST
    $body = ""
    if ($req.HasEntityBody) {
        $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
        $body = $reader.ReadToEnd()
        $reader.Close()
    }

    # API: Open folder
    if ($urlPath -eq "/api/open-folder") {
        Start-Process "explorer.exe" -ArgumentList "`"$downloadsDir`""
        $json = '{"ok":true}'
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $res.ContentType = "application/json"
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
        continue
    }

    # API: Launch CMD window
    if ($urlPath -eq "/api/launch-cmd") {
        $opts = $body | ConvertFrom-Json
        $url = $opts.url
        $mode = if ($opts.mode) { $opts.mode } else { "allout" }
        $threads = if ($opts.threads) { $opts.threads } else { 16 }
        $playlist = if ($opts.playlist) { "" } else { "--no-playlist" }

        $fmt = ""
        if ($mode -eq "allout") {
            $fmt = if (Test-Path $ffmpegBin) { '-f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b" --merge-output-format mp4' } else { '-f "b[ext=mp4]/best[ext=mp4]/best"' }
        } elseif ($mode -eq "swift") {
            $fmt = '-f "b[ext=mp4]/best[ext=mp4]/best"'
        } elseif ($mode -eq "audio") {
            $fmt = '-x --audio-format mp3 --audio-quality 0'
        } elseif ($mode -eq "mkv") {
            $fmt = '-f "bv*+ba/b" --merge-output-format mkv'
        }

        $cmdStr = "`"$ytdlpBin`" --ffmpeg-location `"$binDir`" -P `"$downloadsDir`" -o `"%(title)s.%(ext)s`" -N $threads --no-mtime --progress $playlist $fmt `"$url`""
        $batch = "title PERSONA 5 - CMD VIDEO DOWNLOADER && echo [PHANTOM THIEVES - INICIANDO DESCARGA] && cd /d `"$downloadsDir`" && $cmdStr && echo. && echo [DESCARGA COMPLETADA] && pause"
        Start-Process "cmd.exe" -ArgumentList "/c start cmd.exe /k `"$batch`""

        $json = '{"ok":true,"message":"CMD abierto con exito"}'
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $res.ContentType = "application/json"
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
        continue
    }

    # API: Get CMD string
    if ($urlPath -eq "/api/cmd-string") {
        $opts = $body | ConvertFrom-Json
        $url = $opts.url
        $mode = if ($opts.mode) { $opts.mode } else { "allout" }
        $threads = if ($opts.threads) { $opts.threads } else { 16 }
        $playlist = if ($opts.playlist) { "" } else { "--no-playlist" }

        $fmt = ""
        if ($mode -eq "allout") {
            $fmt = if (Test-Path $ffmpegBin) { '-f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b" --merge-output-format mp4' } else { '-f "b[ext=mp4]/best[ext=mp4]/best"' }
        } elseif ($mode -eq "swift") {
            $fmt = '-f "b[ext=mp4]/best[ext=mp4]/best"'
        } elseif ($mode -eq "audio") {
            $fmt = '-x --audio-format mp3 --audio-quality 0'
        } elseif ($mode -eq "mkv") {
            $fmt = '-f "bv*+ba/b" --merge-output-format mkv'
        }

        $cmdStr = "`"$ytdlpBin`" --ffmpeg-location `"$binDir`" -P `"$downloadsDir`" -o `"%(title)s.%(ext)s`" -N $threads --no-mtime --progress $playlist $fmt `"$url`""
        $json = @{ ok = $true; command = $cmdStr; downloadsDir = $downloadsDir } | ConvertTo-Json
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $res.ContentType = "application/json"
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
        continue
    }

    # API: Download (direct execution)
    if ($urlPath -eq "/api/download") {
        $opts = $body | ConvertFrom-Json
        $url = $opts.url
        $jobId = "steal_" + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

        # Build args
        $argsList = @(
            "--ffmpeg-location", $binDir,
            "-P", $downloadsDir,
            "-o", "%(title)s.%(ext)s",
            "-N", (if ($opts.threads) { [string]$opts.threads } else { "16" }),
            "--no-mtime",
            "--progress",
            "--newline"
        )
        if (-not $opts.playlist) { $argsList += "--no-playlist" }

        if ($opts.mode -eq "allout") {
            if (Test-Path $ffmpegBin) {
                $argsList += @("-f", "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b", "--merge-output-format", "mp4")
            } else {
                $argsList += @("-f", "b[ext=mp4]/best[ext=mp4]/best")
            }
        } elseif ($opts.mode -eq "swift") {
            $argsList += @("-f", "b[ext=mp4]/best[ext=mp4]/best")
        } elseif ($opts.mode -eq "audio") {
            $argsList += @("-x", "--audio-format", "mp3", "--audio-quality", "0")
        } elseif ($opts.mode -eq "mkv") {
            $argsList += @("-f", "bv*+ba/b", "--merge-output-format", "mkv")
        }
        $argsList += $url.Trim()

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $ytdlpBin
        $pinfo.Arguments = ($argsList | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join " "
        $pinfo.WorkingDirectory = $downloadsDir
        $pinfo.RedirectStandardOutput = $true
        $pinfo.RedirectStandardError = $true
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $pinfo
        $jobObj = [PSCustomObject]@{
            Process = $proc
            Logs = New-Object System.Collections.ArrayList
            Status = "running"
            Percent = 0
            Speed = "--"
            Eta = "--"
            Size = "--"
        }
        $activeJobs[$jobId] = $jobObj
        $null = $jobObj.Logs.Add("> yt-dlp " + $pinfo.Arguments)

        $proc.Start() | Out-Null

        # Async log reader
        [System.Threading.Tasks.Task]::Run([Action]{
            while (-not $proc.HasExited) {
                $line = $proc.StandardOutput.ReadLine()
                if ($line) {
                    $null = $jobObj.Logs.Add($line)
                    if ($line -match '\[download\]\s+(\d+\.?\d*)%\s+of\s+~?([^\s]+)\s+at\s+([^\s]+)\s+ETA\s+([^\s]+)') {
                        $jobObj.Percent = [double]$Matches[1]
                        $jobObj.Size = $Matches[2]
                        $jobObj.Speed = $Matches[3]
                        $jobObj.Eta = $Matches[4]
                    }
                }
            }
            $err = $proc.StandardError.ReadToEnd()
            if ($err) { $null = $jobObj.Logs.Add("[STDERR] " + $err) }
            $jobObj.Status = if ($proc.ExitCode -eq 0) { "done" } else { "error" }
            if ($proc.ExitCode -eq 0) { $jobObj.Percent = 100 }
        }) | Out-Null

        $json = @{ ok = $true; jobId = $jobId } | ConvertTo-Json
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $res.ContentType = "application/json"
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
        continue
    }

    # API: Stream (polling / SSE)
    if ($urlPath -eq "/api/stream") {
        $jobId = $req.QueryString["jobId"]
        $res.ContentType = "text/event-stream"
        $res.Headers.Add("Cache-Control", "no-cache")
        $res.Headers.Add("Connection", "keep-alive")

        if (-not $activeJobs.ContainsKey($jobId)) {
            $msg = "data: {`"type`":`"error`",`"error`":`"Trabajo no encontrado`"}`n`n"
            $b = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $res.OutputStream.Write($b, 0, $b.Length)
            $res.Close()
            continue
        }

        $jobObj = $activeJobs[$jobId]
        $lastLogIndex = 0

        # Stream until job finished
        while ($true) {
            $count = $jobObj.Logs.Count
            while ($lastLogIndex -lt $count) {
                $line = $jobObj.Logs[$lastLogIndex]
                $lastLogIndex++
                $payload = @{
                    type = "log"
                    line = $line
                    percent = $jobObj.Percent
                    speed = $jobObj.Speed
                    eta = $jobObj.Eta
                    size = $jobObj.Size
                } | ConvertTo-Json -Compress
                $msg = "data: $payload`n`n"
                $b = [System.Text.Encoding]::UTF8.GetBytes($msg)
                try {
                    $res.OutputStream.Write($b, 0, $b.Length)
                    $res.OutputStream.Flush()
                } catch { break }
            }

            if ($jobObj.Status -eq "done" -or $jobObj.Status -eq "error") {
                $payload = @{
                    type = "done"
                    code = if ($jobObj.Status -eq "done") { 0 } else { 1 }
                    status = $jobObj.Status
                    percent = $jobObj.Percent
                } | ConvertTo-Json -Compress
                $msg = "data: $payload`n`n"
                $b = [System.Text.Encoding]::UTF8.GetBytes($msg)
                try {
                    $res.OutputStream.Write($b, 0, $b.Length)
                    $res.OutputStream.Flush()
                } catch {}
                break
            }

            Start-Sleep -Milliseconds 250
        }

        $res.Close()
        continue
    }

    # API: Cancel
    if ($urlPath -eq "/api/cancel") {
        $opts = $body | ConvertFrom-Json
        $jobId = $opts.jobId
        if ($activeJobs.ContainsKey($jobId)) {
            $j = $activeJobs[$jobId]
            try { $j.Process.Kill() } catch {}
            $j.Status = "error"
        }
        $json = '{"ok":true}'
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $res.ContentType = "application/json"
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
        continue
    }

    $res.StatusCode = 404
    $res.Close()
}
