const { spawnSync } = require('node:child_process');
const path = require('node:path');
const fs = require('node:fs');
const os = require('node:os');
const environment = { ...process.env };
delete environment.ELECTRON_RUN_AS_NODE;
const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'smartshop-ui-smoke-'));
environment.SMARTSHOP_SMOKE_DIR = directory;
const result = spawnSync(require('electron'), [path.join(__dirname, 'smoke-electron.cjs')], {
  stdio: 'inherit', env: environment,
});
fs.rmSync(directory, { recursive: true, force: true, maxRetries: 3 });
if (result.error) throw result.error;
process.exit(result.status ?? 1);
