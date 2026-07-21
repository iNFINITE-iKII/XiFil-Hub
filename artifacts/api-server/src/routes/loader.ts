import { Router } from "express";
import { db } from "@workspace/db";
import { gamesTable } from "@workspace/db";
import { eq } from "drizzle-orm";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// NOTE: esbuild bundles this file into dist/index.mjs, so __dirname at
// runtime is artifacts/api-server/dist (one level shallower than the
// original src/routes location) — only one ".." is needed to reach
// artifacts/api-server/lua/games.
const LUA_DIR = path.resolve(__dirname, "../lua/games");

const router = Router();

// GET /api/loader/:slug
// Called by Roblox executor: loadstring(game:HttpGet("..."))()
router.get("/:slug", async (req, res): Promise<void> => {
  const { slug } = req.params;

  // Sanitize slug — only allow alphanumeric, hyphens, underscores
  if (!/^[a-zA-Z0-9_-]+$/.test(slug)) {
    res.status(400).send("-- Invalid script name");
    return;
  }

  // Check game exists in DB
  const [game] = await db
    .select()
    .from(gamesTable)
    .where(eq(gamesTable.slug, slug));

  if (!game) {
    res.status(404).send(`-- Script '${slug}' tidak ditemukan.`);
    return;
  }

  if (game.status !== "active") {
    res.status(403).send(`-- Script '${slug}' sedang tidak aktif.`);
    return;
  }

  // Look for lua file: lua/games/<slug>.lua or lua/games/<slug>/loader.lua
  const candidates = [
    path.join(LUA_DIR, `${slug}.lua`),
    path.join(LUA_DIR, slug, "loader.lua"),
  ];

  let luaPath: string | null = null;
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      luaPath = candidate;
      break;
    }
  }

  if (!luaPath) {
    res.status(404).send(`-- File lua untuk '${slug}' belum tersedia.`);
    return;
  }

  const luaContent = fs.readFileSync(luaPath, "utf-8");
  res.setHeader("Content-Type", "text/plain; charset=utf-8");
  res.send(luaContent);
});

export default router;
