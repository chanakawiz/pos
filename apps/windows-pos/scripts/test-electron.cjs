// Use the same Node ABI as the packaged app; native modules are rebuilt for Electron.
const { spawnSync } = require('node:child_process');
const { readdirSync } = require('node:fs');
const path = require('node:path');
const directory = path.join(__dirname, '../dist-electron/tests');
const tests = readdirSync(directory).filter((file) => file.endsWith('.test.js')).map((file) => path.join(directory, file));
if (tests.length === 0) throw new Error('No compiled Electron tests found');
const result = spawnSync(require('electron'), ['--test', ...tests], {
  stdio: 'inherit',
  env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' },
});
if (result.error) throw result.error;
process.exit(result.status ?? 1);
