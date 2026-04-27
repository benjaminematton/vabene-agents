# vabene-discovery-synthesis

## Purpose

Turn raw customer interview transcripts into structured JTBD insights via a draft-then-refine loop. Per-transcript extraction surfaces Forces of Progress (Push / Pull / Anxiety / Habit) plus verbatim quotes; a weekly aggregate pass produces candidate opportunities for the Opportunity Solution Tree.

The bottleneck this is built around: teams complete JTBD interviews, recordings sit in a shared drive, insights never reach a product decision. AI draft + human refinement beats either alone — Ben catches things the model misses (and vice versa). Auto-commit of un-refined drafts always carries an audit flag.

## Inputs / outputs

- **Reads:** transcript files at `~/.openclaw/agents/main/transcripts/*.md` and `*.txt`. Excludes `*.draft.md` and `*.refined.md`. Read-only — never modifies or deletes the source. Recommended source: Otter or Granola Markdown export. Filename convention: `YYYY-MM-DD-<participant-handle>.md`.
- **Writes:**
  - AI drafts to `<TRANSCRIPTS_DIR>/<id>.draft.md` (sibling files; never replaces the source).
  - One Telegram message per state transition (draft ready, refined commit, auto-commit-unreviewed, weekly aggregate).
  - JSONL entries to `{baseDir}/MEMORY.md` with `scan` in `discovery-synthesis`, `discovery-opportunities`, `synthesis-warn`. All entries carry `schema_version: "0.1"`.

## Inputs (transcripts)

Watched directory: `~/.openclaw/agents/main/transcripts/`

Last reviewed: 2026-04-26

## Qualifiers / triggers

State machine per transcript: `new → drafted → (refined | committed-unreviewed)`. Default stale-after = 168h (7d); `SYNTH_STALE_AFTER_HOURS` env var or `--simulate-stale-after <hours>` flag overrides for testing.

Verbatim quotes validate against the normalized source (strip bracket annotations, collapse whitespace, lowercase, then exact-substring; fall back to Levenshtein ≥ 0.85 with `quote_match: "fuzzy"` flag; below 0.85 → drop quote, log warn).

Weekly aggregate (Sundays 10am PT) excludes `committed-unreviewed` entries by default. Override via `weekly opportunities --include-unreviewed`. See [`SKILL.md`](SKILL.md) "Aggregate pass" for the opportunity schema and Telegram format.

## Change log

- **2026-04-26 — v0.1.0** *(initial)*: scaffold per Plan v3. Two-phase HITL synthesis (AI draft → Ben refines via `<id>.refined.md` → canonical commit). Pinned per-transcript and per-opportunity JSONL schemas at `schema_version: "0.1"`. Verbatim quote validation with normalization rule + fuzzy fallback at 0.85 ratio. Aggregate excludes `committed-unreviewed` by default; `--include-unreviewed` opt-in tracks `derived_from_unreviewed` + `unreviewed_count` on opportunity entries. `SYNTH_STALE_AFTER_HOURS` / `--simulate-stale-after` test overrides. Heartbeat on empty weeks. Cron creation deferred until ≥ 3 successful runs per state path.
- Schema v0.1 will likely need a v0.2 rework after the first 2–3 real SF self-host celebrant transcripts. Imminent-interviews timing accepted that trade-off rather than scaffolding ahead of data.
