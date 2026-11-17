import os
import yt_dlp

def run_download(url, mode, threads, output_dir, callback):
    """
    Motor autónomo yt-dlp ejecutándose de forma nativa en Android
    """
    def progress_hook(d):
        try:
            status = d.get('status', '')
            if status == 'downloading':
                total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
                downloaded = d.get('downloaded_bytes') or 0
                percent = (downloaded / total * 100.0) if total > 0 else 0.0
                
                speed = d.get('speed') or 0
                speed_str = f"{speed / (1024 * 1024):.1f} MB/s" if speed else "-- MB/s"
                
                eta = d.get('eta') or 0
                eta_str = f"{int(eta // 60):02d}:{int(eta % 60):02d}" if eta else "--:--"
                
                callback.onProgress(float(percent), speed_str, eta_str, "downloading")
            elif status == 'finished':
                callback.onProgress(100.0, "Completado", "00:00", "finished")
        except Exception as err:
            pass

    opts = {
        'outtmpl': os.path.join(output_dir, '%(title)s.%(ext)s'),
        'concurrent_fragment_downloads': int(threads or 16),
        'progress_hooks': [progress_hook],
        'no_mtime': True,
        'nocheckcertificate': True,
        'ignoreerrors': False,
    }

    if mode == 'allout' or mode == 'swift':
        # Mejor MP4 directo compatible nativamente con reproductor de Android
        opts['format'] = 'b[ext=mp4]/best[ext=mp4]/best'
    elif mode == 'audio':
        opts['format'] = 'bestaudio/best'
    elif mode == 'mkv':
        opts['format'] = 'bv*+ba/b'

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            ydl.download([url])
        callback.onComplete(True, "Descarga guardada en la carpeta Descargas de tu telefono.")
    except Exception as e:
        callback.onComplete(False, str(e))
