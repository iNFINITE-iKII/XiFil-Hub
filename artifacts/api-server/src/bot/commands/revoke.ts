import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, revokeLicense } from "../database.js";
import { logRevoke } from "../../lib/discordLogger.js";
import { censorKey } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("revoke")
  .setDescription("Permanently revoke a license key — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("The license key to revoke").setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.get("key")?.value as string).trim().toUpperCase();
  const license = await getByKey(key);

  if (!license) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Key Not Found")
          .setDescription("This license key does not exist.")
          .setTimestamp(),
      ],
    });
    return;
  }

  if (license.status === "REVOKED") {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("⚠️ Already Revoked")
          .setDescription("This key is already permanently revoked.")
          .setTimestamp(),
      ],
    });
    return;
  }

  await revokeLicense(key);
  await logRevoke(key, interaction.user.id);

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0xd50000)
        .setTitle("🔴 Key Revoked")
        .setDescription(
          `License \`${censorKey(key)}\` has been **permanently revoked**. All client access will be blocked immediately on next validation.`
        )
        .addFields(
          { name: "Previous Status", value: license.status, inline: true },
          { name: "Revoked by", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setFooter({ text: "License Manager • This action is irreversible" })
        .setTimestamp(),
    ],
  });
}
