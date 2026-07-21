import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, setHwid } from "../database.js";
import { censorKey } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("sethwid")
  .setDescription("Manually bind a license key to a specific HWID — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("The license key").setRequired(true)
  )
  .addStringOption((opt) =>
    opt.setName("hwid").setDescription("The HWID hash to bind").setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.get("key")?.value as string).trim().toUpperCase();
  const hwid = (interaction.options.get("hwid")?.value as string).trim();

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
          .setColor(0xd50000)
          .setTitle("❌ Key Revoked")
          .setDescription("Cannot modify a revoked license key.")
          .setTimestamp(),
      ],
    });
    return;
  }

  await setHwid(hwid, key);

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ HWID Set")
        .setDescription(`HWID has been bound to key \`${censorKey(key)}\`.`)
        .addFields(
          { name: "HWID Hash", value: `\`${hwid.substring(0, 32)}...\``, inline: false },
          { name: "Admin", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setFooter({ text: "License Manager" })
        .setTimestamp(),
    ],
  });
}
