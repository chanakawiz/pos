const { cpSync, writeFileSync } = require('node:fs');
const path = require('node:path');

writeFileSync(path.join(__dirname, '../dist-electron/package.json'), JSON.stringify({ type: 'commonjs' }));
cpSync(path.join(__dirname, '../electron/assets'), path.join(__dirname, '../dist-electron/assets'), { recursive: true });
