import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, setMaxHwidCount, getHwidsForKey } from "../database.js";
import { censorKey } from "../utils.js";
import { safeDefer } from "../utils/safeDefer.js";

export const data = new SlashCommandBuilder()
  .setName("setaccountlimit")
  .setDescription("Set jumlah akun Roblox yang boleh pakai satu key secara bersamaan — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("License key yang akan diubah").setRequired(true)
  )
  .addIntegerOption((opt) =>
    opt
      .setName("count")
      .setDescription("Jumlah akun Roblox max (1 = satu akun, 2–10 = multi-akun)")
      .setRequired(true)
      .setMinValue(1)
      .setMaxValue(1000)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  if (!await safeDefer(interaction)) return;

  const key = (interaction.options.get("key")?.value as string).trim().toUpperCase();
  const count = interaction.options.get("count")?.value as number;

  const license = await getByKey(key);

  if (!license) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Key Tidak Ditemukan")
          .setDescription("License key ini tidak ada di database.")
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
          .setTitle("❌ Key Sudah Dicabut")
          .setDescription("Tidak bisa memodifikasi key yang sudah dicabut.")
          .setTimestamp(),
      ],
    });
    return;
  }

  const currentHwids = await getHwidsForKey(key);
  const currentCount = license.max_hwid_count ?? 1;

  let warningText = "";
  if (count < currentHwids.length) {
    warningText =
      `\n\n⚠️ **Perhatian:** Saat ini key ini terikat ke **${currentHwids.length} akun Roblox**, ` +
      `tapi batas baru yang kamu set adalah **${count}**.\n` +
      "Akun yang sudah terikat **tidak otomatis dilepas** — reset HWID key ini untuk membersihkan binding yang ada.";
  }

  await setMaxHwidCount(key, count);

  const modeLabel = count === 1 ? "🔒 Single Account" : `📱 Multi-Akun (max ${count} akun)`;
  const changeLabel =
    currentCount === count
      ? "Tidak ada perubahan"
      : `${currentCount} akun → **${count} akun**`;

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ Batas Akun Roblox Diupdate")
        .setDescription(
          `Jumlah akun Roblox maksimal untuk key \`${censorKey(key)}\` telah diubah.${warningText}`
        )
        .addFields(
          { name: "Mode", value: modeLabel, inline: true },
          { name: "Perubahan", value: changeLabel, inline: true },
          { name: "Terikat Saat Ini", value: `${currentHwids.length} akun`, inline: true },
          { name: "Admin", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setFooter({ text: "License Manager • /resethwid untuk reset binding akun" })
        .setTimestamp(),
    ],
  });
}
