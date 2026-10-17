import type { PrintRequest, PrinterProfile, ReceiptSale, ShiftPrintReport } from './printer-types';

export class ReceiptValidationError extends Error {}
const invalid = (): never => { throw new ReceiptValidationError('The receipt data is incomplete or invalid. Reopen the receipt and try again.'); };
const object = (value: unknown): Record<string, unknown> => value && typeof value === 'object' && !Array.isArray(value) ? value as Record<string, unknown> : invalid();
const text = (value: unknown, max = 2000): string => typeof value === 'string' && value.length <= max ? value : invalid();
const optionalText = (value: unknown): string | undefined => value === undefined || value === null ? undefined : text(value);
const money = (value: unknown, signed = false): number => {
  if ((typeof value !== 'number' && typeof value !== 'string') || (typeof value === 'string' && !value.trim())) return invalid();
  const number = Number(value);
  return Number.isFinite(number) && Math.abs(number) < 1e12 && (signed || number >= 0) ? number : invalid();
};

export function validatePrintRequest(value: unknown): PrintRequest {
  const request = object(value);
  if (request.kind === 'sale') {
    const sale = object(request.sale);
    if (!['en', 'si', 'bilingual'].includes(String(request.language)) ||
        !Array.isArray(sale.items) || sale.items.length === 0 || sale.items.length > 500) return invalid();
    const metadata = sale.receipt === undefined ? {} : object(sale.receipt);
    const date = text(sale.sold_at);
    if (!Number.isFinite(Date.parse(date))) return invalid();
    const result: ReceiptSale = {
      invoice_number: text(sale.invoice_number), sold_at: date,
      subtotal: money(sale.subtotal), tax_amount: money(sale.tax_amount), discount_amount: money(sale.discount_amount),
      total_amount: money(sale.total_amount), paid_amount: money(sale.paid_amount), change_amount: money(sale.change_amount),
      paymentMethod: optionalText(sale.paymentMethod),
      items: sale.items.map((value) => {
        const item = object(value);
        const quantity = money(item.quantity);
        if (quantity <= 0) return invalid();
        return { product_name: text(item.product_name), sinhala_name: optionalText(item.sinhala_name), quantity,
          total: money(item.total), serial_number: optionalText(item.serial_number), warranty_notes: optionalText(item.warranty_notes) };
      }),
      receipt: {
        store_name: optionalText(metadata.store_name), store_address: optionalText(metadata.store_address),
        store_phone: optionalText(metadata.store_phone), cashier_name: optionalText(metadata.cashier_name),
        currency_symbol: optionalText(metadata.currency_symbol), tax_number: optionalText(metadata.tax_number),
        receipt_header: optionalText(metadata.receipt_header), receipt_footer: optionalText(metadata.receipt_footer),
      },
    };
    return { kind: 'sale', sale: result, language: request.language as 'en' | 'si' | 'bilingual', storeNameSi: optionalText(request.storeNameSi) };
  }
  if (request.kind === 'shift' && ['X', 'Z'].includes(String(request.reportType))) {
    const report = object(request.report);
    const result: ShiftPrintReport = {
      session_uuid: text(report.session_uuid), store_name: text(report.store_name), cashier_name: text(report.cashier_name),
      opened_at: text(report.opened_at), closed_at: optionalText(report.closed_at), report_generated_at: optionalText(report.report_generated_at),
      opening_float: money(report.opening_float), cash_sales: money(report.cash_sales), card_sales: money(report.card_sales),
      gross_sales: money(report.gross_sales), discount_total: money(report.discount_total), refund_total: money(report.refund_total),
      transactions_count: money(report.transactions_count),
      expected_cash_in_drawer: report.expected_cash_in_drawer === undefined ? undefined : money(report.expected_cash_in_drawer, true),
      expected_cash: report.expected_cash === undefined ? undefined : money(report.expected_cash, true),
      actual_closing_cash: report.actual_closing_cash === undefined ? undefined : money(report.actual_closing_cash),
      discrepancy: report.discrepancy === undefined ? undefined : money(report.discrepancy, true), notes: optionalText(report.notes),
    };
    if (result.expected_cash_in_drawer === undefined && result.expected_cash === undefined) return invalid();
    return { kind: 'shift', report: result, reportType: request.reportType as 'X' | 'Z' };
  }
  if (request.kind === 'refund') {
    const receipt = object(request.receipt);
    return { kind: 'refund', receipt: {
      refund_number: text(receipt.refund_number), invoice_number: text(receipt.invoice_number),
      store_name: text(receipt.store_name), cashier_name: text(receipt.cashier_name),
      total_refunded: money(receipt.total_refunded), reason: text(receipt.reason), refunded_at: text(receipt.refunded_at),
    } };
  }
  return invalid();
}

export const escapeHtml = (value: string): string => value.replace(/[&<>"']/g, (character) =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character]!);

const printableDate = (value: string): string => {
  const date = new Date(value);
  return Number.isFinite(date.getTime()) ? date.toLocaleString('en-GB', {
    year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false,
  }) : value;
};

/** All business strings are escaped; the document contains no renderer UI or executable markup. */
export function buildReceiptHtml(request: PrintRequest, profile: PrinterProfile, fontBase64: string): string {
  const esc = escapeHtml;
  const row = (label: string, value: string, total = false) => `<div class="row${total ? ' total' : ''}"><span>${esc(label)}</span><strong>${esc(value)}</strong></div>`;
  let body: string;
  if (request.kind === 'sale') {
    const { sale, language } = request;
    const metadata = sale.receipt;
    const format = (amount: number) => `${metadata?.currency_symbol || '$'}${amount.toFixed(2)}`;
    const label = (en: string, si: string) => language === 'si' ? si : language === 'bilingual' ? `${en} / ${si}` : en;
    const lines = sale.items.map((item) => `<section class="item"><div class="row"><div class="name">${esc(language === 'si' ? item.sinhala_name || item.product_name : item.product_name)}${language === 'bilingual' && item.sinhala_name ? `<div>${esc(item.sinhala_name)}</div>` : ''}</div><strong>${esc(format(item.total))}</strong></div><div>${esc(label('Qty', 'ප්‍රමාණය'))}: ${item.quantity}</div>${item.serial_number ? `<div>SN/IMEI: ${esc(item.serial_number)}</div>` : ''}${item.warranty_notes ? `<div>${esc(item.warranty_notes)}</div>` : ''}</section>`).join('');
    body = `<header>${language !== 'en' && request.storeNameSi ? `<h2>${esc(request.storeNameSi)}</h2>` : ''}<h1>${esc(metadata?.store_name || 'SMARTSHOP POS')}</h1>${[metadata?.store_address, metadata?.store_phone, metadata?.tax_number, metadata?.receipt_header].filter(Boolean).map((value) => `<div>${esc(value!)}</div>`).join('')}</header>
      ${row(label('Invoice', 'බිල්පත් අංකය'), sale.invoice_number)}${row(label('Date', 'දිනය'), printableDate(sale.sold_at))}${row(label('Cashier', 'අයකැමි'), metadata?.cashier_name || '')}
      <main>${lines}</main>${row(label('Subtotal', 'උප එකතුව'), format(sale.subtotal))}${row(label('Tax', 'බදු'), format(sale.tax_amount))}${sale.discount_amount > 0 ? row(label('Discount', 'වට්ටම්'), `-${format(sale.discount_amount)}`) : ''}
      ${row(label('TOTAL', 'මුළු එකතුව'), format(sale.total_amount), true)}${row(label('Paid', 'ගෙවූ මුදල'), format(sale.paid_amount))}${row(label('Change', 'ඉතිරි මුදල'), format(sale.change_amount))}
      <footer>${metadata?.receipt_footer ? `<div>${esc(metadata.receipt_footer)}</div>` : ''}${language !== 'en' ? '<div>ස්තූතියි! නැවත එන්න.</div>' : ''}${language !== 'si' ? '<div>Thank you! Please visit again.</div>' : ''}</footer>`;
  } else if (request.kind === 'shift') {
    const r = request.report;
    const format = (value: number) => value.toFixed(2);
    body = `<header><h1>${esc(r.store_name)}</h1><h2>${request.reportType}-REPORT</h2></header>${row('Session', r.session_uuid)}${row('Cashier', r.cashier_name)}${row('Opened', printableDate(r.opened_at))}${row(request.reportType === 'Z' ? 'Closed' : 'Generated', printableDate(r.closed_at || r.report_generated_at || ''))}
      <main>${row('Transactions', String(r.transactions_count))}${row('Opening float', format(r.opening_float))}${row('Cash sales', format(r.cash_sales))}${row('Card sales', format(r.card_sales))}${row('Gross sales', format(r.gross_sales))}${row('Discounts', format(r.discount_total))}${row('Refunds', format(r.refund_total))}${row('Expected cash', format(r.expected_cash_in_drawer ?? r.expected_cash!), true)}${r.actual_closing_cash !== undefined ? row('Counted cash', format(r.actual_closing_cash)) : ''}${r.discrepancy !== undefined ? row('Variance', format(r.discrepancy)) : ''}</main>${r.notes ? `<footer>${esc(r.notes)}</footer>` : ''}`;
  } else {
    const r = request.receipt;
    body = `<header><h1>${esc(r.store_name)}</h1><h2>REFUND RECEIPT</h2></header>${row('Refund', r.refund_number)}${row('Invoice', r.invoice_number)}${row('Cashier', r.cashier_name)}${row('Date', printableDate(r.refunded_at))}${row('Amount refunded', r.total_refunded.toFixed(2), true)}<footer>${esc(r.reason)}</footer>`;
  }
  return `<!doctype html><html><head><meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; font-src data:"><style>
    @font-face{font-family:ReceiptSinhala;src:url(data:font/ttf;base64,${fontBase64}) format('truetype');font-weight:100 900;font-display:block}
    *{box-sizing:border-box}html{scrollbar-width:none}::-webkit-scrollbar{display:none}html,body{margin:0;background:white;color:black;width:${profile.printableDots}px}
    body{font:22px/1.4 ReceiptSinhala,Arial,sans-serif}#receipt{padding:12px;width:100%;overflow-wrap:anywhere}
    h1,h2{margin:4px 0;font-size:29px;line-height:1.35}h2{font-size:25px}header,footer{text-align:center;white-space:pre-wrap}
    header,main{border-bottom:2px dashed black;padding-bottom:10px;margin-bottom:10px}.row{display:flex;justify-content:space-between;gap:12px;margin:5px 0}.row>span,.name{min-width:0;flex:1}.row>strong{max-width:48%;text-align:right;overflow-wrap:anywhere}.item{padding:7px 0;border-bottom:1px dotted #555}.item:last-child{border:0}.name{font-weight:600}.total{font-size:28px;border-top:2px solid black;padding-top:8px}footer{border-top:2px dashed black;margin-top:12px;padding-top:12px}
  </style></head><body><article id="receipt">${body}</article></body></html>`;
}
