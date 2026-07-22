import express, { type Express } from "express";
import cors from "cors";
import pinoHttp from "pino-http";
import session from "express-session";
import ConnectPgSimple from "connect-pg-simple";
import { pool } from "@workspace/db";
import router from "./routes/index.js";
import { logger } from "./lib/logger.js";
import path from "path";
import { fileURLToPath } from "url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PgSession = ConnectPgSimple(session);

const app: Express = express();

// Trust the Replit reverse proxy so cookies work correctly over HTTPS
app.set("trust proxy", 1);

app.use(
  pinoHttp({
    logger,
    serializers: {
      req(req) {
        return {
          id: req.id,
          method: req.method,
          url: req.url?.split("?")[0],
        };
      },
      res(res) {
        return {
          statusCode: res.statusCode,
        };
      },
    },
  }),
);

app.use(cors({
  origin: true,
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const sessionSecret = process.env["SESSION_SECRET"];
if (!sessionSecret) {
  throw new Error("SESSION_SECRET must be set");
}

app.use(
  session({
    store: new PgSession({
      pool,
      tableName: "session",
      createTableIfMissing: true, // auto-create if missing
    }),
    secret: sessionSecret,
    resave: false,
    saveUninitialized: false,
    cookie: {
      maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
      httpOnly: true,
      secure: true, // Replit always serves over HTTPS via proxy
      sameSite: "lax",
    },
  })
);

app.use("/api", router);

// Serve frontend static files di production
const frontendDist = path.resolve(__dirname, "../../xifil-hub/dist/public");
logger.info({ frontendDist }, "Serving static files from");
app.use(express.static(frontendDist));

// Catch-all: semua route non-API diarahkan ke index.html (React Router)
app.get("/{*splat}", (_req, res) => {
  const indexPath = path.join(frontendDist, "index.html");
  res.sendFile(indexPath, (err) => {
    if (err) {
      res.status(200).send(`<h2>XiFil Hub API running</h2><p>Frontend not found at: ${indexPath}</p>`);
    }
  });
});

export default app;
