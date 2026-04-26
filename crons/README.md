# crons/

This directory holds **manual snapshots** of the openclaw cron config — not the source of truth.

The live config lives at `~/.openclaw/cron/jobs.json` on the host and changes whenever you run `openclaw cron edit ...`. This repo's copy can drift.

## Files

- `jobs.json` — raw snapshot from the host. **Gitignored** — contains real Telegram chat IDs and bot tokens.
- `jobs.example.json` — sanitized version (chat IDs and tokens replaced with `<TELEGRAM_CHAT_ID>` / `<TELEGRAM_BOT_TOKEN>` placeholders). Safe to commit. This is the file other people (or future-you on a new host) reference when reconstructing the cron setup.

## Refreshing the snapshot

On the host:

```bash
cd ~/Developer/vabene-agents
./sync-from-host.sh
git diff crons/jobs.example.json
# Verify: grep -F "<YOUR_CHAT_ID>" crons/jobs.example.json should return nothing
git add crons/jobs.example.json
git commit -m "chore: refresh cron snapshot"
git push
```

If the grep finds anything, do **not** commit — extend the sed pipeline in `sync-from-host.sh` first.

## Reconstructing crons on a new host

Read `jobs.example.json` to get the schedules and prompts, then re-create each job with `openclaw cron create ...` using your real chat ID. There's no `openclaw cron import` (yet); this is manual.
