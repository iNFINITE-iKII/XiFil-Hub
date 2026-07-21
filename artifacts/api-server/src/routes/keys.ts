import { Router, type IRouter } from "express";
import { db, usersTable } from "@workspace/db";
import { eq } from "drizzle-orm";
import { getUserKeys, getByKey } from "../bot/database.js";

const router: IRouter = Router();

// GET /api/keys/mine - list the current logged-in user's license keys
router.get("/mine", async (req, res): Promise<void> => {
  try {
    const userId = (req.session as any)?.userId;
    if (!userId) {
      res.status(401).json({ error: "Not authenticated" });
      return;
    }

    const [user] = await db.select().from(usersTable).where(eq(usersTable.id, userId));
    if (!user) {
      res.status(401).json({ error: "User not found" });
      return;
    }

    const userKeys = await getUserKeys(user.discordId);

    const keys = await Promise.all(
      userKeys.map(async (uk) => {
        const license = await getByKey(uk.license_key);
        return {
          id: uk.id,
          key: uk.license_key,
          status: license?.status ?? "UNKNOWN",
          expiresAt: license?.expires_at ?? null,
          durationType: license?.duration_type ?? null,
          assignedAt: uk.assigned_at,
        };
      })
    );

    res.json(keys);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch keys" });
  }
});

export default router;
