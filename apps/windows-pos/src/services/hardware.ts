import type { HardwareResult } from '../../electron/printer-types';
import { usePosStore } from '../stores/usePosStore';

let drawerRequest: Promise<HardwareResult> | null = null;

export function openCashDrawer(saleSaved = false): Promise<HardwareResult> {
  if (drawerRequest) return drawerRequest;
  drawerRequest = (async () => {
    let result: HardwareResult;
    try {
      result = window.posApi ? await window.posApi.openCashDrawer() :
        { success: false, message: 'Cash drawer control requires the desktop app.' };
    } catch {
      result = { success: false, message: 'The drawer request was not confirmed. Check the printer and drawer before retrying.', uncertain: true };
    }
    usePosStore.getState().setHardwareMessage(result.success || (result.skipped && saleSaved) ? null :
      `${saleSaved ? 'Payment saved. ' : ''}${result.message}`);
    return result;
  })().finally(() => { drawerRequest = null; });
  return drawerRequest;
}
