const express = require('express');
const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: '/home/mohittokas/RepCount/.env' });

const app = express();
const HTTP_PORT = process.env.PORT || 3000;
const HTTPS_PORT = process.env.HTTPS_PORT || 3443;

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(express.static(path.join(__dirname, 'build', 'web')));

app.get('/api/firebase-config', (req, res) => {
  res.json({
    apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY,
    authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID,
    storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID,
  });
});

app.get('*', (req, res) => {
  const indexPath = path.join(__dirname, 'build', 'web', 'index.html');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.setHeader('Content-Type', 'text/html');
    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>RepCount - Build Required</title>
        <style>
          body {
            background-color: #11111b;
            color: #ffffff;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            text-align: center;
          }
          .card {
            background-color: #1e1e2e;
            padding: 32px;
            border-radius: 16px;
            border: 1px solid rgba(255,255,255,0.08);
            max-width: 500px;
            box-shadow: 0 8px 30px rgba(0,0,0,0.5);
          }
          h2 { color: #6c5ce7; margin-top: 0; }
          code {
            background-color: #11111b;
            padding: 8px 12px;
            border-radius: 6px;
            font-family: monospace;
            display: inline-block;
            margin: 12px 0;
            border: 1px solid rgba(255,255,255,0.05);
            color: #00b894;
          }
          p { color: #a6adc8; line-height: 1.5; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="card">
          <h2>🚧 Flutter Web Build Required</h2>
          <p>The server is configured to serve your unified Flutter app, but the compiled web files were not found.</p>
          <p>Please run the following command in your terminal on your host machine to build the web target:</p>
          <code>flutter build web</code>
          <p>After the build completes, simply refresh this page to preview your app!</p>
        </div>
      </body>
      </html>
    `);
  }
});

// Load SSL Key & Certificate
const sslOptions = {
  key: fs.readFileSync(path.join(__dirname, 'key.pem')),
  cert: fs.readFileSync(path.join(__dirname, 'cert.pem')),
};

// Start HTTPS Server
https.createServer(sslOptions, app).listen(HTTPS_PORT, () => {
  console.log(`🔒 SSL HTTPS Server running at https://localhost:${HTTPS_PORT}`);
});

// Start HTTP Server
http.createServer(app).listen(HTTP_PORT, () => {
  console.log(`💪 HTTP Server running at http://localhost:${HTTP_PORT}`);
  console.log(`🔥 Connected to Firebase Project: ${process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID}`);
});

// Auto-rebuild Flutter Web on code changes in development
if (process.env.NODE_ENV !== 'production') {
  const { spawn } = require('child_process');
  let isBuilding = false;
  let debounceTimeout = null;

  const rebuild = () => {
    if (isBuilding) return;
    isBuilding = true;
    console.log('⚡ Code change in lib/ detected! Running "flutter build web"...');
    
    const proc = spawn('flutter', ['build', 'web'], { stdio: 'inherit', shell: true });
    
    proc.on('error', (err) => {
      isBuilding = false;
      console.warn('⚠️ Could not run "flutter build web". Make sure Flutter SDK is installed and on your PATH.');
    });

    proc.on('close', (code) => {
      isBuilding = false;
      if (code === 0) {
        console.log('✅ Flutter Web rebuild complete!');
      } else {
        console.warn(`⚠️ Flutter Web rebuild completed with exit code ${code}`);
      }
    });
  };

  const libPath = path.join(__dirname, 'lib');
  if (fs.existsSync(libPath)) {
    console.log('👀 Watching lib/ for changes to auto-rebuild Flutter Web...');
    fs.watch(libPath, { recursive: true }, (eventType, filename) => {
      if (filename && filename.endsWith('.dart')) {
        if (debounceTimeout) clearTimeout(debounceTimeout);
        debounceTimeout = setTimeout(rebuild, 500);
      }
    });
    // Trigger initial check/rebuild if build/web doesn't exist
    if (!fs.existsSync(path.join(__dirname, 'build', 'web', 'index.html'))) {
      rebuild();
    }
  }
}
