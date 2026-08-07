const express = require('express');
const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: '/home/mohittokas/RepCount/.env' });

const app = express();
const HTTP_PORT = process.env.PORT || 3000;
const HTTPS_PORT = process.env.HTTPS_PORT || 3443;

app.use(express.static(path.join(__dirname, 'public')));

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
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
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
