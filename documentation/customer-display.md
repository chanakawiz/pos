# Customer-facing secondary monitor

HRD-004 now has a desktop implementation for an HDMI/VGA/DisplayPort monitor. This is a graphical Electron window; serial VFD/pole-display protocols are outside this implementation. A physical Windows dual-monitor deployment still needs the checks below.

## Enable and operate

1. Connect the customer monitor and choose **Extend** in the operating system's display settings. Mirroring cannot show independent cashier and customer views.
2. Keep the cashier window entirely on its own monitor. The app automatically opens a borderless, non-focusable customer window on an available monitor with no cashier-window overlap. With several eligible monitors, it retains the current one; otherwise it chooses the lowest Electron display ID.
3. Press **F1 → Customer display** to view status, **Pause display**, or **Enable display**. The preference persists across restarts in `customer-display.json` under Electron's user-data directory:

   ```json
   { "enabled": true }
   ```

   The default is enabled when the file is absent. An unreadable or invalid preference disables the display and logs an error; enabling it from F1 rewrites a valid preference when the directory is writable.
4. The screen follows cart quantities, item removal, tax, bill discounts, held/restored bills, and the cashier's English/Sinhala/bilingual language setting. Subtotal is after line discounts, line amounts include tax, and bill discount is shown separately. Names fall back to English when no Sinhala name exists. The bundled Sinhala font works offline.
5. Clearing, holding, or completing a cart returns the display to a welcome screen. Signing out removes both the cart and store identity from the display. Payment tender, card references, customer identity, cashier identity, serial/IMEI values, and cost prices are not included. Payment/change confirmation is available on the cashier receipt.

No second monitor produces a waiting status and leaves the cashier usable. Unplugging the monitor closes the customer window. Reconnecting sends the latest cart snapshot. Changes to display bounds, rotation, and scale trigger placement reconciliation. Moving/resizing the cashier window also rechecks eligibility; spanning all available monitors closes the display until a separate monitor is available. Closing the cashier closes the display. Reloading or losing the cashier renderer clears its public snapshot. A customer renderer load/crash error is visible in F1; pause then enable to retry.

The display fills the selected monitor's bounds without entering an OS fullscreen workspace or taking keyboard focus. It does not control the desktop behind that window. Configure a dedicated customer monitor for deployment. Browser preview has no native secondary-window support.

## Isolation

The customer page is a separate Vite entry point with no authentication, API, sync, or cashier-store imports. Its sandboxed, context-isolated preload exposes one read-only state subscription. It uses a separate, nonpersistent Electron session, and permissions, popups, webviews, and page navigation are denied. Its content security policy blocks API connections and external assets. Only the current customer's main frame can request its initial snapshot.

Cashier storage, hardware, device, and display-write IPC validate the exact cashier window, main frame, and document URL. Main-process validation rebuilds the public projection and discards unknown fields before forwarding it. No public snapshots are written to disk. Product text is escaped by React.

Placement follows Electron's device-independent bounds and monitor-change events. References: [screen API](https://www.electronjs.org/docs/latest/api/screen), [BrowserWindow API](https://www.electronjs.org/docs/latest/api/browser-window), [Electron security guidance](https://www.electronjs.org/docs/latest/tutorial/security).

## Verification

From `apps/windows-pos`, with Node.js 24:

```sh
npm test
npm run test:smoke
npm run lint
```

Native tests cover monitor exclusion (including negative coordinates, mirroring, and spanning windows), public-state validation/privacy, and IPC document/frame restrictions. The existing cashier GUI smoke suite now also creates a real sandboxed customer renderer in a hidden offscreen window using simulated monitor events. It checks live quantities, discounts, clear/hold/restore, three languages, isolated local storage/no cashier bridge, disconnect/reconnect, persisted pause/resume, failed-write cart retention, successful-checkout clearing, logout, and cashier shutdown. It does not take over a physical monitor.

Optional screenshots of synthetic data can be retained with:

```sh
SMARTSHOP_DISPLAY_ARTIFACTS=/tmp/smartshop-display-qa npm run test:smoke
```

## Target-device acceptance checklist

- [ ] Run the Windows build with extended HDMI/VGA/DisplayPort monitors and the actual lane resolution/DPI.
- [ ] Confirm the customer screen fills only the intended monitor, including a monitor left of/above the cashier and a rotated monitor.
- [ ] Confirm barcode scanning and keyboard focus stay with the cashier as the display opens, reconnects, and updates.
- [ ] Exercise discounts, tax, long carts, Sinhala names, payment completion, sign-out, and pause/resume during an outage.
- [ ] Unplug/reconnect, change resolution/scaling, move/span the cashier window, and restart after pausing. Verify the cashier remains usable and no previous cart is left visible.

Physical monitor/DPI behavior and Windows execution remain unverified in the macOS development environment.
