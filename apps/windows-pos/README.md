# SmartShop desktop POS

Electron, React, TypeScript, and a main-process `better-sqlite3` database.

## Development

Use Node.js 24 LTS (minimum 22.12). Install dependencies with `npm ci`; the postinstall step rebuilds SQLite for Electron's ABI. After changing Electron versions or CPU architecture, run `npm run rebuild:native`.

Copy `.env.example` to `.env`. Configure the API URL and `VITE_DEVICE_UUID` using an active device registered to the cashier's store in Filament. The successful login persists this device UUID for the terminal. A stored UUID takes precedence over the environment value; to reconfigure an existing terminal, close the app and back up its database/queue before changing its device configuration. Do not reuse another lane's identity.

Run the backend migrations, including `2026_10_17_000001_create_sync_revisions_tables.php`, before starting this client. Then use two terminals:

```sh
npm run dev
```

```sh
npm run build:electron
npm run electron:start
```

`npm run dev` alone opens a browser preview with online checkout. Offline persistence requires Electron. `VITE_DEV_SERVER_URL` can override Electron's development URL (default `http://localhost:5173`).

## Persistence and recovery

The database is `smartshop_pos.sqlite` in Electron's user-data directory. Only the main process opens it. Sales, item rows, and payments commit atomically with WAL and `synchronous=FULL`. A UUID identifies each immutable sale; retries cannot overwrite a sale or reset its sync status. Desktop checkout shows a completed receipt only after a successful local commit.

Queued sales and cached catalog records are isolated by store and terminal UUID. The sync worker pushes up to 50 sales, persists only acknowledged UUIDs, and applies product/category/customer updates together with the checkpoint. Failed or unacknowledged sales remain queued. Receipt tax rates are captured at checkout so a later catalog edit does not change the accepted payment.

On the first scoped storage access, an existing `smartshop_offline_sales.json` is imported atomically once. Legacy records without store/device fields are assigned to that terminal's configured scope; configure the original store/device before first use. The JSON file is never deleted or rewritten. Invalid records or conflicting identities stop the import with an error so the original data can be recovered.

An existing authenticated session and cached user profile can survive a network outage and restart. New sign-in requires connectivity; a confirmed 401/403 clears the session. Logout clears the cached profile and token, while preserving the sales queue.

Close the app before making a filesystem backup of the database. If copying a live database, use a SQLite-aware backup process; copying only the `.sqlite` file can omit committed data in its WAL. Never delete local storage to resolve a sync error while sales are pending.

## Verification and packaging

```sh
npm run lint
npm run build:all
npm test
npm run test:smoke
```

`npm test` runs 13 recovery and sync tests under Electron's Node runtime, matching the native module ABI. `test:smoke` runs the built cashier UI with a real preload bridge and SQLite against an isolated mock API; it checks offline checkout, reload recovery, and reconnect synchronization. It needs a graphical session (use `xvfb-run -a npm run test:smoke` on Linux CI).

Use `npm run dist:win` on a Windows build machine for the installer, or `npm run dist:mac` for macOS. Output goes to `release/<version>/`. Native SQLite is unpacked from ASAR and rebuilt for the target architecture. macOS arm64 packaging is verified; Windows execution and physical printer/drawer/scale testing remain target-device checks.
