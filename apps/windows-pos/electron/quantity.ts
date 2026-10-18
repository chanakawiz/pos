export function roundQuantity(value: number): number {
  return Math.round((value + Number.EPSILON) * 1000) / 1000;
}

export function isValidQuantity(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0.001 && value <= 9999999999.999 &&
    Math.abs(value - roundQuantity(value)) < 1e-9;
}

export function weightUnit(unit: string): 'kg' | 'g' | null {
  const normalized = unit.trim().toLowerCase();
  return normalized === 'kg' || normalized === 'g' ? normalized : null;
}

export function quantityFromWeight(value: number, from: 'kg' | 'g', to: 'kg' | 'g'): number {
  const converted = from === to ? value : from === 'g' ? value / 1000 : value * 1000;
  if (!isValidQuantity(converted)) throw new Error('Weight must be positive and representable to three decimal places in the product unit.');
  return roundQuantity(converted);
}
