// Sandboxed preload must only require Electron; all other imports are erased types.
import { contextBridge, ipcRenderer } from 'electron';
import type { CustomerDisplayState } from './customer-display-types';

contextBridge.exposeInMainWorld('customerDisplayApi', {
  onState: (callback: (state: CustomerDisplayState) => void) => {
    const handler = (_event: Electron.IpcRendererEvent, state: CustomerDisplayState) => callback(state);
    ipcRenderer.on('customer-display:state', handler);
    ipcRenderer.send('customer-display:ready');
    return () => ipcRenderer.removeListener('customer-display:state', handler);
  },
});
