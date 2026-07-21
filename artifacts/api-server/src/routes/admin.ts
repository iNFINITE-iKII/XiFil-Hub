import { Router, type IRouter } from "express";
import { db, usersTable, gamesTable } from "@workspace/db";
import { eq } from "drizzle-orm";
import { getLicenseStats } from "../bot/database.js";

const router: IRouter = Router();

async function requireAdmin(req: any, res: any, next: any): Promise<void> {
  try {
    const userId = req.session?.userId;
    if (!userId) {
      res.status(401).json({ error: "Not authenticated" });
      return;
    }

    const [user] = await db.select().from(usersTable).where(eq(usersTable.id, userId));
    if (!user || !user.isAdmin) {
      res.status(403).json({ error: "Admin access required" });
      return;
    }

    next();
  } catch (err) {
    res.status(500).json({ error: "Auth check failed" });
  }
}

router.use(requireAdmin);

// GET /api/admin/stats
router.get("/stats", async (_req, res): Promise<void> => {
  try {
    const stats = await getLicenseStats();
    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch stats" });
  }
});

// GET /api/admin/games
router.get("/games", async (_req, res): Promise<void> => {
  try {
    const games = await db.select().from(gamesTable);
    res.json(games);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch games" });
  }
});

// POST /api/admin/games
router.post("/games", async (req, res): Promise<void> => {
  try {
    const { slug, name, description, status } = req.body as {
      slug?: string;
      name?: string;
      description?: string;
      status?: string;
    };

    if (!slug || !name) {
      res.status(400).json({ error: "slug and name are required" });
      return;
    }

    const [game] = await db
      .insert(gamesTable)
      .values({ slug, name, description: description ?? null, status: status ?? "active" })
      .returning();

    res.status(201).json(game);
  } catch (err: any) {
    if (err?.code === "23505") {
      res.status(409).json({ error: "A game with this slug already exists" });
    } else {
      res.status(500).json({ error: "Failed to create game" });
    }
  }
});

// PATCH /api/admin/games/:id
router.patch("/games/:id", async (req, res): Promise<void> => {
  try {
    const id = Number(req.params.id);
    if (Number.isNaN(id)) {
      res.status(400).json({ error: "Invalid game id" });
      return;
    }

    const { name, description, status } = req.body as {
      name?: string;
      description?: string;
      status?: string;
    };

    const updates: Record<string, unknown> = {};
    if (name !== undefined) updates.name = name;
    if (description !== undefined) updates.description = description;
    if (status !== undefined) updates.status = status;

    if (Object.keys(updates).length === 0) {
      res.status(400).json({ error: "No fields to update" });
      return;
    }

    const [game] = await db
      .update(gamesTable)
      .set(updates)
      .where(eq(gamesTable.id, id))
      .returning();

    if (!game) {
      res.status(404).json({ error: "Game not found" });
      return;
    }

    res.json(game);
  } catch (err) {
    res.status(500).json({ error: "Failed to update game" });
  }
});

// DELETE /api/admin/games/:id
router.delete("/games/:id", async (req, res): Promise<void> => {
  try {
    const id = Number(req.params.id);
    if (Number.isNaN(id)) {
      res.status(400).json({ error: "Invalid game id" });
      return;
    }

    const [game] = await db.delete(gamesTable).where(eq(gamesTable.id, id)).returning();

    if (!game) {
      res.status(404).json({ error: "Game not found" });
      return;
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: "Failed to delete game" });
  }
});

export default router;
