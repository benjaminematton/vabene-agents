# skills/

One subdirectory per openclaw skill. The directory name **is** the skill name as referenced by openclaw (e.g. `vabene-reddit-monitor`).

## Convention

Each skill subdirectory must contain:

- `SKILL.md` — the file openclaw loads
- `README.md` — rationale and change log, following [`_TEMPLATE_README.md`](_TEMPLATE_README.md)

Files at the `skills/` level (this README, the template) are **not** deployed — `deploy.sh` only iterates subdirectories of `skills/`, so you never end up symlinking a template into `~/.openclaw/skills/`.

## Decompose when natural

If a skill's logic decomposes — separable subreddit list, qualifier rules, draft templates, etc. — put each piece in its own file in the skill directory and have `SKILL.md` reference them. This lets you A/B a single component (say, a new qualifier) without rewriting the whole skill, and makes diffs of behavioral changes much more readable.

For example:

```
skills/vabene-reddit-monitor/
├── SKILL.md          # Orchestration + glue
├── README.md         # Rationale + change log
├── subreddits.md     # Curated list, last-reviewed date
├── qualifiers.md     # Two-axis rules: celebration trigger × coordination pain
└── templates.md      # DM/comment draft templates
```
