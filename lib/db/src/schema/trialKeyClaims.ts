import { pgTable, text, bigint } from "drizzle-orm/pg-core";

export const trialKeyClaimsTable = pgTable("trial_key_claims", {
  discord_user_id: text("discord_user_id").primaryKey(),
  license_key: text("license_key").notNull(),
  claimed_at: bigint("claimed_at", { mode: "number" }).notNull(),
});

export type TrialKeyClaim = typeof trialKeyClaimsTable.$inferSelect;
