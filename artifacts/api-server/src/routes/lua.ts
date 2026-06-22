import { Router } from "express";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";

const router = Router();

const LUA_DIR = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../lua/games"
);

// Hanya izinkan nama game: huruf, angka, underscore, strip (keamanan path traversal)
const VALID_GAME_NAME = /^[a-z0-9_-]{1,64}$/i;

router.get("/loader", async (req, res) => {
  const ua = (req.headers["user-agent"] ?? "").toLowerCase();
  const isRoblox = ua.includes("roblox");

  if (!isRoblox) {
    res.status(403).send("Forbidden");
    return;
  }

  const game = (req.query["game"] as string | undefined)?.trim();

  if (!game) {
    res
      .status(400)
      .send(
        '-- ERROR: Parameter "game" wajib diisi.\n-- Contoh: /api/lua/loader?game=soul_iron'
      );
    return;
  }

  if (!VALID_GAME_NAME.test(game)) {
    res.status(400).send('-- ERROR: Nama game tidak valid.');
    return;
  }

  const filePath = path.join(LUA_DIR, `${game}.lua`);

  try {
    const content = await readFile(filePath, "utf-8");
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.send(content);
  } catch {
    res
      .status(404)
      .send(`-- ERROR: Script untuk game "${game}" tidak ditemukan.`);
  }
});

// Serve per-game modules: GET /lua/module/:game/:name
// Path: lua/games/:game/:name.lua  — both params sanitized against path traversal
const VALID_MOD_NAME = /^[a-z0-9_]{1,64}$/i;

router.get("/module/:game/:name", async (req, res) => {
  const ua = (req.headers["user-agent"] ?? "").toLowerCase();
  const isRoblox = ua.includes("roblox");

  if (!isRoblox) {
    res.status(403).send("Forbidden");
    return;
  }

  const { game, name } = req.params;

  if (!VALID_GAME_NAME.test(game)) {
    res.status(400).send("-- ERROR: Nama game tidak valid.");
    return;
  }

  if (!VALID_MOD_NAME.test(name)) {
    res.status(400).send("-- ERROR: Nama modul tidak valid.");
    return;
  }

  const filePath = path.join(LUA_DIR, game, `${name}.lua`);

  // Verify resolved path stays inside LUA_DIR (defense-in-depth)
  if (!filePath.startsWith(LUA_DIR + path.sep)) {
    res.status(400).send("-- ERROR: Path tidak diizinkan.");
    return;
  }

  try {
    const content = await readFile(filePath, "utf-8");
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.send(content);
  } catch {
    res
      .status(404)
      .send(`-- ERROR: Modul "${game}/${name}" tidak ditemukan.`);
  }
});

// Daftar game yang tersedia
router.get("/games", async (_req, res) => {
  const { readdir } = await import("node:fs/promises");
  try {
    const files = await readdir(LUA_DIR);
    const games = files
      .filter((f) => f.endsWith(".lua"))
      .map((f) => f.replace(".lua", ""));
    res.json({ games });
  } catch {
    res.json({ games: [] });
  }
});

export default router;
