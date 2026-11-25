import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { Storage } from 'megajs';
import { createServer as createViteServer } from 'vite';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = Number(process.env.PORT) || 3000;

app.use(cors());
app.use(express.json({ limit: '50mb' }));

// Configuration File path for server backup folder
const configPath = path.join(__dirname, 'backup_config.json');
let currentBackupDir = path.join(__dirname, 'backups');

function loadConfig() {
  try {
    if (fs.existsSync(configPath)) {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
      if (config.backupDir) {
        currentBackupDir = path.isAbsolute(config.backupDir)
          ? config.backupDir
          : path.resolve(__dirname, config.backupDir);
      }
    }
  } catch (err) {
    console.error('Error loading backup config:', err);
  }
}

function saveConfig(newBackupDir: string) {
  try {
    const config = { backupDir: newBackupDir };
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf-8');
    currentBackupDir = path.isAbsolute(newBackupDir)
      ? newBackupDir
      : path.resolve(__dirname, newBackupDir);
    
    if (!fs.existsSync(currentBackupDir)) {
      fs.mkdirSync(currentBackupDir, { recursive: true });
    }
  } catch (err) {
    console.error('Error saving backup config:', err);
    throw err;
  }
}

// Load initial configuration
loadConfig();

import os from 'os';
import net from 'net';
import { EnvHttpProxyAgent, setGlobalDispatcher } from 'undici';
import { ErpApi } from './src/server/api';
import { FsBackend } from './src/server/kvFs';
import { platform } from './src/server/zatcaEngine';

// خوادم الشركات التي تخرج للإنترنت عبر بروكسي: نوجّه طلبات منصة فاتورة عبره (HTTPS_PROXY / NO_PROXY)
if (process.env.HTTPS_PROXY || process.env.https_proxy || process.env.HTTP_PROXY || process.env.http_proxy) {
  try { setGlobalDispatcher(new EnvHttpProxyAgent()); } catch { /* يُستخدم الاتصال المباشر */ }
}

// Ensure active backups directory exists
if (!fs.existsSync(currentBackupDir)) {
  fs.mkdirSync(currentBackupDir, { recursive: true });
}

// API Routes
// النسخ الاحتياطي على الخادم محمي بنفس رمز المزامنة (SYNC_TOKEN) إن كان مضبوطاً
const syncAuthBackup = (req: express.Request, res: express.Response, next: express.NextFunction) => {
  const t = process.env.SYNC_TOKEN || '';
  if (t && decodeURIComponent(req.header('x-sync-token') || '') !== t) {
    res.status(401).json({ success: false, message: 'رمز المزامنة غير صحيح' });
    return;
  }
  next();
};
app.get('/api/backup/config', syncAuthBackup, (req, res) => {
  res.json({
    success: true,
    backupDir: currentBackupDir,
    defaultDir: path.join(__dirname, 'backups'),
    absolutePath: path.resolve(currentBackupDir)
  });
});

app.post('/api/backup/config', syncAuthBackup, (req, res) => {
  const { backupDir: newDir } = req.body;
  if (!newDir) {
    return res.status(400).json({ success: false, message: 'المسار مطلوب' });
  }

  try {
    const resolvedPath = path.isAbsolute(newDir) ? newDir : path.resolve(__dirname, newDir);
    if (!fs.existsSync(resolvedPath)) {
      fs.mkdirSync(resolvedPath, { recursive: true });
    }
    
    // Test write permission
    const testFile = path.join(resolvedPath, '.write-test');
    fs.writeFileSync(testFile, 'test');
    fs.unlinkSync(testFile);

    saveConfig(newDir);
    res.json({
      success: true,
      message: 'تم تحديث مسار التخزين بنجاح',
      backupDir: currentBackupDir,
      absolutePath: resolvedPath
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: `تعذر استخدام هذا المسار: ${error.message || 'خطأ غير معروف'}` });
  }
});

app.post('/api/backup', syncAuthBackup, async (req, res) => {
  const { type, data, fileName, megaEmail: reqEmail, megaPassword: reqPassword, simulateCloud } = req.body;

  if (!data || !fileName) {
    return res.status(400).json({ success: false, message: 'بيانات غير مكتملة' });
  }

  try {
    const backupPath = path.join(currentBackupDir, fileName);
    
    // 1. Save locally to server backups directory
    fs.writeFileSync(backupPath, JSON.stringify(data, null, 2));

    // 2. Upload to MEGA if requested
    if (type === 'cloud') {
      if (simulateCloud) {
        console.log('[Simulation] Uploading backup to MEGA cloud:', fileName);
        // Artificial delay for simulation realism
        await new Promise(resolve => setTimeout(resolve, 1500));
      } else {
        const megaEmail = reqEmail || process.env.MEGA_EMAIL;
        const megaPassword = reqPassword || process.env.MEGA_PASSWORD;

        if (!megaEmail || !megaPassword) {
          return res.status(400).json({ success: false, message: 'بيانات تسجيل الدخول إلى MEGA غير موجودة في المتغيرات البيئية أو الإدخال المخصص' });
        }

        const storage = await new Storage({
          email: megaEmail,
          password: megaPassword
        }).ready;

        const fileBuffer = fs.readFileSync(backupPath);
        await storage.upload(fileName, fileBuffer).complete;
      }
    }

    res.json({ 
      success: true, 
      message: type === 'cloud' 
        ? (simulateCloud ? 'تمت محاكاة الرفع إلى MEGA بنجاح (وضع التجربة)' : 'تم الرفع إلى MEGA بنجاح') 
        : 'تم الحفظ محلياً على الخادم بنجاح', 
      path: backupPath 
    });
  } catch (error: any) {
    console.error('Backup Error:', error);
    res.status(500).json({ success: false, message: error.message || 'حدث خطأ أثناء النسخ الاحتياطي' });
  }
});

app.get('/api/backup/history', syncAuthBackup, (req, res) => {
  try {
    const files = fs.readdirSync(currentBackupDir);
    const history = files
      .filter(f => f.endsWith('.json'))
      .map(fileName => {
        const stats = fs.statSync(path.join(currentBackupDir, fileName));
        return {
          fileName,
          size: stats.size,
          createdAt: stats.mtime
        };
      })
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
      
    res.json({ success: true, history });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ══════════════ قاعدة البيانات المشتركة + استعلام الأسعار + الفوترة الإلكترونية ZATCA ══════════════
// نفس واجهة /api المستخدمة على Cloudflare وFirebase (src/server/api.ts)، والتخزين هنا ملفات مجلد data.
// SYNC_TOKEN (اختياري في ملف .env): كلمة سر يجب أن يدخلها كل جهاز قبل ربطه بالخادم.
const SYNC_TOKEN = process.env.SYNC_TOKEN || '';
platform.hostname = () => os.hostname();
platform.tcpProbe = (host, port, timeout) => new Promise(resolve => {
  const s = net.createConnection({ host, port });
  const done = (ok: boolean) => { s.destroy(); resolve(ok); };
  s.setTimeout(timeout, () => done(false));
  s.once('connect', () => done(true));
  s.once('error', () => done(false));
});
const apiReady = ErpApi.open(new FsBackend(process.env.DATA_DIR || path.join(__dirname, 'data')), {
  platform: 'node', SYNC_TOKEN, MEGA_EMAIL: process.env.MEGA_EMAIL, MEGA_PASSWORD: process.env.MEGA_PASSWORD
}).then(api => {
  api.zatca.startWorker();
  return api;
});
app.use('/api', async (req, res, next) => {
  try {
    const api = await apiReady;
    const out = await api.handle({
      method: req.method, path: req.originalUrl.split('?')[0], query: req.query as Record<string, string>,
      header: n => req.header(n) || null, body: req.body
    });
    if (!out) return next();
    res.status(out.status).json(out.json);
  } catch (err: any) {
    res.status(500).json({ success: false, message: err?.message || 'خطأ في الخادم' });
  }
});

const shutdown = () => { apiReady.then(a => a.kv.flush()).finally(() => process.exit(0)); };
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

async function startServer() {
  // Vite middleware for development
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(__dirname, 'dist');
    app.use(express.static(distPath));
    app.get('*all', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
