const http = require('http');
const fs   = require('fs');
const path = require('path');
const dir  = __dirname;

const MIME = {
  '.html': 'text/html',
  '.js':   'application/javascript',
  '.css':  'text/css',
};

http.createServer((req, res) => {
  const file = req.url === '/' ? '/card-phase-through.html' : req.url;
  const fp   = path.join(dir, file);
  if (!fp.startsWith(dir)) { res.writeHead(403); return res.end(); }
  fs.readFile(fp, (err, data) => {
    if (err) { res.writeHead(404); return res.end('Not found'); }
    const ext  = path.extname(fp);
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'text/plain' });
    res.end(data);
  });
}).listen(7331, () => console.log('Mockup server: http://localhost:7331'));
