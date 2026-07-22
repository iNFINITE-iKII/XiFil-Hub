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

// GET /api/lua/loader?game=<slug>
// Format: loadstring(game:HttpGet("https://xifil-hub-production.up.railway.app/api/lua/loader?game=soul_iron"))()
router.get("/loader", async (req, res): Promise<void> => {
  const slug = req.query.game as string | undefined;

  if (!slug) {
    res.status(400).send("-- Parameter 'game' diperlukan.");
    return;
  }

  // Sanitize — only alphanumeric, hyphens, underscores
  if (!/^[a-zA-Z0-9_-]+$/.test(slug)) {
    res.status(400).send("-- Nama game tidak valid.");
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

// GET /api/lua/module/:game/*filePath
// Serves individual module files inside lua/games/<game>/... (e.g. the
// ironsoulv1 UI modules). This lets a game's main entry script (e.g.
// soul_iron.lua) bootstrap its modules from THIS server instead of a
// hardcoded external GitHub repo, so fixes made here actually reach players.
router.get("/module/:game/{*filePath}", async (req, res): Promise<void> => {
  const { game } = req.params;
  const filePathParts = req.params.filePath;
  const relPath = Array.isArray(filePathParts)
    ? filePathParts.join("/")
    : (filePathParts ?? "");

  if (!/^[a-zA-Z0-9_-]+$/.test(game)) {
    res.status(400).send("-- Invalid game name");
    return;
  }
  if (!relPath || !/^[a-zA-Z0-9_\-./]+\.lua$/.test(relPath)) {
    res.status(400).send("-- Invalid module path");
    return;
  }

  const gameDir = path.resolve(LUA_DIR, game);
  const filePath = path.resolve(gameDir, relPath);

  // Prevent path traversal outside the game's own module directory
  if (!filePath.startsWith(gameDir + path.sep)) {
    res.status(400).send("-- Invalid module path");
    return;
  }

  if (!fs.existsSync(filePath)) {
    res.status(404).send(`-- Module '${relPath}' tidak ditemukan.`);
    return;
  }

  const content = fs.readFileSync(filePath, "utf-8");
  res.setHeader("Content-Type", "text/plain; charset=utf-8");
  res.send(content);
});

export default router;
