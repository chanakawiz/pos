const { writeFileSync } = require('node:fs');
const path = require('node:path');

writeFileSync(path.join(__dirname, '../dist-electron/package.json'), JSON.stringify({ type: 'commonjs' }));
