import {
  Client,
  REST,
  Routes,
  EmbedBuilder,
  TextChannel,
} from "discord.js";
import { buildPanelEmbed, buildPanelRows } from "../utils/panelBuilder.js";
import { logger } from "../../lib/logger.js";
import { startExpireNotifier } from "../../lib/expireNotifier.js";
import * as genkey from "../commands/genkey.js";
import * as checkkey from "../commands/checkkey.js";
import * as sethwid from "../commands/sethwid.js";
import * as resethwid from "../commands/resethwid.js";
import * as revoke from "../commands/revoke.js";
import * as whitelist from "../commands/whitelist.js";
import * as setmaxhwid from "../commands/setmaxhwid.js";
import * as userkey from "../commands/userkey.js";
import * as panel from "../commands/panel.js";
import * as deletekey from "../commands/deletekey.js";
import * as stats from "../commands/stats.js";
import * as renewkey from "../commands/renewkey.js";
import * as transferkey from "../commands/transferkey.js";
import * as setlabel from "../commands/setlabel.js";
import * as cleanup from "../commands/cleanup.js";
import * as help from "../commands/help.js";
import * as setaccountlimit from "../commands/setaccountlimit.js";
import * as syncpremium from "../commands/syncpremium.js";
import * as resetticket from "../commands/resetticket.js";

const commands = [
  genkey, checkkey, sethwid, resethwid, revoke,
  whitelist, setmaxhwid, userkey, panel, deletekey,
  stats, renewkey, transferkey, setlabel, cleanup, help,
  setaccountlimit, syncpremium, resetticket,
];


async function sendAutoPanelToVipChannel(client: Client): Promise<void> {
  try {
    for (const guild of client.guilds.cache.values()) {
      const panelChannel = guild.channels.cache.find(
        (ch) => ch.isTextBased() && ch.name.toLowerCase().includes("panel-vip")
      ) as TextChannel | undefined;

      if (!panelChannel) continue;

      const messages = await panelChannel.messages.fetch({ limit: 10 });
      const existing = messages.find(
        (m) =>
          m.author.id === client.user!.id &&
          m.components.length > 0 &&
          m.embeds.length > 0
      );

      if (existing) {
        logger.info({ channel: panelChannel.name }, "Panel already exists, skipping auto-send");
        continue;
      }

      await panelChannel.send({
        embeds: [buildPanelEmbed()],
        components: buildPanelRows(),
      });

      logger.info({ channel: panelChannel.name }, "Auto-sent panel to panel-vip channel");
    }
  } catch (err) {
    logger.error({ err }, "Failed to auto-send panel");
  }
}

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
    logger.info({ count: commandData.length }, "Slash commands registered successfully");
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

  await sendAutoPanelToVipChannel(client);
  startExpireNotifier();
}
