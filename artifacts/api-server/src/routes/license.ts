import { Router } from "express";
import { rateLimit } from "express-rate-limit";
import { getByKey, activateLicense, expireLicense } from "../bot/database.js";
import { getDurationMs } from "../bot/utils.js";

const router = Router();

const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { status: "error", message: "Too many requests. Try again later." },
});

// ─────────────────────────────────────────────────────────────
// Core verification logic (shared by both endpoints)
// ─────────────────────────────────────────────────────────────
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

    await activateLicense(hwid, expiresAt, key);

    return {
      ok: true,
      code: "ACTIVATED",
      expires_at: expiresAt,
      duration_type: license.duration_type,
    };
  }

  if (license.status === "ACTIVE") {
    if (license.hwid_hash !== hwid) {
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
