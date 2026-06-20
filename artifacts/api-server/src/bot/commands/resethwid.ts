import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { stmtGetByKey, stmtResetHwid } from "../database.js";
import { censorKey } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("resethwid")
  .setDescription(
    "Reset HWID binding for a license key (allows migration to new hardware)"
  )
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("The license key").setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.get("key")?.value as string).trim().toUpperCase();
  const license = stmtGetByKey.get(key);

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
          .setColor(0xd50000)
          .setTitle("❌ Key Revoked")
          .setDescription("Cannot modify a revoked license key.")
          .setTimestamp(),
      ],
    });
    return;
  }

  if (!license.hwid_hash) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("⚠️ No HWID Bound")
          .setDescription("This key has no HWID binding to reset.")
          .setTimestamp(),
      ],
    });
    return;
  }

  stmtResetHwid.run(key);

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ HWID Reset")
        .setDescription(
          `HWID binding removed from \`${censorKey(key)}\`. The next activation will bind to a new device.`
        )
        .addFields(
          { name: "Admin", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setFooter({ text: "License Manager" })
        .setTimestamp(),
    ],
  });
}
