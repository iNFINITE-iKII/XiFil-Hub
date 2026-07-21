import { Router, type IRouter } from "express";
import { db } from "@workspace/db";
import { gamesTable } from "@workspace/db";
import { eq } from "drizzle-orm";

const router: IRouter = Router();

// GET /api/games - list all active games (public)
router.get("/", async (_req, res): Promise<void> => {
  try {
    const games = await db
      .select()
      .from(gamesTable)
      .where(eq(gamesTable.status, "active"));
    res.json(games);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch games" });
  }
});

// GET /api/games/:slug - get a single game by slug
router.get("/:slug", async (req, res): Promise<void> => {
  try {
    const { slug } = req.params;
    const [game] = await db
      .select()
      .from(gamesTable)
      .where(eq(gamesTable.slug, slug));

    if (!game) {
      res.status(404).json({ error: "Game not found" });
      return;
    }
    res.json(game);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch game" });
  }
});

export default router;
