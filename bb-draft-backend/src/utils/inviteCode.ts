import { customAlphabet } from 'nanoid';

// Generate readable invite codes (no confusing characters)
const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const generateCode = customAlphabet(alphabet, 8);

export function generateInviteCode(): string {
  return generateCode();
}
