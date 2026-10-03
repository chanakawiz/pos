import { useEffect, useRef } from 'react';
import { posSounds } from '../utils/audio';

interface Options {
  onScan: (barcode: string) => void;
  minChars?: number;
  maxKeyInterval?: number; // ms
  enabled?: boolean;
}

/**
 * Universal Hardware Barcode Scanner Wedge Hook
 * Intercepts rapid keystroke bursts sent by USB and Bluetooth barcode scanners
 * Works globally without requiring the search input to have focus.
 */
export const useBarcodeScanner = ({
  onScan,
  minChars = 3,
  maxKeyInterval = 60,
  enabled = true,
}: Options) => {
  const bufferRef = useRef<string>('');
  const lastKeyTimeRef = useRef<number>(0);

  useEffect(() => {
    if (!enabled) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      // Ignore functional modifier keys
      if (e.ctrlKey || e.altKey || e.metaKey) {
        return;
      }

      const now = performance.now();
      const interval = now - lastKeyTimeRef.current;
      lastKeyTimeRef.current = now;

      // Enter key indicates end of barcode transmission from scanner
      if (e.key === 'Enter') {
        const barcode = bufferRef.current.trim();
        bufferRef.current = '';

        if (barcode.length >= minChars) {
          e.preventDefault();
          e.stopPropagation();
          posSounds.playScannerBeep();
          onScan(barcode);
        }
        return;
      }

      // Check if character is a printable single character
      if (e.key.length === 1) {
        // If the gap between previous keystroke and this one is too long, reset buffer
        if (interval > maxKeyInterval && bufferRef.current.length > 0) {
          bufferRef.current = '';
        }

        bufferRef.current += e.key;

        // Auto-clear buffer after 300ms of inactivity to prevent accidental stale accumulation
        setTimeout(() => {
          if (performance.now() - lastKeyTimeRef.current > 300) {
            bufferRef.current = '';
          }
        }, 350);
      }
    };

    window.addEventListener('keydown', handleKeyDown, true);
    return () => {
      window.removeEventListener('keydown', handleKeyDown, true);
    };
  }, [enabled, minChars, maxKeyInterval, onScan]);
};
