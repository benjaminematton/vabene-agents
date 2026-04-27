# vabene-interview-recruiter

## Purpose

Close the gap between qualified leads (from `vabene-interview-finder` and optionally `vabene-reddit-monitor`) and processed transcripts (from `vabene-discovery-synthesis`). Today the middle (drafting personalized invites, tracking who's been contacted/replied/scheduled, gift-card delivery, stalled-thread follow-ups) is manual and untracked — leads rot in MEMORY.md.

The recruiter drafts comment-first then DM Reddit outreach (always for human dispatch — never auto-sends), tracks state via `recruit-status <id> <state>` Telegram commands, and pings Ben when threads stall.

## Inputs / outputs

- **Reads:** `{baseDir}/MEMORY.md` for `interview-finder` (and optionally `reddit-monitor`) entries with `outcome: "pending"`. Cross-skill dedup via deterministic `lead_id = sha256(normalized_url)[:12]` — same URL surfaced by both upstream skills produces one drafted invite.
- **Writes:**
  - One Telegram message per state transition (comment draft, DM draft, stalled nudge, day-before refresher, transcript-drop reminder, empty-sweep heartbeat).
  - Append-only JSONL entries to `{baseDir}/MEMORY.md` with `scan: "recruiter"`, full `draft_text` on `*_drafted` states, all entries at `schema_version: "0.1"`.

## Inputs (lead sources)

Upstream skills:

- `vabene-interview-finder` (primary)
- `vabene-reddit-monitor` (optional; same `lead_id` dedup contract)

Last reviewed: 2026-04-26

## Qualifiers / triggers

State machine: `pending → comment_drafted → commented → engaged → dm_drafted → dm_sent → (replied | scheduled | interviewed | declined | ghosted | gift_sent)`. Override `recruit-status <id> skip-comment` jumps `pending → dm_drafted` for sub-allowed DM-direct leads.

DM drafts must include three consent elements (recording disclosure, use-of-data sentence, opt-out language) — the agent self-checks and regenerates if any are missing instead of dispatching to Telegram. Comment-first is the default Reddit path because cold-DMs without prior thread engagement land badly even when permitted.

Stalled-thread sweep at 5d (daily 9:30 PT, deferred cron). Heartbeat Telegram on empty sweeps. See [`SKILL.md`](SKILL.md) for the full state machine, MEMORY.md schema, and Telegram message formats.

## Change log

- **2026-04-26 — v0.1.0** *(initial)*: scaffold per Plan v3. State machine extended for comment-first Reddit pattern (research showed cold-DM is hostile on Reddit; better to comment first, DM after engagement). Mandatory three-element consent block on DM drafts with self-check regeneration. Cross-skill `lead_id` dedup contract: deterministic `sha256(normalized_url)[:12]` shared with `interview-finder` and `reddit-monitor`. Voice: first-person founder pre-PMF. Pinned MEMORY.md schema at `schema_version: "0.1"` — append-only state-transition log, never edit-in-place. `INTERVIEW_INCENTIVE_USD` env var (default 25). Cron creation deferred until ≥ 3 successful runs covering all branches (comment_drafted, dm_drafted, skip-comment, stalled-sweep, cross-skill dedup).
