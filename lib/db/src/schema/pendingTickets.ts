import { pgTable, text, bigint } from "drizzle-orm/pg-core";

export const pendingTicketsTable = pgTable("pending_tickets", {
  discord_user_id: text("discord_user_id").primaryKey(),
  channel_id: text("channel_id").notNull(),
  message_id: text("message_id").notNull(),
  created_at: bigint("created_at", { mode: "number" }).notNull(),
});

export type PendingTicket = typeof pendingTicketsTable.$inferSelect;
