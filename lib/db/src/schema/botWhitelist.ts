import { pgTable, text, integer, boolean, bigint } from "drizzle-orm/pg-core";

export const botWhitelistTable = pgTable("whitelist", {
  id: text("id").primaryKey(),
  discord_user_id: text("discord_user_id").notNull().unique(),
  discord_username: text("discord_username").notNull(),
  key_count: integer("key_count").notNull().default(1),
  vip_role_assigned: boolean("vip_role_assigned").notNull().default(false),
  added_by: text("added_by").notNull(),
  added_at: bigint("added_at", { mode: "number" }).notNull(),
});

export type WhitelistEntry = typeof botWhitelistTable.$inferSelect;
