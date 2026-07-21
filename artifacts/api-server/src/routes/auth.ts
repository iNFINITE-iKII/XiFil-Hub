import { Router } from "express";
import { db } from "@workspace/db";
import { usersTable } from "@workspace/db";
import { eq } from "drizzle-orm";

const router = Router();

const DISCORD_CLIENT_ID = process.env["DISCORD_CLIENT_ID"];
const DISCORD_CLIENT_SECRET = process.env["DISCORD_CLIENT_SECRET"];

function getRedirectUri(req: any): string {
  // Prioritas: env var eksplisit → Railway domain → Replit dev domain → fallback ke request hostname
  if (process.env["APP_URL"]) {
    return `${process.env["APP_URL"]}/api/auth/discord/callback`;
  }
  if (process.env["RAILWAY_PUBLIC_DOMAIN"]) {
    return `https://${process.env["RAILWAY_PUBLIC_DOMAIN"]}/api/auth/discord/callback`;
  }
  if (process.env["REPLIT_DEV_DOMAIN"]) {
    return `https://${process.env["REPLIT_DEV_DOMAIN"]}/api/auth/discord/callback`;
  }
  return `${req.protocol}://${req.hostname}/api/auth/discord/callback`;
}

// GET /api/auth/discord - redirect to Discord OAuth
router.get("/discord", (req, res): void => {
  if (!DISCORD_CLIENT_ID) {
    res.status(503).json({ error: "Discord auth not configured. Set DISCORD_CLIENT_ID." });
    return;
  }
  // Generate and store CSRF state token
  const state = crypto.randomUUID();
  (req.session as any).oauthState = state;

  // Explicitly save session BEFORE redirecting so state is persisted
  req.session.save((err) => {
    if (err) {
      res.status(500).json({ error: "Session save failed" });
      return;
    }
    const redirectUri = encodeURIComponent(getRedirectUri(req));
    const url = `https://discord.com/api/oauth2/authorize?client_id=${DISCORD_CLIENT_ID}&redirect_uri=${redirectUri}&response_type=code&scope=identify&state=${state}`;
    res.redirect(url);
  });
});

// GET /api/auth/discord/callback - handle OAuth callback
router.get("/discord/callback", async (req, res) => {
  const { code, state } = req.query;

  // Validate CSRF state
  const sessionState = (req.session as any).oauthState;
  if (!state || !sessionState || state !== sessionState) {
    res.redirect("/?error=invalid_state");
    return;
  }
  (req.session as any).oauthState = undefined;

  if (!code || typeof code !== "string") {
    res.redirect("/?error=missing_code");
    return;
  }

  if (!DISCORD_CLIENT_ID || !DISCORD_CLIENT_SECRET) {
    res.redirect("/?error=not_configured");
    return;
  }

  try {
    // Exchange code for token
    const tokenRes = await fetch("https://discord.com/api/oauth2/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: DISCORD_CLIENT_ID,
        client_secret: DISCORD_CLIENT_SECRET,
        grant_type: "authorization_code",
        code,
        redirect_uri: getRedirectUri(req),
      }),
    });

    if (!tokenRes.ok) {
      req.log.error({ status: tokenRes.status }, "Discord token exchange failed");
      res.redirect("/?error=token_failed");
      return;
    }

    const tokenData = await tokenRes.json() as { access_token: string };

    // Fetch user info from Discord
    const userRes = await fetch("https://discord.com/api/users/@me", {
      headers: { Authorization: `Bearer ${tokenData.access_token}` },
    });

    if (!userRes.ok) {
      res.redirect("/?error=user_fetch_failed");
      return;
    }

    const discordUser = await userRes.json() as {
      id: string;
      username: string;
      avatar: string | null;
    };

    // Upsert user in DB
    const [user] = await db
      .insert(usersTable)
      .values({
        discordId: discordUser.id,
        username: discordUser.username,
        avatar: discordUser.avatar,
      })
      .onConflictDoUpdate({
        target: usersTable.discordId,
        set: {
          username: discordUser.username,
          avatar: discordUser.avatar,
        },
      })
      .returning();

    // Save to session explicitly before redirect
    (req.session as any).userId = user.id;
    req.session.save((saveErr) => {
      if (saveErr) {
        req.log.error({ saveErr }, "Session save failed after OAuth");
        res.redirect("/?error=session_failed");
        return;
      }
      res.redirect("/dashboard");
    });
  } catch (err) {
    req.log.error({ err }, "Discord OAuth error");
    res.redirect("/?error=oauth_error");
  }
});

// GET /api/auth/me - get current user
router.get("/me", async (req, res): Promise<void> => {
  const userId = (req.session as any)?.userId;
  if (!userId) {
    res.status(401).json({ error: "Not authenticated" });
    return;
  }

  const [user] = await db
    .select()
    .from(usersTable)
    .where(eq(usersTable.id, userId));

  if (!user) {
    (req.session as any).userId = undefined;
    res.status(401).json({ error: "User not found" });
    return;
  }

  res.json({
    id: user.id,
    discordId: user.discordId,
    username: user.username,
    avatar: user.avatar,
    isAdmin: user.isAdmin,
    createdAt: user.createdAt.toISOString(),
  });
});

// POST /api/auth/logout
router.post("/logout", (req, res) => {
  req.session.destroy(() => {
    res.json({ message: "Logged out successfully" });
  });
});

export default router;
