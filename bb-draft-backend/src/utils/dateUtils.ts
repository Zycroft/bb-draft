/**
 * Date utilities for version numbering
 * All dates are calculated in PST (Pacific Standard Time) / PDT (Pacific Daylight Time)
 */

const PST_OFFSET_HOURS = -8; // PST is UTC-8
const PDT_OFFSET_HOURS = -7; // PDT is UTC-7

/**
 * Check if a given date is in Pacific Daylight Time (PDT)
 * PDT is observed from the second Sunday in March to the first Sunday in November
 */
function isPDT(date: Date): boolean {
  const year = date.getUTCFullYear();

  // Second Sunday in March
  const marchFirst = new Date(Date.UTC(year, 2, 1));
  const marchFirstDay = marchFirst.getUTCDay();
  const secondSundayMarch = 8 + (7 - marchFirstDay) % 7;
  const pdtStart = new Date(Date.UTC(year, 2, secondSundayMarch, 10, 0, 0)); // 2am PST = 10am UTC

  // First Sunday in November
  const novFirst = new Date(Date.UTC(year, 10, 1));
  const novFirstDay = novFirst.getUTCDay();
  const firstSundayNov = 1 + (7 - novFirstDay) % 7;
  const pdtEnd = new Date(Date.UTC(year, 10, firstSundayNov, 9, 0, 0)); // 2am PDT = 9am UTC

  return date >= pdtStart && date < pdtEnd;
}

/**
 * Get the current Pacific Time offset in hours
 */
function getPacificOffset(date: Date): number {
  return isPDT(date) ? PDT_OFFSET_HOURS : PST_OFFSET_HOURS;
}

/**
 * Get the current date in PST/PDT timezone as yyyymmdd string
 */
export function getPSTDate(date: Date = new Date()): string {
  const offset = getPacificOffset(date);
  const pstTime = new Date(date.getTime() + offset * 60 * 60 * 1000);

  const year = pstTime.getUTCFullYear();
  const month = String(pstTime.getUTCMonth() + 1).padStart(2, '0');
  const day = String(pstTime.getUTCDate()).padStart(2, '0');

  return `${year}${month}${day}`;
}

/**
 * Format a version string from components
 * @param majorMinorPatch - The X.X.X portion (e.g., "0.0.0", "1.2.3")
 * @param date - The date portion in yyyymmdd format
 * @param counter - The daily counter (1-9999)
 * @returns Formatted version string (e.g., "0.0.0-20260109-0001")
 */
export function formatVersion(majorMinorPatch: string, date: string, counter: number): string {
  const paddedCounter = String(counter).padStart(4, '0');
  return `${majorMinorPatch}-${date}-${paddedCounter}`;
}

/**
 * Parse a version string into its components
 * @param version - Full version string (e.g., "0.0.0-20260109-0001")
 * @returns Object with majorMinorPatch, date, and counter
 */
export function parseVersion(version: string): { majorMinorPatch: string; date: string; counter: number } | null {
  const match = version.match(/^(\d+\.\d+\.\d+)-(\d{8})-(\d{4})$/);
  if (!match) return null;

  return {
    majorMinorPatch: match[1],
    date: match[2],
    counter: parseInt(match[3], 10),
  };
}
