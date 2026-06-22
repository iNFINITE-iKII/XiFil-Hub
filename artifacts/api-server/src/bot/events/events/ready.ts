import {
  Client,
  REST,
  Routes,
  EmbedBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  TextChannel,
} from "discord.js";
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
import * as sethwidcount from "../commands/sethwidcount.js";

const commands = [
  genkey, checkkey, sethwid, resethwid, revoke,
  whitelist, setmaxhwid, userkey, panel, deletekey,
  stats, renewkey, transferkey, setlabel, cleanup, help,
  sethwidcount,
];

function buildPanelEmbed(): EmbedBuilder {
  return new EmbedBuilder()
    .setColor(0x5865f2)
    .setTitle("🌟 Panel VIP — XiFil Hub")
    .setDescription(
      "Gunakan tombol di bawah untuk mengakses fitur member:\n\n" +
      "🎖️ **Get Role VIP** — Klaim role VIP (perlu whitelist)\n" +
      "🔑 **Get Key** — Lihat license key kamu (perlu whitelist)\n" +
      "🔄 **Reset HWID** — Reset HWID key kamu (perlu whitelist)\n" +
      "🔍 **Cek HWID** — Lihat HWID yang terikat ke key kamu\n" +
      "🎟️ **Request Akses** — Minta akses VIP ke admin\n" +
      "📜 **Get Script** — Dapatkan script Roblox (semua orang)"
    )
    .setFooter({ text: "XiFil Hub • License Manager • Semua aksi bersifat privat" })
    .setTimestamp();
}

function buildPanelRows(): ActionRowBuilder<ButtonBuilder>[] {
  const row1 = new ActionRowBuilder<ButtonBuilder>().addComponents(
    new ButtonBuilder()
      .setCustomId("get_role_vip")
      .setLabel("Get Role VIP")
      .setEmoji("🎖️")
      .setStyle(ButtonStyle.Primary),
    new ButtonBuilder()
      .setCustomId("get_key")
      .setLabel("Get Key")
      .setEmoji("🔑")
      .setStyle(ButtonStyle.Success),
    new ButtonBuilder()
      .setCustomId("reset_hwid")
      .setLabel("Reset HWID")
      .setEmoji("🔄")
      .setStyle(ButtonStyle.Danger)
  );

  const row2 = new ActionRowBuilder<ButtonBuilder>().addComponents(
    new ButtonBuilder()
      .setCustomId("cek_hwid")
      .setLabel("Cek HWID")
      .setEmoji("🔍")
      .setStyle(ButtonStyle.Secondary),
    new ButtonBuilder()
      .setCustomId("request_akses_vip")
      .setLabel("Request Akses")
      .setEmoji("🎟️")
      .setStyle(ButtonStyle.Primary),
    new ButtonBuilder()
      .setCustomId("get_script")
      .setLabel("Get Script")
      .setEmoji("📜")
      .setStyle(ButtonStyle.Secondary)
  );

  return [row1, row2];
}

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
