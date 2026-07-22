import { randomBytes } from "crypto";

const CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export function generateLicenseKey(): string {
  const segments: string[] = [];
  for (let s = 0; s < 4; s++) {
    let seg = "";
    const bytes = randomBytes(4);
    for (let i = 0; i < 4; i++) {
      seg += CHARS[bytes[i]! % CHARS.length];
    }
    segments.push(seg);
  }
  return segments.join("-");
}

export function getDurationMs(type: string, value: number): number {
  switch (type) {
    case "HOURLY":
      return value * 60 * 60 * 1000;
    case "DAILY":
      return value * 24 * 60 * 60 * 1000;
    case "WEEKLY":
      return value * 7 * 24 * 60 * 60 * 1000;
    default:
      return 0;
  }
}

export function censorKey(key: string): string {
  const parts = key.split("-");
  if (parts.length === 4) {
    return `${parts[0]}-****-****-${parts[3]}`;
  }
  return key.substring(0, 4) + "....." + key.substring(key.length - 4);
}

export function statusColor(status: string): number {
  switch (status) {
    case "ACTIVE":
      return 0x00c853;
    case "UNUSED":
      return 0x2196f3;
    case "EXPIRED":
      return 0xff6d00;
    case "REVOKED":
      return 0xd50000;
    default:
      return 0x616161;
  }
}

export function statusEmoji(status: string): string {
  switch (status) {
    case "ACTIVE":
      return "🟢";
    case "UNUSED":
      return "🔵";
    case "EXPIRED":
      return "🟠";
    case "REVOKED":
      return "🔴";
    default:
      return "⚪";
  }
}

export function durationLabel(type: string, value: number): string {
  if (type === "PERMANENT") return "Permanent (Lifetime)";
  return `${value} ${type.charAt(0) + type.slice(1).toLowerCase().replace("ly", "")}${value > 1 ? "s" : ""}`;
}
