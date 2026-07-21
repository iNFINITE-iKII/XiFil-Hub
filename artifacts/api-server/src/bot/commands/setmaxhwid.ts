import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, setMaxHwidResets } from "../database.js";
import { censorKey } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("setmaxhwid")
  .setDescription("Set batas reset HWID dan periode cooldown untuk sebuah key — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("License key yang akan diubah").setRequired(true)
  )
  .addIntegerOption((opt) =>
    opt
      .setName("max")
      .setDescription("Jumlah maksimal reset per periode (-1 = unlimited)")
      .setRequired(true)
      .setMinValue(-1)
      .setMaxValue(999)
  )
  .addStringOption((opt) =>
    opt
      .setName("period")
      .setDescription("Seberapa sering user bisa reset (default: Per Minggu)")
      .setRequired(false)
      .addChoices(
        { name: "Per Hari (1x/24jam)", value: "DAILY" },
        { name: "Per Minggu (1x/7hari)", value: "WEEKLY" },
        { name: "Per Bulan (1x/30hari)", value: "MONTHLY" },
        { name: "Tidak Ada Cooldown", value: "UNLIMITED" }
      )
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.get("key")?.value as string).trim().toUpperCase();
  const max = interaction.options.get("max")?.value as number;
  const period = (interaction.options.get("period")?.value as string) ?? "WEEKLY";

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

  await setMaxHwidResets(key, max, period);

  const periodLabel: Record<string, string> = {
    DAILY: "Per Hari (1x/24jam)",
    WEEKLY: "Per Minggu (1x/7hari)",
    MONTHLY: "Per Bulan (1x/30hari)",
    UNLIMITED: "Tidak Ada Cooldown",
  };

  const maxLabel = max === -1 ? "**Unlimited**" : `**${max}x** per periode`;

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ Pengaturan Reset HWID Diupdate")
        .setDescription(`Pengaturan reset HWID untuk key \`${censorKey(key)}\` telah diubah.`)
        .addFields(
          { name: "Batas Reset", value: maxLabel, inline: true },
          { name: "Periode", value: periodLabel[period] ?? period, inline: true },
          { name: "Reset Sudah Dilakukan", value: `${license.hwid_reset_count}x`, inline: true },
          { name: "Admin", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setFooter({ text: "License Manager" })
        .setTimestamp(),
    ],
  });
}
