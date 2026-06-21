import { Interaction, ChatInputCommandInteraction, EmbedBuilder, ButtonInteraction } from "discord.js";
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
import { handleButton } from "../handlers/buttonHandler.js";

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
]);

export async function onInteractionCreate(interaction: Interaction): Promise<void> {
  if (interaction.isButton()) {
    logger.info(
      { user: interaction.user.tag, button: interaction.customId },
      "Button clicked"
    );

    try {
      await handleButton(interaction as ButtonInteraction);
    } catch (err) {
      logger.error({ err, button: interaction.customId }, "Button handler error");

      const errorEmbed = new EmbedBuilder()
        .setColor(0xd50000)
        .setTitle("❌ Internal Error")
        .setDescription("Terjadi error saat memproses tombol ini.")
        .setTimestamp();

      if (interaction.deferred || interaction.replied) {
        await (interaction as ButtonInteraction).editReply({ embeds: [errorEmbed] }).catch(() => null);
      } else {
        await (interaction as ButtonInteraction).reply({ embeds: [errorEmbed], ephemeral: true }).catch(() => null);
      }
    }
    return;
  }

  if (!interaction.isChatInputCommand()) return;

  const cmd = commandMap.get(interaction.commandName);
  if (!cmd) return;

  logger.info(
    { user: interaction.user.tag, command: interaction.commandName },
    "Command executed"
  );

  try {
    await cmd.execute(interaction as ChatInputCommandInteraction);
  } catch (err) {
    logger.error({ err, command: interaction.commandName }, "Command error");

    const errorEmbed = new EmbedBuilder()
      .setColor(0xd50000)
      .setTitle("❌ Internal Error")
      .setDescription("Terjadi error saat menjalankan perintah ini.")
      .setTimestamp();

    if (interaction.deferred || interaction.replied) {
      await interaction.editReply({ embeds: [errorEmbed] }).catch(() => null);
    } else {
      await interaction
        .reply({ embeds: [errorEmbed], ephemeral: true })
        .catch(() => null);
    }
  }
}
