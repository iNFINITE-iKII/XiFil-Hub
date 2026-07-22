import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
  MessageFlags,
} from "discord.js";
import { randomUUID } from "crypto";
import { getByKey, insertLicenses } from "../database.js";
import { generateLicenseKey, durationLabel } from "../utils.js";
import { logger } from "../../lib/logger.js";

export const data = new SlashCommandBuilder()
  .setName("genkey")
  .setDescription("Generate new license key(s) — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt
      .setName("type")
      .setDescription("License duration type")
      .setRequired(true)
      .addChoices(
        { name: "Permanent (Lifetime)", value: "PERMANENT" },
        { name: "Hourly", value: "HOURLY" },
        { name: "Daily", value: "DAILY" },
        { name: "Weekly", value: "WEEKLY" }
      )
  )
  .addIntegerOption((opt) =>
    opt
      .setName("duration")
      .setDescription(
        "Duration multiplier (e.g. 12 for 12 hours). Ignored for Permanent."
      )
      .setRequired(false)
      .setMinValue(1)
      .setMaxValue(9999)
  )
  .addIntegerOption((opt) =>
    opt
      .setName("amount")
      .setDescription("Number of keys to generate (max 50)")
      .setRequired(false)
      .setMinValue(1)
      .setMaxValue(50)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  const type = interaction.options.get("type")?.value as string;
  const duration = (interaction.options.get("duration")?.value as number) ?? 1;
  const amount = (interaction.options.get("amount")?.value as number) ?? 1;

  // Validation error — reply immediately, no defer needed
  if (type !== "PERMANENT" && !interaction.options.get("duration")) {
    await interaction.reply({
      flags: MessageFlags.Ephemeral,
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Missing Parameter")
          .setDescription("You must specify a `duration` for non-permanent keys.")
          .setTimestamp(),
      ],
    }).catch(() => null);
    return;
  }

  // Fire deferReply immediately — don't await yet.
  // Key generation and DB insert run in parallel with the HTTP round-trip to Discord.
  // This maximises the chance of beating the 3-second window even under latency.
  const deferPromise = interaction.deferReply({ flags: MessageFlags.Ephemeral }).catch((err: unknown) => {
    const code = (err as { code?: number })?.code;
    logger.warn({ interactionId: interaction.id, code }, "genkey: deferReply failed");
    return null; // null = defer failed, but we still save keys
  });

  try {
    const now = Date.now();
    const entries: Array<{
      id: string;
      licenseKey: string;
      durationType: string;
      durationValue: number;
      issuerDiscordId: string;
      createdAt: number;
    }> = [];

    for (let i = 0; i < amount; i++) {
      let key: string;
      let attempts = 0;
      do {
        key = generateLicenseKey();
        attempts++;
        if (attempts > 20) throw new Error("Key collision — try again");
      } while (await getByKey(key));

      entries.push({
        id: randomUUID(),
        licenseKey: key,
        durationType: type,
        durationValue: type === "PERMANENT" ? 0 : duration,
        issuerDiscordId: interaction.user.id,
        createdAt: now,
      });
    }

    // Insert to DB — this runs regardless of whether defer succeeded
    await insertLicenses(entries);
    const keyList = entries.map((e) => e.licenseKey).join(", ");
    console.log(`[genkey] ✅ Inserted ${entries.length} key(s) into DB: ${keyList}`);
    logger.info({ keys: keyList, issuedBy: interaction.user.id }, "genkey: keys saved");

    const label = durationLabel(type, duration);
    const keyBlock = entries.map((e) => `\`${e.licenseKey}\``).join("\n");

    const embed = new EmbedBuilder()
      .setColor(0x00c853)
      .setTitle(`🔑 ${amount} Key${amount > 1 ? "s" : ""} Generated`)
      .addFields(
        { name: "Type", value: label, inline: true },
        { name: "Status", value: "🔵 UNUSED", inline: true },
        { name: "Issued by", value: `<@${interaction.user.id}>`, inline: true },
        { name: `Key${amount > 1 ? "s" : ""}`, value: keyBlock }
      )
      .setFooter({ text: "License Manager • Keys are inactive until first activation" })
      .setTimestamp();

    // Now check if defer succeeded
    const deferred = await deferPromise;
    if (deferred !== null) {
      await interaction.editReply({ embeds: [embed] });
    } else {
      // Defer expired — keys are saved but we can't reply to this interaction.
      // Keys are visible in Railway logs above.
      console.log(`[genkey] ⚠️ Interaction expired (10062) but keys were saved to DB: ${keyList}`);
    }
  } catch (err) {
    console.error("[genkey] ❌ Error during key generation/insert:", err);
    logger.error({ err }, "genkey: failed");
    const deferred = await deferPromise;
    if (deferred !== null) {
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0xd50000)
            .setTitle("❌ Error")
            .setDescription(`Failed to generate keys: ${String(err)}`)
            .setTimestamp(),
        ],
      });
    }
  }
}
