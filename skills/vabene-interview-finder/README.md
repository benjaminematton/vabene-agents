# vabene-interview-finder

## Purpose

Surface Reddit users who are actively experiencing celebration-planning pain and would be valuable JTBD interview candidates. Draft a personalized outreach DM for each and send to Telegram for manual review and sending. Never messages anyone on Reddit automatically.

Sibling skill to [`vabene-reddit-monitor`](../vabene-reddit-monitor/) — different goal: this skill finds **research candidates to DM privately**; reddit-monitor finds **leads to reply to publicly**. A post can qualify for both; the outputs go to different Telegram message formats.

## Inputs / outputs

- **Reads:** Reddit posts via the openclaw-shipped `reddit-readonly` scraper. Two-strategy fetch (per [`SKILL.md`](SKILL.md) Step 1): Strategy A browses recent posts in small high-signal subs and searches within high-volume subs; Strategy B searches r/all for pain-language queries. Window: last 7 days (interview candidates are good for longer than promotional leads).
- **Writes:** One Telegram message per qualifying candidate (score ≥3/6) with the post link, score breakdown, and a drafted personalized DM. Appends scan summary to MEMORY.md after each run.

## Subreddits scanned

Primary (every run, pain language): r/BachelorettePlanning, r/weddingplanning, r/AskWomen, r/AskWomenOver30
Secondary (every other run, broader pain): r/wedding, r/Parenting, r/Mommit, r/travel, r/relationships, r/TwoXChromosomes
Plus r/all pain-keyword queries each run.

Last reviewed: 2026-04-26

## Qualifiers / triggers

0–6 scoring rubric — see [`SKILL.md`](SKILL.md) "What Makes Someone Worth Interviewing" for the full rubric. Components: +1 each for high-severity pain, identifiable trigger event, named workaround, bad outcome, wish statement, detailed post (150+ words). Minimum to surface: 3/6.

When this skill gets its rewrite (deferred — see plan), the scoring scale should be unified with reddit-monitor's two-axis numeric system for consistency across the two skills.

## Change log

- **2026-04-26 — v1.0.1** *(commit 52fea6d)*: dropped r/Bachelorette (TV show), r/MaidOfHonor + r/GirlsTrip (banned), r/birthdays (celebration-of-self) from primary subs. Narrowed Strategy A `for` loop to BachelorettePlanning only (other subs in loop were dead). Added TV-show keyword exclusions (Gabby Windey, Jenn Tran, rose ceremony, etc.) and a comment in Strategy B noting the qualification step is the real filter for r/all results. Shared cleanup commit with reddit-monitor.
- **2026-04-26 — v1.0.0 promoted** *(commit 38dc3b6)*: substantive Step 1 fetch-strategy rewrite became live. Replaced single `find` call with two-strategy approach: Strategy A (per-sub `posts --sort new --limit 25` for small high-signal subs + per-sub `search` for high-volume subs); Strategy B (3 r/all pain-keyword queries). Added explicit 7-day age filter. Refactor only — no further behavior changes. The rewrite content had been orphaned in a nested `vabene-interview-finder/vabene-interview-finder/` directory on the host since 2026-04-24, never loaded by openclaw because it loads `<skill-dir>/SKILL.md` not `<skill-dir>/<skill-dir>/SKILL.md`. Promote-to-live unblocks the iteration that was silently discarded for two days.
- **2026-04-26 — v1.0.0 (baseline)** *(commit 8d00158)*: imported verbatim from openclaw host. Pre-repo iteration history is not preserved — versioning starts here.
