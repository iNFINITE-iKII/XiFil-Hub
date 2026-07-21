import { pgTable, text, bigint, unique } from "drizzle-orm/pg-core";

export const licenseHwidsTable = pgTable("license_hwids", {
  id: text("id").primaryKey(),
  license_key: text("license_key").notNull(),
  hwid_hash: text("hwid_hash").notNull(),
  bound_at: bigint("bound_at", { mode: "number" }).notNull(),
}, (table) => [
  unique().on(table.license_key, table.hwid_hash),
]);

export type LicenseHwid = typeof licenseHwidsTable.$inferSelect;
