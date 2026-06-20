import { Client, REST, Routes } from "discord.js";
import { logger } from "../../lib/logger.js";
import * as genkey from "../commands/genkey.js";
import * as checkkey from "../commands/checkkey.js";
import * as sethwid from "../commands/sethwid.js";
import * as resethwid from "../commands/resethwid.js";
import * as revoke from "../commands/revoke.js";

const commands = [genkey, checkkey, sethwid, resethwid, revoke];

export async function onReady(client: Client): Promise<void> {
  logger.info({ tag: client.user?.tag }, "Discord bot logged in");

  const token = process.env["DISCORD_BOT_TOKEN"]!;
  const clientId = process.env["DISCORD_CLIENT_ID"]!;
  const guildId = process.env["DISCORD_GUILD_ID"]!;

  const rest = new REST({ version: "10" }).setToken(token);
  const commandData = commands.map((c) => c.data.toJSON());

  try {
    logger.info("Registering slash commands to guild...");
    await rest.put(Routes.applicationGuildCommands(clientId, guildId), {
      body: commandData,
    });
    logger.info(
      { count: commandData.length },
      "Slash commands registered successfully"
    );
  } catch (err: unknown) {
    const apiErr = err as { code?: number; status?: number };
    if (apiErr?.code === 50001 || apiErr?.status === 403) {
      logger.error(
        "⚠️  MISSING ACCESS: Bot is not in the guild or lacks applications.commands scope.\n" +
        `   → Invite URL: https://discord.com/oauth2/authorize?client_id=${clientId}&permissions=8&scope=bot+applications.commands`
      );
    } else {
      logger.error({ err }, "Failed to register slash commands");
    }
  }
}
