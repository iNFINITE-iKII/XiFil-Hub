import { pgTable, text, bigint, unique } from "drizzle-orm/pg-core";

export const userKeysTable = pgTable("user_keys", {
  id: text("id").primaryKey(),
  discord_user_id: text("discord_user_id").notNull(),
  license_key: text("license_key").notNull(),
  assigned_at: bigint("assigned_at", { mode: "number" }).notNull(),
}, (table) => [
  unique().on(table.discord_user_id, table.license_key),
]);

export type UserKey = typeof userKeysTable.$inferSelect;
