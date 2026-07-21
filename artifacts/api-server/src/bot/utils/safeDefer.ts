import {
  ChatInputCommandInteraction,
  ButtonInteraction,
  ModalSubmitInteraction,
} from "discord.js";
import { logger } from "../../lib/logger.js";

type DeferrableInteraction =
  | ChatInputCommandInteraction
  | ButtonInteraction
  | ModalSubmitInteraction;

/**
 * Safely calls deferReply and returns true on success.
 *
 * Returns false (without throwing) when the interaction has already expired
 * (Discord error 10062 "Unknown Interaction"). This happens when Discord's
 * 3-second acknowledgement window has passed — usually because the server
 * was under load or cold-starting.
 *
 * Callers should guard the rest of the handler:
 *   if (!await safeDefer(interaction)) return;
 */
export async function safeDefer(
  interaction: DeferrableInteraction,
  options: { ephemeral?: boolean } = { ephemeral: true }
): Promise<boolean> {
  try {
    await interaction.deferReply(options);
    return true;
  } catch (err) {
    const code = (err as { code?: number })?.code;
    if (code === 10062) {
      logger.warn(
        { interactionId: interaction.id },
        "safeDefer: interaction expired (10062) — skipping handler"
      );
      return false;
    }
    // Any other error (bad token, network, etc.) — re-throw so the caller's
    // catch block can log it properly.
    throw err;
  }
}
