import type { BrowserWindow, IpcMainEvent, IpcMainInvokeEvent } from 'electron';

export function isTrustedFrame(event: IpcMainEvent | IpcMainInvokeEvent, window: BrowserWindow | null, expectedUrl: string): boolean {
  if (!window || window.isDestroyed() || event.sender !== window.webContents || event.senderFrame !== window.webContents.mainFrame) return false;
  try {
    const actual = new URL(event.senderFrame.url);
    const expected = new URL(expectedUrl);
    actual.hash = ''; expected.hash = '';
    return actual.href === expected.href;
  } catch { return false; }
}
