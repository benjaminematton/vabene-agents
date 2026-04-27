# vabene-reddit-monitor

## Purpose

Find Reddit posts where a real person is doing the planning labor for a group celebration and is stuck. Draft a planner-pain-framed reply for each qualifying post and surface to Telegram for manual approval. Never posts to Reddit automatically.

The user we serve is the **planner-friend** — the one who got handed the to-do list and is going to be the one who books. Replies should speak to coordination pain, not activity discovery.

## Inputs / outputs

- **Reads:** Reddit posts via the openclaw-shipped `reddit-readonly` scraper (`~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs`). Window: last 36 hours. Multiple `find` calls per run, batched to ≤4 subs each. See [`SKILL.md`](SKILL.md) for the full fetch architecture.
- **Writes:** One Telegram message per qualifying post (HIGH or MED tier) to the configured chat, formatted as a lead card with score breakdown + draft reply text. Stays silent on 0-lead runs (Lead Digest cron handles daily summaries). Appends scan summary + trigger-pattern yield to MEMORY.md after each run.

## Subreddits scanned

Tier 1 (every run, SF-first): r/SanFrancisco, r/AskSF, r/bayarea
Tier 2 (every other run): r/LosAngeles, r/AskLosAngeles, r/Nashville, r/LasVegas, r/Austin, r/Scottsdale
Tier 3 (every run, low-volume working planning subs): r/BachelorettePlanning, r/weddingplanning
Tier 4 (every other run, strict filter): r/AskWomen, r/AskWomenOver30, r/travel

Banned/dead/wrong (do NOT scan): r/Bachelorette (TV show), r/MaidOfHonor, r/GirlsTrip, r/Bridesmaid, r/dirtythirty, r/birthdays (celebration-of-self), r/turning30. See [`SKILL.md`](SKILL.md) "Banned, dead, or wrong" section for rationale per sub.

Last reviewed: 2026-04-26

## Qualifiers / triggers

Two-axis numeric scoring, with hard exclusions running pre-scoring (vendor, TV-show, ceremony-logistics terms — kill the lead outright regardless of other signals).

Score components:
- +2 celebration trigger (birthday, milestone, bach, group trip, baby shower, engagement, anniversary, reunion, etc.)
- +2 coordination-pain phrase ("I'm planning," "trying to coordinate," "drowning in options," "haven't booked," etc.)
- +1 explicit group size ≥3
- +1 decision-pending language
- +1 SF or SF-adjacent
- −2 soft penalty for gray terms (drama, registry, ceremony order, etc.)

Tiers: HIGH ≥4, MED 2–3, excluded <2. The math allows one-axis HIGH if there's enough corroborating signal (e.g. celebration + group + SF = 4 = HIGH); raise the HIGH floor to 5 to restore strict two-axis. See [`SKILL.md`](SKILL.md) "Two-axis scoring" for the full rubric and worked examples.

## Change log

- **2026-04-26 — v2.1.0**: schema-only addition for cross-skill recruiter consumption. **Behavior unchanged** — same tier composition, same scoring, same keyword lists, same Telegram dispatch. New: per-lead JSONL entries written alongside per-run summary, each carrying `schema_version: "0.1"`, deterministic `lead_id` (sha256 of normalized URL, first 12 hex chars — cross-skill contract with interview-finder and interview-recruiter), and `outcome: "pending"` so the recruiter can pick them up. Per-run summary `scan` renamed `"reddit-monitor"` → `"reddit-monitor-run"` so per-lead and per-run queries don't collide; `lead stats` jq query accepts both for backward compatibility with pre-v2.1.0 entries. Wedding-day persona drift from the 2026-04-26 18:00 PT v2.0.1 run (3/4 HIGH leads on r/weddingplanning were wedding-day-execution pain rather than VaBene-market coordination) explicitly NOT addressed in this commit — letting v2.0.1 bake 48h before tuning per protocol; revisit only if pattern persists.
- **2026-04-26 — v2.0.1** *(commit 5076a21)*: hardening pass on v2.0.0. No behavior-model changes; surface-area fixes against silent failures and fragile heuristics. Added Prerequisites section + Step 1 existence check for the `reddit-readonly` cross-skill dependency (was producing zero leads silently if missing). Switched memory format from prose to JSONL with explicit schema so `lead stats` parses with `jq` instead of regex over text. Replaced fragile "The Bachelorette" capitalization heuristic with `bachelornation` + `episode \d+` / `season \d+` / `ep \d+` regex patterns. Replaced hand-wavy "every other run" prose with explicit hour-based branching (Tier 2 runs at hours {8,12,16,20}, Tier 4 at {10,14,18,22}). Switched all node-call paths to a `$SCRAPER` variable defined once at top of Step 1. Defined `{baseDir}/MEMORY.md` path explicitly throughout. Replaced manual-command bullet list with a 3-column table. Softened the security PII claim (titles + permalinks are still soft-PII via Reddit UI). Led the decision-pending rubric line with rationale (the dual-counting with the pain axis is intentional — highest VaBene-fit signal). Tightened MILESTONE BIRTHDAY and GROUP TRIP templates from 4 to 3 sentences. Dropped sloppy `/7+` score notation (max really is 7). Dropped dead `python_packages: requests` declaration. Deferred: openclaw frontmatter restructure into `metadata.openclaw` (parser ignores unrecognized fields harmlessly; matters only for ClawHub publish).
- **2026-04-26 — v2.0.0** *(commit 95f2b2c, breaking)*: major rewrite. Architecture inverted to city-sub-first (4 tiers); qualifier reworked from single-axis HIGH/MED/LOW priority labels to two-axis numeric scoring with hard exclusions; voice rewritten from activity-discovery framing to planner-pain framing across 6 templates; per-call max-4-subs batching with retry-without-failing-sub; MEMORY.md schema gains trigger-pattern yield field; new manual triggers (`scan sf`, `scan birthdays`, `scan trips`, `scan bach`). Reasoning: planning-specific subs are too low-volume after Reddit bans to be primary signal source; city subs filtered for celebration intent are the actual lead source. SF-first weighting per VaBene business strategy (SF launch market, supply-first thesis).
- **2026-04-26 — v1.3.1** *(commit 52fea6d)*: dropped r/Bachelorette (TV show, not planning), r/MaidOfHonor + r/Bridesmaid + r/GirlsTrip (banned by Reddit), r/birthdays (celebration-of-self, not planning-for) from primary subs. Added defensive TV-show keyword exclusions (Gabby Windey, Jenn Tran, rose ceremony, etc.) for crossposted/leaked content. Removed `scan moh` and `find bachelorette posts` triggers. Verified against Reddit 2026-04-26 — banned subs return errors, r/Bachelorette top posts are TV gossip.
- **2026-04-26 — v1.3.0 (baseline)** *(commit 8d00158)*: imported verbatim from openclaw host. Pre-repo iteration history is not preserved — versioning starts here.
