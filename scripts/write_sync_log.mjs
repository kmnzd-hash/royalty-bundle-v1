// scripts/write_sync_log.mjs
import fs from 'fs';
import path from 'path';

// -------------------------------
// CONFIG
// -------------------------------
const LOG_PATH = path.resolve('./logs/sync-report.json');

// Ensure log file exists
if (!fs.existsSync(LOG_PATH)) {
  console.log('🆕 Log file not found — creating new sync-report.json');
  fs.writeFileSync(LOG_PATH, '[]', 'utf-8');
}

// -------------------------------
// APPEND FUNCTION
// -------------------------------
function appendLog(entry) {
  try {
    const logs = JSON.parse(fs.readFileSync(LOG_PATH, 'utf-8'));
    const logEntry = {
      timestamp: new Date().toISOString(),
      ...entry,
    };
    logs.push(logEntry);
    fs.writeFileSync(LOG_PATH, JSON.stringify(logs, null, 2));
    console.log(`🪵 Log entry appended (${entry.job || 'manual'}) → sync-report.json`);
  } catch (err) {
    console.error('❌ Failed to append log:', err.message);
  }
}

// -------------------------------
// CLI ENTRYPOINT
// -------------------------------
// Usage example:
// node scripts/write_sync_log.mjs cadence_runner "dry run complete" success
const [,, job = 'manual', message = 'no message', status = 'success'] = process.argv;

appendLog({
  job,
  message,
  status,
});
