# memory/

Placeholder. The live `MEMORY.md` lives on the host at `~/.openclaw/agents/main/memory/MEMORY.md` and is **gitignored** here — it contains lead names, phone numbers, and other PII from Reddit threads.

## If you want occasional snapshots for analysis

Scrub PII first, then save as `memory/snapshot-YYYY-MM-DD.md` (also gitignored by the `*.local.md` rule if you name it `*.local.md`, or commit explicitly if you've actually scrubbed it).

## Future

If we ever want to ship a "lead history" surface or do retrospective analysis on the lead pipeline, the right move is to extract structured data from MEMORY.md into a real database, not to commit raw snapshots here. This dir exists mostly so the path is documented.
