import { Router } from "express";
import { rateLimit } from "express-rate-limit";
import { getByKey, activateLicense, setLicenseActive, expireLicense, getHwidsForKey, addHwidToKey } from "../bot/database.js";
import { getDurationMs } from "../bot/utils.js";
import {
  logKeyActivated,
  logKeyExpired,
  logHwidMismatch,
} from "../lib/discordLogger.js";

const router = Router();

const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { status: "error", message: "Too many requests. Try again later." },
});

async function verifyLicense(
  licenseKey: string,
  hwid: string
): Promise<
  | { ok: true; code: string; expires_at: number | null; duration_type: string }
  | { ok: false; status: number; message: string; code: string }
> {
  const key = licenseKey.trim().toUpperCase();
  const license = await getByKey(key);

  if (!license) {
    return { ok: false, status: 404, message: "Key tidak ditemukan.", code: "NOT_FOUND" };
  }

  if (license.status === "REVOKED") {
    return { ok: false, status: 403, message: "Key telah dicabut oleh admin.", code: "REVOKED" };
  }

  const now = Date.now();

  if (license.expires_at !== null && now > license.expires_at) {
    await expireLicense(key);
    await logKeyExpired(key);
    return { ok: false, status: 401, message: "Key sudah kadaluarsa.", code: "EXPIRED" };
  }

  if (license.status === "EXPIRED") {
    return { ok: false, status: 401, message: "Key sudah kadaluarsa.", code: "EXPIRED" };
  }

  if (license.status === "UNUSED") {
    const durationMs =
      license.duration_type === "PERMANENT"
        ? null
        : getDurationMs(license.duration_type, license.duration_value);
    const expiresAt = durationMs !== null ? now + durationMs : null;

    if (license.max_hwid_count > 1) {
      await setLicenseActive(key, expiresAt);
      await addHwidToKey(key, hwid);
    } else {
      await activateLicense(hwid, expiresAt, key);
    }
    await logKeyActivated(key, hwid);

    return {
      ok: true,
      code: "ACTIVATED",
      expires_at: expiresAt,
      duration_type: license.duration_type,
    };
  }

  if (license.status === "ACTIVE") {
    if (license.max_hwid_count > 1) {
      const hwids = await getHwidsForKey(key);
      if (hwids.some((h) => h.hwid_hash === hwid)) {
        return {
          ok: true,
          code: "AUTHORIZED",
          expires_at: license.expires_at,
          duration_type: license.duration_type,
        };
      }
      if (hwids.length < license.max_hwid_count) {
        await addHwidToKey(key, hwid);
        await logKeyActivated(key, hwid);
        return {
          ok: true,
          code: "ACTIVATED",
          expires_at: license.expires_at,
          duration_type: license.duration_type,
        };
      }
      await logHwidMismatch(key);
      return {
        ok: false,
        status: 403,
        message: `Batas perangkat tercapai. Key ini hanya boleh dipakai di ${license.max_hwid_count} perangkat.`,
        code: "HWID_MISMATCH",
      };
    }

    // Single device mode — fix: allow rebind if HWID was reset (hwid_hash is NULL)
    if (license.hwid_hash === null) {
      await activateLicense(hwid, license.expires_at, key);
      await logKeyActivated(key, hwid);
      return {
        ok: true,
        code: "ACTIVATED",
        expires_at: license.expires_at,
        duration_type: license.duration_type,
      };
    }

    if (license.hwid_hash !== hwid) {
      await logHwidMismatch(key);
      return {
        ok: false,
        status: 403,
        message: "HWID tidak cocok. Key terikat ke perangkat lain.",
        code: "HWID_MISMATCH",
      };
    }
    return {
      ok: true,
      code: "AUTHORIZED",
      expires_at: license.expires_at,
      duration_type: license.duration_type,
    };
  }

  return { ok: false, status: 500, message: "Status tidak diketahui.", code: "INTERNAL_ERROR" };
}

// ─────────────────────────────────────────────────────────────
// GET /api/license/check?key=KEY&hwid=HWID
// ─────────────────────────────────────────────────────────────
router.get("/check", limiter, async (req, res) => {
  const key = req.query["key"] as string | undefined;
  const hwid = (req.query["hwid"] as string | undefined) ?? "UNKNOWN";

  if (!key) {
    res.status(400).json({ status: "error", message: "Parameter 'key' wajib diisi." });
    return;
  }

  const result = await verifyLicense(key, hwid);

  if (!result.ok) {
    res.status(result.status).json({ status: "error", message: result.message, code: result.code });
    return;
  }

  res.status(200).json({
    status: "success",
    message: "Akses diberikan.",
    code: result.code,
    duration_type: result.duration_type,
    expires_at: result.expires_at,
  });
});

// ─────────────────────────────────────────────────────────────
// POST /api/license/activate
// ─────────────────────────────────────────────────────────────
router.post("/activate", limiter, async (req, res) => {
  const { license_key, hwid } = req.body as {
    license_key?: string;
    hwid?: string;
  };

  if (!license_key || typeof license_key !== "string") {
    res.status(400).json({ error: "Missing license_key", code: "INVALID_REQUEST" });
    return;
  }
  if (!hwid || typeof hwid !== "string") {
    res.status(400).json({ error: "Missing hwid", code: "INVALID_REQUEST" });
    return;
  }

  const result = await verifyLicense(license_key, hwid);

  if (!result.ok) {
    res.status(result.status).json({ error: result.message, code: result.code });
    return;
  }

  res.status(200).json({
    success: true,
    code: result.code,
    license_key: license_key.trim().toUpperCase(),
    duration_type: result.duration_type,
    expires_at: result.expires_at,
  });
});

export default router;
