import { Interaction, ChatInputCommandInteraction, EmbedBuilder } from "discord.js";
import { logger } from "../../lib/logger.js";
import * as genkey from "../commands/genkey.js";
import * as checkkey from "../commands/checkkey.js";
import * as sethwid from "../commands/sethwid.js";
import * as resethwid from "../commands/resethwid.js";
import * as revoke from "../commands/revoke.js";

const commandMap = new Map([
  ["genkey", genkey],
  ["checkkey", checkkey],
  ["sethwid", sethwid],
  ["resethwid", resethwid],
  ["revoke", revoke],
]);

export async function onInteractionCreate(interaction: Interaction): Promise<void> {
  if (!interaction.isChatInputCommand()) return;

  const cmd = commandMap.get(interaction.commandName);
  if (!cmd) return;

  logger.info(
    { user: interaction.user.tag, command: interaction.commandName },
    "Command executed"
  );

  try {
    await cmd.execute(interaction);
  } catch (err) {
    logger.error({ err, command: interaction.commandName }, "Command error");

    const errorEmbed = new EmbedBuilder()
      .setColor(0xd50000)
      .setTitle("❌ Internal Error")
      .setDescription("An unexpected error occurred while executing this command.")
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
