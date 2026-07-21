import { pgTable, text, integer, boolean, bigint } from "drizzle-orm/pg-core";

export const licensesTable = pgTable("licenses", {
  id: text("id").primaryKey(),
  license_key: text("license_key").notNull().unique(),
  duration_type: text("duration_type").notNull(),
  duration_value: integer("duration_value").notNull(),
  status: text("status").notNull().default("UNUSED"),
  hwid_hash: text("hwid_hash"),
  expires_at: bigint("expires_at", { mode: "number" }),
  issuer_discord_id: text("issuer_discord_id").notNull(),
  created_at: bigint("created_at", { mode: "number" }).notNull(),
  max_hwid_resets: integer("max_hwid_resets").notNull().default(1),
  hwid_reset_count: integer("hwid_reset_count").notNull().default(0),
  hwid_reset_period: text("hwid_reset_period").notNull().default("WEEKLY"),
  label: text("label"),
  notified_expire: boolean("notified_expire").notNull().default(false),
  max_hwid_count: integer("max_hwid_count").notNull().default(3),
});

export type License = typeof licensesTable.$inferSelect;
