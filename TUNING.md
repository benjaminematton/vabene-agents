# TUNING.md

How we iterate on VaBene agent skills. Read this before changing any `SKILL.md`.

## What's automatic vs manual

**Automatic:** crons fire, scans run, JSONL is appended to `~/.openclaw/agents/main/memory/MEMORY.md`, leads delivered to Telegram. That's it.

**Manual:** every behavior change. Skills don't self-tune. The agent doesn't adjust its own keywords, weights, or sub list based on its own runs. Humans decide what to change, write the edit, commit, deploy.

This is intentional. Self-modifying skills are hard to reason about and easy to break. Trust beats velocity.

## Cadence

### Days 1–14 after a major skill change: silence

Don't tune anything. JSONL accumulates. You eyeball Telegram leads, jot mental thumbs-up/down per lead, but write no commits.

A quiet week is not a regression — the qualifier filtering noise is its job. A noisy week is more concerning, but still wait it out unless the **ceiling is breached** (any single run > 6 leads, or a daily average > 4).

### Day 14: deliberate review (~10 min)

Pull MEMORY.md, run the jq snippets below, judge.

Decision tree:
- **Floor unmet** (no HIGH/MED in 14d) → lower HIGH score floor in SKILL.md (4 → 3) as the first move. Don't expand the sub list.
- **Ceiling exceeded** → raise HIGH score floor (4 → 5), or expand hard-exclusion keywords if the false-positive pattern is specific (e.g., wedding-day-of pain that doesn't fit VaBene's market: "ceremony to reception", "kids/no kids", "officiant").
- **Quality forced** (leads pass scoring but you wouldn't reply) → tune templates or qualifier, not the sub list. The sub list is the **last** lever, not the first.

### After day 14: trigger-driven, Lead Digest as forcing function

The daily Lead Digest (8:30 AM PT) is your automatic weekly review. When it surfaces a concrete pattern you'd act on ("last 5 runs all 0 leads," "r/X dominates signal but produces low-quality leads"), that's the trigger to write a tuning commit. Otherwise leave the system alone.

**One tuning commit per week max.** Easier to attribute regression. Easier to revert.

## Tuning levers (priority order)

When you decide to tune, pick the highest-priority lever that addresses the issue. Don't combine.

1. **HIGH score floor** — single biggest knob. Currently 4. Raise to 5 if noisy, lower to 3 if quiet.
2. **Hard exclusion list** — add kill-words when a category of false positive surfaces.
3. **Include keyword coverage** — if real leads slip through with no score signal, the include list is missing keywords.
4. **Sub list** — last resort. Add or remove subs based on 2-week yield data, not gut feel.
5. **Score component weights** — only when 1–4 don't work. Document the *why* in the SKILL.md change log; weights are easy to fiddle and hard to reason about retroactively.

## The 2-minute review workflow

On the openclaw host (`ssh macbookpro`):

```bash
MEM=~/.openclaw/agents/main/memory/MEMORY.md

# Reddit Scan summary, last ~7 days
tail -200 "$MEM" | jq -s '
  map(select(.scan == "reddit-monitor"))
  | {runs:             length,
     total_qualifying: (map(.qualifying) | add),
     total_high:       (map(.high)       | add),
     total_med:        (map(.med)        | add),
     avg_per_run:     ((map(.qualifying) | add) / length),
     max_run:          (map(.qualifying) | max)}'
```

Use it to check the success bar:
- **Floor**: `total_high + total_med >= 1` over the window
- **Ceiling**: `avg_per_run <= 4` AND `max_run <= 6`
- **Quality**: open Telegram, scroll back through the last week's leads, count "would I actually reply" against total. <60% = qualifier or templates need work.

**Subreddit yield breakdown** (which subs actually produce qualifying leads — the input to lever #4):

```bash
tail -200 "$MEM" | jq -s '
  map(select(.scan == "reddit-monitor") | .subreddit_yield)
  | reduce .[] as $r ({};
      reduce ($r | to_entries[]) as $e (.;
        .[$e.key].f = ((.[$e.key].f // 0) + $e.value.f)
        | .[$e.key].q = ((.[$e.key].q // 0) + $e.value.q)))
  | to_entries | sort_by(.value.q) | reverse'
```

**Trigger-pattern yield** (which keyword combos actually convert — the input to lever #3):

```bash
tail -200 "$MEM" | jq -s '
  map(select(.scan == "reddit-monitor") | .trigger_pattern_yield)
  | reduce .[] as $r ({};
      reduce ($r | to_entries[]) as $e (.;
        .[$e.key] = ((.[$e.key] // 0) + $e.value)))
  | to_entries | sort_by(.value) | reverse'
```

## Rollback playbook

Every tuning commit:
- Uses Conventional Commits: `fix(reddit-monitor): ...`, `refactor(interview-finder): ...`, `feat(reddit-monitor)!: ...` for breaking
- Has a body explaining **why** — not what (the diff shows what)
- Touches **one** SKILL.md (or one SKILL.md plus its README change log; don't bundle multiple skills)

To roll back a single tuning that made things worse:
```bash
# On dev:
git revert <hash>
git push

# On host:
cd ~/Developer/vabene-agents && git pull && ./deploy.sh
```

The symlink architecture means the next cron tick after `git pull` runs the reverted skill — no daemon restart needed.

## When to update this doc

Update TUNING.md when:
- The cadence changes (longer windows, more frequent reviews, etc.)
- A new tuning lever appears (e.g., per-sub max-results becomes a knob)
- The jq snippets break because MEMORY.md schema evolved
- A specific failure mode happens often enough to warrant a pre-written response (add a "common patterns" appendix)

Don't update for one-off observations — those go in the SKILL.md change log.
