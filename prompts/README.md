# prompts/

Inline prompts that aren't full skills — i.e., one-shot prompts passed directly to a cron job's `payload.message` rather than referencing a skill.

## Convention

One file per cron, named after the cron's purpose (not the cron id, since ids are opaque):

- `lead-digest.md` — Lead Digest cron (id `7d4260c7-9f21-4c62-a171-2ef2c39dfa7f`); summarizes the previous day's Reddit lead activity from MEMORY.md

## When to use a prompt vs a skill

- **Prompt** (here): single one-shot instruction, no reusable knowledge, no slash-command surface. The cron's `payload.message` is the whole thing.
- **Skill** (under `skills/`): reusable, may be invoked from multiple contexts (cron + interactive sessions), benefits from the `SKILL.md` frontmatter / file-loading machinery.

The Lead Digest is a prompt because it's just "summarize yesterday's MEMORY.md" — no reusable logic. The Reddit monitor and interview finder are skills because they encode strategy (which subreddits, what qualifiers) that we iterate on independently.
