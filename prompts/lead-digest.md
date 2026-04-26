# lead-digest

Inline prompt used by the **VaBene Lead Digest** cron job.

- Cron id: `7d4260c7-9f21-4c62-a171-2ef2c39dfa7f`
- Schedule: `30 8 * * *` America/Los_Angeles (daily at 8:30am PT)
- Delivery: Telegram

## Prompt

```
Summarize yesterday's VaBene Reddit lead monitoring from MEMORY.md: posts found, top subreddits, patterns. Max 6 lines.
```

## Notes

This is a one-shot prompt passed directly via the cron's `payload.message`, not a skill. It runs after the Reddit Scan cron's overnight passes (Reddit Scan runs at 08, 10, 12, 14, 16, 18, 20, 22 PT) so the digest reads fresh data.

Reads `~/.openclaw/agents/main/memory/MEMORY.md` (host-side) — the agent's own conversational memory, where the Reddit Scan accumulates lead notes.
