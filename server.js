const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawn, exec } = require('child_process');

const PORT = process.env.PORT || 5050;
const ROOT_DIR = __dirname;
const PUBLIC_DIR = path.join(ROOT_DIR, 'public');
const BIN_DIR = path.join(ROOT_DIR, 'bin');
const YTDLP_BIN = path.join(BIN_DIR, 'yt-dlp.exe');
const FFMPEG_BIN = path.join(BIN_DIR, 'ffmpeg.exe');

let DOWNLOADS_DIR = path.join(os.homedir(), 'Downloads', 'Persona5_Descargas');
try {
  if (!fs.existsSync(DOWNLOADS_DIR)) {
    fs.mkdirSync(DOWNLOADS_DIR, { recursive: true });
  }
} catch (err) {
  DOWNLOADS_DIR = path.join(ROOT_DIR, 'downloads');
  if (!fs.existsSync(DOWNLOADS_DIR)) {
    try { fs.mkdirSync(DOWNLOADS_DIR, { recursive: true }); } catch (e) {}
  }
}

// Active jobs map: jobId -> { proc, logs: [], status: 'running'|'done'|'error', progress: {} }
const jobs = new Map();
// SSE subscribers: jobId -> Set of response objects
const subscribers = new Map();

function broadcast(jobId, data) {
  const clients = subscribers.get(jobId);
  if (!clients) return;
  const msg = `data: ${JSON.stringify(data)}\n\n`;
  for (const client of clients) {
    try {
      client.write(msg);
    } catch (e) {
      // client disconnected
    }
  }
}

function buildCommandArgs(opts) {
  const { url, mode = 'allout', threads = 16, playlist = false } = opts;
  const hasFfmpeg = fs.existsSync(FFMPEG_BIN);

  const args = [
    '-P', DOWNLOADS_DIR,
    '-o', '%(title)s.%(ext)s',
    '-N', String(threads || 16),
    '--no-mtime',
    '--progress',
    '--newline'
  ];

  if (hasFfmpeg) {
    args.unshift('--ffmpeg-location', BIN_DIR);
  }

  if (!playlist) {
    args.push('--no-playlist');
  }

  if (mode === 'allout') {
    if (hasFfmpeg) {
      args.push('-f', 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b', '--merge-output-format', 'mp4');
    } else {
      args.push('-f', 'b[ext=mp4]/best[ext=mp4]/best');
    }
  } else if (mode === 'swift') {
    args.push('-f', 'b[ext=mp4]/best[ext=mp4]/best');
  } else if (mode === 'audio') {
    args.push('-x', '--audio-format', 'mp3', '--audio-quality', '0');
  } else if (mode === 'mkv') {
    args.push('-f', 'bv*+ba/b', '--merge-output-format', 'mkv');
  }

  args.push(url.trim());
  return args;
}

function buildNativeCmdString(opts) {
  const args = buildCommandArgs(opts);
  const quotedArgs = args.map(a => (a.includes(' ') || a.includes('&') || a.includes('^')) ? `"${a}"` : a);
  return `"${YTDLP_BIN}" ${quotedArgs.join(' ')}`;
}

const server = http.createServer((req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
  const pathname = parsedUrl.pathname;

  // Static files
  if (req.method === 'GET' && (pathname === '/' || pathname === '/index.html')) {
    const indexPath = path.join(PUBLIC_DIR, 'index.html');
    fs.readFile(indexPath, 'utf8', (err, data) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Error loading index.html: ' + err.message);
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(data);
    });
    return;
  }

  if (req.method === 'GET' && pathname === '/icon.png') {
    const iconPath = path.join(PUBLIC_DIR, 'icon.png');
    if (fs.existsSync(iconPath)) {
      res.writeHead(200, { 'Content-Type': 'image/png' });
      fs.createReadStream(iconPath).pipe(res);
      return;
    }
  }

  if (req.method === 'GET' && (pathname === '/icon.ico' || pathname === '/favicon.ico')) {
    const icoPath = path.join(PUBLIC_DIR, 'icon.ico');
    if (fs.existsSync(icoPath)) {
      res.writeHead(200, { 'Content-Type': 'image/x-icon' });
      fs.createReadStream(icoPath).pipe(res);
      return;
    }
  }

  // API: Status
  if (req.method === 'GET' && pathname === '/api/status') {
    const hasYtdlp = fs.existsSync(YTDLP_BIN);
    const hasFfmpeg = fs.existsSync(FFMPEG_BIN);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      ok: true,
      ytdlp: hasYtdlp,
      ffmpeg: hasFfmpeg,
      downloadsDir: DOWNLOADS_DIR,
      activeJobsCount: jobs.size
    }));
    return;
  }

  // API: Get CMD string
  if (req.method === 'POST' && pathname === '/api/cmd-string') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const opts = JSON.parse(body || '{}');
        const cmdStr = buildNativeCmdString(opts);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, command: cmdStr, downloadsDir: DOWNLOADS_DIR }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: false, error: e.message }));
      }
    });
    return;
  }

  // API: Open native CMD window
  if (req.method === 'POST' && pathname === '/api/launch-cmd') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const opts = JSON.parse(body || '{}');
        const cmdStr = buildNativeCmdString(opts);
        
        // Spawn cmd in separate window: start cmd.exe /k ...
        const fullBatch = `title PERSONA 5 - CMD VIDEO DOWNLOADER && echo [PHANTOM THIEVES - INITIATING DOWNLOAD] && cd /d "${DOWNLOADS_DIR}" && ${cmdStr} && echo. && echo [STEAL COMPLETE! File saved in ${DOWNLOADS_DIR}] && pause`;
        
        spawn('cmd.exe', ['/c', 'start', 'cmd.exe', '/k', fullBatch], {
          detached: true,
          stdio: 'ignore'
        }).unref();

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, message: 'CMD window launched successfully!' }));
      } catch (e) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: false, error: e.message }));
      }
    });
    return;
  }

  // API: Open Downloads Folder in Explorer
  if (req.method === 'POST' && pathname === '/api/open-folder') {
    try {
      spawn('explorer.exe', [DOWNLOADS_DIR], { detached: true, stdio: 'ignore' }).unref();
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ok: true }));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ok: false, error: e.message }));
    }
    return;
  }

  // API: Start download
  if (req.method === 'POST' && pathname === '/api/download') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const opts = JSON.parse(body || '{}');
        if (!opts.url || !opts.url.trim()) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: false, error: 'URL is required' }));
          return;
        }

        const jobId = 'steal_' + Date.now() + '_' + Math.floor(Math.random() * 1000);
        const args = buildCommandArgs(opts);

        const proc = spawn(YTDLP_BIN, args, {
          cwd: DOWNLOADS_DIR,
          windowsHide: true
        });

        const job = {
          id: jobId,
          proc,
          url: opts.url,
          mode: opts.mode,
          status: 'running',
          percent: 0,
          speed: '--',
          eta: '--',
          size: '--',
          logs: [`> yt-dlp ${args.join(' ')}`]
        };
        jobs.set(jobId, job);

        const handleData = (chunk) => {
          const lines = chunk.toString().split(/\r?\n/);
          for (const line of lines) {
            if (!line.trim()) continue;
            job.logs.push(line);
            if (job.logs.length > 500) job.logs.shift();

            // Parse progress: [download]  45.2% of ~  15.00MiB at   12.50MiB/s ETA 00:01
            const match = line.match(/\[download\]\s+(\d+\.?\d*)%\s+of\s+~?([^\s]+)\s+at\s+([^\s]+)\s+ETA\s+([^\s]+)/i);
            if (match) {
              job.percent = parseFloat(match[1]);
              job.size = match[2];
              job.speed = match[3];
              job.eta = match[4];
            } else if (line.includes('100%') || line.includes('has already been downloaded')) {
              job.percent = 100;
            }

            broadcast(jobId, {
              type: 'log',
              line,
              percent: job.percent,
              speed: job.speed,
              eta: job.eta,
              size: job.size
            });
          }
        };

        proc.stdout.on('data', handleData);
        proc.stderr.on('data', handleData);

        proc.on('close', (code) => {
          job.status = code === 0 ? 'done' : 'error';
          broadcast(jobId, {
            type: 'done',
            code,
            status: job.status,
            percent: code === 0 ? 100 : job.percent,
            message: code === 0 ? 'Download complete! Video stolen successfully.' : `Process exited with code ${code}`
          });
          setTimeout(() => {
            jobs.delete(jobId);
            subscribers.delete(jobId);
          }, 30000);
        });

        proc.on('error', (err) => {
          job.status = 'error';
          broadcast(jobId, {
            type: 'error',
            error: err.message
          });
        });

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true, jobId }));
      } catch (e) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: false, error: e.message }));
      }
    });
    return;
  }

  // API: SSE stream for job progress
  if (req.method === 'GET' && pathname === '/api/stream') {
    const jobId = parsedUrl.searchParams.get('jobId');
    if (!jobId || !jobs.has(jobId)) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Job not found');
      return;
    }

    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*'
    });

    if (!subscribers.has(jobId)) {
      subscribers.set(jobId, new Set());
    }
    const clientSet = subscribers.get(jobId);
    clientSet.add(res);

    // Send initial backlog
    const job = jobs.get(jobId);
    res.write(`data: ${JSON.stringify({
      type: 'init',
      logs: job.logs,
      percent: job.percent,
      speed: job.speed,
      eta: job.eta,
      size: job.size,
      status: job.status
    })}\n\n`);

    req.on('close', () => {
      clientSet.delete(res);
      if (clientSet.size === 0) {
        subscribers.delete(jobId);
      }
    });
    return;
  }

  // API: Cancel job
  if (req.method === 'POST' && pathname === '/api/cancel') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const { jobId } = JSON.parse(body || '{}');
        if (jobs.has(jobId)) {
          const job = jobs.get(jobId);
          try {
            // Kill process tree
            exec(`taskkill /pid ${job.proc.pid} /T /F`);
          } catch (e) {
            job.proc.kill('SIGKILL');
          }
          job.status = 'cancelled';
          broadcast(jobId, { type: 'done', code: -1, status: 'cancelled', message: 'Mission aborted.' });
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true }));
      } catch (e) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: false, error: e.message }));
      }
    });
    return;
  }

  // 404 fallback
  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not Found');
});

// Port finder with automatic browser opener
function startServer(portToTry, attemptsLeft = 10) {
  server.once('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.log(`[AVISO] Puerto ${portToTry} ocupado. Probando puerto ${portToTry + 1}...`);
      if (attemptsLeft > 0) {
        startServer(portToTry + 1, attemptsLeft - 1);
      } else {
        console.error('[ERROR] No se pudo encontrar ningun puerto libre.');
        process.exit(1);
      }
    } else {
      console.error('[ERROR]', err.message);
    }
  });

  server.listen(portToTry, '127.0.0.1', () => {
    console.log(`====================================================`);
    console.log(`  ★ PERSONA 5 PHANTOM THIEVES VIDEO DOWNLOADER ★  `);
    console.log(`  Servidor activo en: http://127.0.0.1:${portToTry}`);
    console.log(`  Carpeta destino:   ${DOWNLOADS_DIR}`);
    console.log(`  Presiona CTRL + C para detener el servidor.`);
    console.log(`====================================================`);
    
    // Open default browser on the active port
    try {
      exec(`start "" "http://127.0.0.1:${portToTry}"`);
    } catch (e) {}
  });
}

startServer(PORT);
