import { pgTable, text, bigint } from "drizzle-orm/pg-core";

export const hwidResetLogTable = pgTable("hwid_reset_log", {
  id: text("id").primaryKey(),
  discord_user_id: text("discord_user_id").notNull(),
  license_key: text("license_key").notNull(),
  reset_at: bigint("reset_at", { mode: "number" }).notNull(),
});

export type HwidResetLog = typeof hwidResetLogTable.$inferSelect;
