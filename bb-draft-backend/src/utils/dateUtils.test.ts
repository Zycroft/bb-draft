import { getPSTDate, formatVersion, parseVersion } from './dateUtils';

describe('dateUtils', () => {
  describe('getPSTDate', () => {
    it('should return correct PST date at midnight UTC (still previous day in PST)', () => {
      // Midnight UTC on Jan 10 = 4pm PST on Jan 9 (PST is UTC-8)
      const date = new Date('2026-01-10T00:00:00Z');
      expect(getPSTDate(date)).toBe('20260109');
    });

    it('should return correct PST date at noon UTC (same day in PST)', () => {
      // Noon UTC on Jan 10 = 4am PST on Jan 10
      const date = new Date('2026-01-10T12:00:00Z');
      expect(getPSTDate(date)).toBe('20260110');
    });

    it('should return correct PST date at 8am UTC (midnight PST, same day)', () => {
      // 8am UTC = midnight PST (new day in PST)
      const date = new Date('2026-01-10T08:00:00Z');
      expect(getPSTDate(date)).toBe('20260110');
    });

    it('should return correct PST date at 7:59am UTC (still previous day in PST)', () => {
      // 7:59am UTC = 11:59pm PST (still previous day)
      const date = new Date('2026-01-10T07:59:00Z');
      expect(getPSTDate(date)).toBe('20260109');
    });

    it('should handle PDT during summer (UTC-7)', () => {
      // July 15 at 10am UTC = 3am PDT on July 15 (PDT is UTC-7)
      const date = new Date('2026-07-15T10:00:00Z');
      expect(getPSTDate(date)).toBe('20260715');
    });

    it('should handle PDT at midnight boundary', () => {
      // July 15 at 7am UTC = midnight PDT (new day)
      const date = new Date('2026-07-15T07:00:00Z');
      expect(getPSTDate(date)).toBe('20260715');
    });

    it('should handle PDT just before midnight', () => {
      // July 15 at 6:59am UTC = 11:59pm PDT on July 14
      const date = new Date('2026-07-15T06:59:00Z');
      expect(getPSTDate(date)).toBe('20260714');
    });

    it('should pad single-digit months and days', () => {
      const date = new Date('2026-01-05T12:00:00Z');
      expect(getPSTDate(date)).toBe('20260105');
    });

    it('should handle year boundaries', () => {
      // Dec 31 at 8pm UTC = noon PST on Dec 31
      const date = new Date('2025-12-31T20:00:00Z');
      expect(getPSTDate(date)).toBe('20251231');
    });

    it('should handle new year in PST', () => {
      // Jan 1 at 10am UTC = 2am PST on Jan 1
      const date = new Date('2026-01-01T10:00:00Z');
      expect(getPSTDate(date)).toBe('20260101');
    });
  });

  describe('formatVersion', () => {
    it('should format version with padded counter', () => {
      expect(formatVersion('0.0.0', '20260109', 42)).toBe('0.0.0-20260109-0042');
    });

    it('should handle counter of 1', () => {
      expect(formatVersion('1.2.3', '20260109', 1)).toBe('1.2.3-20260109-0001');
    });

    it('should handle counter of 9999', () => {
      expect(formatVersion('0.0.0', '20260109', 9999)).toBe('0.0.0-20260109-9999');
    });

    it('should handle counter of 10000 (exceeds padding)', () => {
      expect(formatVersion('0.0.0', '20260109', 10000)).toBe('0.0.0-20260109-10000');
    });

    it('should preserve major.minor.patch format', () => {
      expect(formatVersion('2.5.10', '20261231', 123)).toBe('2.5.10-20261231-0123');
    });
  });

  describe('parseVersion', () => {
    it('should parse a valid version string', () => {
      const result = parseVersion('0.0.0-20260109-0042');
      expect(result).toEqual({
        majorMinorPatch: '0.0.0',
        date: '20260109',
        counter: 42,
      });
    });

    it('should parse version with larger numbers', () => {
      const result = parseVersion('12.34.56-20261231-9999');
      expect(result).toEqual({
        majorMinorPatch: '12.34.56',
        date: '20261231',
        counter: 9999,
      });
    });

    it('should return null for invalid format', () => {
      expect(parseVersion('invalid')).toBeNull();
      expect(parseVersion('0.0.0')).toBeNull();
      expect(parseVersion('0.0.0-20260109')).toBeNull();
      expect(parseVersion('0.0.0-2026010-0001')).toBeNull();
      expect(parseVersion('0.0.0-20260109-001')).toBeNull();
    });

    it('should handle leading zeros in counter', () => {
      const result = parseVersion('0.0.0-20260109-0001');
      expect(result?.counter).toBe(1);
    });
  });
});
