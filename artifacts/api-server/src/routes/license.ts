import { Router } from "express";
import { rateLimit } from "express-rate-limit";
import { stmtGetByKey, stmtActivate, stmtExpire } from "../bot/database.js";
import { getDurationMs } from "../bot/utils.js";

const router = Router();

const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: "Too many requests",
    code: "RATE_LIMITED",
  },
});

router.post("/activate", limiter, (req, res) => {
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

  const key = license_key.trim().toUpperCase();
  const license = stmtGetByKey.get(key);

  if (!license) {
    res.status(404).json({ error: "License key not found", code: "NOT_FOUND" });
    return;
  }

  if (license.status === "REVOKED") {
    res.status(403).json({ error: "License key has been revoked", code: "REVOKED" });
    return;
  }

  const now = Date.now();

  if (license.expires_at !== null && now > license.expires_at) {
    stmtExpire.run(key);
    res.status(401).json({ error: "License key has expired", code: "EXPIRED" });
    return;
  }

  if (license.status === "EXPIRED") {
    res.status(401).json({ error: "License key has expired", code: "EXPIRED" });
    return;
  }

  if (license.status === "UNUSED") {
    const durationMs =
      license.duration_type === "PERMANENT"
        ? null
        : getDurationMs(license.duration_type, license.duration_value);
    const expiresAt = durationMs !== null ? now + durationMs : null;

    stmtActivate.run(hwid, expiresAt as number, key);

    res.status(200).json({
      success: true,
      code: "ACTIVATED",
      license_key: key,
      duration_type: license.duration_type,
      expires_at: expiresAt,
      hwid_bound: hwid,
    });
    return;
  }

  if (license.status === "ACTIVE") {
    if (license.hwid_hash !== hwid) {
      res.status(403).json({
        error: "HWID mismatch — this license is bound to a different device",
        code: "HWID_MISMATCH",
      });
      return;
    }

    res.status(200).json({
      success: true,
      code: "AUTHORIZED",
      license_key: key,
      duration_type: license.duration_type,
      expires_at: license.expires_at,
      hwid_bound: license.hwid_hash,
    });
    return;
  }

  res.status(500).json({ error: "Unexpected license state", code: "INTERNAL_ERROR" });
});

export default router;
