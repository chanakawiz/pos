import { drawerPulse } from './escpos';
import { PrinterConfigurationError } from './printer-config';
import { PrinterDeliveryError, sendPrinterJob } from './printer-transport';
import { ReceiptValidationError, validatePrintRequest } from './receipt-document';
import type { HardwareResult, PrinterProfile, PrintRequest } from './printer-types';

/** One queue for both receipt jobs and drawer pulses; failures never trigger an automatic retry. */
export class PrinterService {
  private tail: Promise<void> = Promise.resolve();
  private queued = 0;
  private deliveryGeneration = 0;

  constructor(
    private readonly profile: () => PrinterProfile,
    private readonly render: (request: PrintRequest, profile: PrinterProfile) => Promise<Buffer>,
    private readonly send: (profile: PrinterProfile, data: Buffer) => Promise<void> = sendPrinterJob,
  ) {}

  private enqueue(operation: () => Promise<HardwareResult>): Promise<HardwareResult> {
    if (this.queued >= 10) return Promise.resolve({ success: false, message: 'The printer is busy. Wait for the current jobs to finish before retrying.' });
    this.queued++;
    const generation = this.deliveryGeneration;
    const task = this.tail.then((): Promise<HardwareResult> | HardwareResult => generation === this.deliveryGeneration ? operation() :
      { success: false, message: 'An earlier printer job was interrupted. Check the printer before submitting this job again.' })
    .catch((error: unknown): HardwareResult => {
      if (error instanceof PrinterConfigurationError || error instanceof ReceiptValidationError) return { success: false, message: error.message };
      if (error instanceof PrinterDeliveryError) {
        if (error.uncertain) this.deliveryGeneration++;
        return { success: false, message: error.message +
          (error.uncertain ? ' Part of the job may have been delivered. Check the printer before retrying.' : ''), uncertain: error.uncertain };
      }
      // Native render errors may contain an entire receipt URL; never log customer receipt data.
      console.error('Receipt rendering failed:', error instanceof Error ? error.name : 'Unknown error');
      return { success: false, message: 'The receipt could not be prepared. Reopen the receipt and try again.' };
    }).finally(() => { this.queued--; });
    this.tail = task.then(() => undefined);
    return task;
  }

  printReceipt(input: unknown): Promise<HardwareResult> {
    let request: PrintRequest;
    try { request = validatePrintRequest(input); }
    catch (error) { return Promise.resolve({ success: false, message: error instanceof Error ? error.message : 'Invalid receipt' }); }
    return this.enqueue(async () => {
      const profile = this.profile();
      const bytes = await this.render(request, profile);
      await this.send(profile, bytes);
      return { success: true, message: profile.transport.type === 'windows' ? 'Receipt submitted to the Windows print queue.' : 'Receipt sent to the printer.', bytes: bytes.length };
    });
  }

  openCashDrawer(): Promise<HardwareResult> {
    return this.enqueue(async () => {
      const profile = this.profile();
      if (!profile.drawerEnabled) return { success: false, skipped: true, message: 'The cash drawer is disabled in this terminal’s printer configuration.' };
      const bytes = drawerPulse(profile.drawerPin);
      await this.send(profile, bytes);
      return { success: true, message: 'Drawer pulse sent to the printer.', bytes: bytes.length };
    });
  }
}
