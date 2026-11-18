import os
import sys
import yt_dlp

def run_download(url, mode, threads, output_dir, playlist, callback):
    """
    Motor autónomo yt-dlp ejecutándose de forma nativa en Android.
    No requiere servidores externos ni binario ffmpeg.
    """
    try:
        callback.onProgress(5.0, "-- MB/s", "--:--", "Conectando con el video...")
    except Exception:
        pass

    def progress_hook(d):
        try:
            status = d.get('status', '')
            if status == 'downloading':
                total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
                downloaded = d.get('downloaded_bytes') or 0
                percent = (downloaded / total * 100.0) if total > 0 else 15.0
                
                speed = d.get('speed') or 0
                speed_str = f"{speed / (1024 * 1024):.1f} MB/s" if speed else "-- MB/s"
                
                eta = d.get('eta') or 0
                eta_str = f"{int(eta // 60):02d}:{int(eta % 60):02d}" if eta else "--:--"
                
                callback.onProgress(float(percent), speed_str, eta_str, "Descargando...")
            elif status == 'finished':
                callback.onProgress(100.0, "100%", "00:00", "Guardando archivo...")
        except Exception:
            pass

    # Asegurar que el directorio de salida existe
    os.makedirs(output_dir, exist_ok=True)

    opts = {
        'outtmpl': os.path.join(output_dir, '%(title)s.%(ext)s'),
        'concurrent_fragment_downloads': int(threads or 8),
        'progress_hooks': [progress_hook],
        'no_mtime': True,
        'nocheckcertificate': True,
        'ignoreerrors': False,
        'noplaylist': not bool(playlist),
        'prefer_ffmpeg': False,
        'quiet': True,
        'no_warnings': True,
    }

    # Selección inteligente de formatos compatibles nativamente en Android sin ffmpeg:
    if mode == 'allout':
        # Video de mejor calidad con audio ya integrado en un solo contenedor
        opts['format'] = 'best[vcodec!=none][acodec!=none][ext=mp4]/best[vcodec!=none][acodec!=none]/b[ext=mp4]/b/best'
    elif mode == 'swift':
        opts['format'] = 'b[ext=mp4]/b/best'
    elif mode == 'audio':
        # Audio directo nativo reproducible en cualquier teléfono
        opts['format'] = 'bestaudio[ext=m4a]/bestaudio[ext=mp3]/bestaudio/best'
    elif mode == 'mkv':
        opts['format'] = 'best[vcodec!=none][acodec!=none]/best'

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            ydl.download([url])
        callback.onComplete(True, "Descarga guardada con éxito en la carpeta Descargas de tu teléfono.")
    except Exception as e:
        callback.onComplete(False, f"Error al descargar: {str(e)}")
