import app from "./app.js";
import { logger } from "./lib/logger.js";
import { startBot } from "./bot/bot.js";
import { initDb } from "./bot/database.js";

const rawPort = process.env["PORT"];

if (!rawPort) {
  throw new Error(
    "PORT environment variable is required but was not provided.",
  );
}

const port = Number(rawPort);

if (Number.isNaN(port) || port <= 0) {
  throw new Error(`Invalid PORT value: "${rawPort}"`);
}

// Log DB host at startup (no credentials)
const dbUrl = process.env["NEON_DATABASE_URL"] ?? "";
try {
  const host = new URL(dbUrl).hostname;
  logger.info({ dbHost: host }, "Connecting to database");
} catch {
  logger.warn("NEON_DATABASE_URL is not set or invalid");
}

initDb()
  .then(() => {
    logger.info("Database initialized");

    app.listen(port, (err) => {
      if (err) {
        logger.error({ err }, "Error listening on port");
        process.exit(1);
      }
      logger.info({ port }, "Server listening");
    });

    startBot();
  })
  .catch((err) => {
    logger.error({ err }, "Failed to initialize database");
    process.exit(1);
  });
