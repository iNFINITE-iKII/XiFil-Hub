import {
  Interaction,
  ChatInputCommandInteraction,
  EmbedBuilder,
  ButtonInteraction,
  ModalSubmitInteraction,
} from "discord.js";
import { logger } from "../../lib/logger.js";
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
import {
  handleButton,
  handleResetHwidModal,
  handleApproveTicketModal,
} from "../handlers/buttonHandler.js";

const commandMap = new Map([
  ["genkey", genkey],
  ["checkkey", checkkey],
  ["sethwid", sethwid],
  ["resethwid", resethwid],
  ["revoke", revoke],
  ["whitelist", whitelist],
  ["setmaxhwid", setmaxhwid],
  ["userkey", userkey],
  ["panel", panel],
  ["deletekey", deletekey],
  ["stats", stats],
  ["renewkey", renewkey],
  ["transferkey", transferkey],
  ["setlabel", setlabel],
  ["cleanup", cleanup],
  ["help", help],
  ["sethwidcount", sethwidcount],
]);

export async function onInteractionCreate(interaction: Interaction): Promise<void> {
  // ─── Button ────────────────────────────────────────────────────────────
  if (interaction.isButton()) {
    logger.info({ user: interaction.user.tag, button: interaction.customId }, "Button clicked");
    try {
      await handleButton(interaction as ButtonInteraction);
    } catch (err) {
      logger.error({ err, button: interaction.customId }, "Button handler error");
      const embed = new EmbedBuilder()
        .setColor(0xd50000).setTitle("❌ Terjadi Kesalahan")
        .setDescription("Terjadi kesalahan sistem. Silakan coba lagi atau hubungi Administrator.")
        .setTimestamp();
      const btn = interaction as ButtonInteraction;
      if (btn.deferred || btn.replied) {
        await btn.editReply({ embeds: [embed] }).catch(() => null);
      } else {
        await btn.reply({ embeds: [embed], ephemeral: true }).catch(() => null);
      }
    }
    return;
  }

  // ─── Modal Submit ──────────────────────────────────────────────────────
  if (interaction.isModalSubmit()) {
    const modal = interaction as ModalSubmitInteraction;
    logger.info({ user: interaction.user.tag, modal: modal.customId }, "Modal submitted");
    try {
      if (modal.customId === "reset_hwid_modal") {
        await handleResetHwidModal(modal);
      } else if (modal.customId.startsWith("approve_ticket_modal_")) {
        await handleApproveTicketModal(modal);
      }
    } catch (err) {
      logger.error({ err, modal: modal.customId }, "Modal handler error");
      const embed = new EmbedBuilder()
        .setColor(0xd50000).setTitle("❌ Terjadi Kesalahan")
        .setDescription("Terjadi kesalahan sistem saat memproses formulir. Silakan coba lagi.")
        .setTimestamp();
      if (modal.deferred || modal.replied) {
        await modal.editReply({ embeds: [embed] }).catch(() => null);
      } else {
        await modal.reply({ embeds: [embed], ephemeral: true }).catch(() => null);
      }
    }
    return;
  }

  // ─── Slash Command ─────────────────────────────────────────────────────
  if (!interaction.isChatInputCommand()) return;

  const cmd = commandMap.get(interaction.commandName);
  if (!cmd) return;

  logger.info({ user: interaction.user.tag, command: interaction.commandName }, "Command executed");

  try {
    await cmd.execute(interaction as ChatInputCommandInteraction);
  } catch (err) {
    logger.error({ err, command: interaction.commandName }, "Command error");
    const embed = new EmbedBuilder()
      .setColor(0xd50000).setTitle("❌ Terjadi Kesalahan")
      .setDescription("Terjadi kesalahan sistem saat menjalankan perintah ini.")
      .setTimestamp();
    if (interaction.deferred || interaction.replied) {
      await interaction.editReply({ embeds: [embed] }).catch(() => null);
    } else {
      await interaction.reply({ embeds: [embed], ephemeral: true }).catch(() => null);
    }
  }
}
