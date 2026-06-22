import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey } from "../database.js";
import { statusColor, statusEmoji, durationLabel } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("checkkey")
  .setDescription("Check the status and details of a license key — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt
      .setName("key")
      .setDescription("The license key to check")
      .setRequired(true)
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
          .setDescription("This license key does not exist in the database.")
          .setTimestamp(),
      ],
    });
    return;
  }

  const now = Date.now();

  let expiryField = "Never (Permanent)";
  if (license.duration_type !== "PERMANENT" && license.expires_at) {
    if (now > license.expires_at) {
      expiryField = `Expired <t:${Math.floor(license.expires_at / 1000)}:R>`;
    } else {
      expiryField = `<t:${Math.floor(license.expires_at / 1000)}:F> (<t:${Math.floor(license.expires_at / 1000)}:R>)`;
    }
  } else if (license.status === "UNUSED") {
    expiryField = "⏳ Starts on first activation";
  }

  const periodLabel: Record<string, string> = {
    DAILY: "Per hari",
    WEEKLY: "Per minggu",
    MONTHLY: "Per bulan",
    UNLIMITED: "Tidak ada cooldown",
  };

  const embed = new EmbedBuilder()
    .setColor(statusColor(license.status))
    .setTitle(`${statusEmoji(license.status)} License Key Details`)
    .addFields(
      { name: "Key (Full)", value: `\`${key}\``, inline: false },
      { name: "Status", value: `${statusEmoji(license.status)} **${license.status}**`, inline: true },
      { name: "Type", value: durationLabel(license.duration_type, license.duration_value), inline: true },
      { name: "HWID Lock", value: license.hwid_hash ? `\`${license.hwid_hash.substring(0, 16)}...\`` : "🔓 Not bound", inline: true },
      { name: "Expires", value: expiryField, inline: false },
      { name: "HWID Reset", value: `${license.hwid_reset_count}/${license.max_hwid_resets === -1 ? "∞" : license.max_hwid_resets} • ${periodLabel[license.hwid_reset_period] ?? license.hwid_reset_period}`, inline: true },
      { name: "Created", value: `<t:${Math.floor(license.created_at / 1000)}:F>`, inline: true },
      { name: "Issued by", value: `<@${license.issuer_discord_id}>`, inline: true },
    )
    .setFooter({ text: "License Manager" })
    .setTimestamp();

  await interaction.editReply({ embeds: [embed] });
}
