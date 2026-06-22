import { Client, GatewayIntentBits } from "discord.js";
import { logger } from "../lib/logger.js";
import { onReady } from "./events/ready.js";
import { onInteractionCreate } from "./events/interactionCreate.js";
import { setClient } from "./clientRef.js";

export function startBot(): void {
  const token = process.env["DISCORD_BOT_TOKEN"];
  if (!token) {
    logger.warn("DISCORD_BOT_TOKEN not set — bot will not start");
    return;
  }

  const client = new Client({
    intents: [GatewayIntentBits.Guilds],
  });

  setClient(client);

  client.once("ready", () => onReady(client));
  client.on("interactionCreate", onInteractionCreate);

  client.on("error", (err) => {
    logger.error({ err }, "Discord client error");
  });

  client
    .login(token)
    .then(() => logger.info("Discord bot connecting..."))
    .catch((err) => logger.error({ err }, "Failed to login to Discord"));
}
