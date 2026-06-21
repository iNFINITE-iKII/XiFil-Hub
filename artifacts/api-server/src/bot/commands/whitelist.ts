import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { randomUUID } from "crypto";
import {
  getWhitelistUser,
  addToWhitelist,
  removeFromWhitelist,
  getAllWhitelist,
  assignKeyToUser,
  insertLicenses,
  getByKey,
} from "../database.js";
import { generateLicenseKey } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("whitelist")
  .setDescription("Kelola whitelist VIP (Admin only)")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addSubcommand((sub) =>
    sub
      .setName("add")
      .setDescription("Tambahkan user ke whitelist VIP dan beri keys")
      .addUserOption((opt) =>
        opt.setName("user").setDescription("User Discord yang akan di-whitelist").setRequired(true)
      )
      .addIntegerOption((opt) =>
        opt
          .setName("key_count")
          .setDescription("Jumlah key yang diberikan ke user")
          .setRequired(true)
          .setMinValue(1)
          .setMaxValue(50)
      )
  )
  .addSubcommand((sub) =>
    sub
      .setName("remove")
      .setDescription("Hapus user dari whitelist VIP")
      .addUserOption((opt) =>
        opt.setName("user").setDescription("User yang akan dihapus dari whitelist").setRequired(true)
      )
  )
  .addSubcommand((sub) =>
    sub.setName("list").setDescription("Lihat semua user yang ada di whitelist VIP")
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const sub = interaction.options.getSubcommand();

  if (sub === "add") {
    const target = interaction.options.getUser("user", true);
    const keyCount = interaction.options.getInteger("key_count", true);

    const existing = await getWhitelistUser(target.id);

    const now = Date.now();
    const generatedKeys: string[] = [];

    const licenseEntries: Array<{
      id: string;
      licenseKey: string;
      durationType: string;
      durationValue: number;
      issuerDiscordId: string;
      createdAt: number;
    }> = [];

    for (let i = 0; i < keyCount; i++) {
      let key: string;
      let attempts = 0;
      do {
        key = generateLicenseKey();
        attempts++;
        if (attempts > 30) throw new Error("Key collision, coba lagi.");
      } while (await getByKey(key));

      generatedKeys.push(key);
      licenseEntries.push({
        id: randomUUID(),
        licenseKey: key,
        durationType: "PERMANENT",
        durationValue: 0,
        issuerDiscordId: interaction.user.id,
        createdAt: now,
      });
    }

    await insertLicenses(licenseEntries);

    for (const key of generatedKeys) {
      await assignKeyToUser({
        id: randomUUID(),
        discordUserId: target.id,
        licenseKey: key,
        assignedAt: now,
      });
    }

    await addToWhitelist({
      id: existing?.id ?? randomUUID(),
      discordUserId: target.id,
      discordUsername: target.username,
      keyCount: existing ? existing.key_count + keyCount : keyCount,
      addedBy: interaction.user.id,
      addedAt: now,
    });

    const keyBlock = generatedKeys.map((k) => `\`${k}\``).join("\n");

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x00c853)
          .setTitle("✅ Whitelist Berhasil")
          .setDescription(`<@${target.id}> telah ditambahkan ke whitelist VIP.`)
          .addFields(
            { name: "Jumlah Key", value: `${keyCount} key PERMANENT`, inline: true },
            { name: "Ditambahkan oleh", value: `<@${interaction.user.id}>`, inline: true },
            { name: "Keys yang Digenerate", value: keyBlock }
          )
          .setFooter({ text: "License Manager • User bisa klaim role VIP via panel" })
          .setTimestamp(),
      ],
    });
    return;
  }

  if (sub === "remove") {
    const target = interaction.options.getUser("user", true);
    const removed = await removeFromWhitelist(target.id);

    if (!removed) {
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0xff6d00)
            .setTitle("⚠️ Tidak Ditemukan")
            .setDescription(`<@${target.id}> tidak ada di whitelist VIP.`)
            .setTimestamp(),
        ],
      });
      return;
    }

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("🗑️ Whitelist Dihapus")
          .setDescription(`<@${target.id}> telah dihapus dari whitelist VIP.`)
          .addFields({ name: "Dihapus oleh", value: `<@${interaction.user.id}>`, inline: true })
          .setTimestamp(),
      ],
    });
    return;
  }

  if (sub === "list") {
    const list = await getAllWhitelist();

    if (list.length === 0) {
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0x2196f3)
            .setTitle("📋 Whitelist VIP")
            .setDescription("Belum ada user yang di-whitelist.")
            .setTimestamp(),
        ],
      });
      return;
    }

    const rows = list
      .slice(0, 25)
      .map(
        (e, i) =>
          `**${i + 1}.** <@${e.discord_user_id}> — ${e.key_count} keys — VIP: ${e.vip_role_assigned ? "✅" : "❌"}`
      )
      .join("\n");

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x2196f3)
          .setTitle(`📋 Whitelist VIP (${list.length} user)`)
          .setDescription(rows)
          .setFooter({ text: "License Manager" })
          .setTimestamp(),
      ],
    });
  }
}
