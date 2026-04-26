# vabene-agents

Version-controlled source of truth for VaBene's agent infrastructure: openclaw skills, cron jobs, and inline prompts that drive the Reddit lead monitor, lead digest, and interview finder.

## Two-machine workflow

```
Machine A (dev laptop, this repo's working copy): edit, commit, push
Machine B (openclaw host, currently the other laptop; later a DO droplet): pull, run ./deploy.sh, test
```

The repo abstracts the host away — that's the whole point. Edits never happen by `nano`-ing skill files in `~/.openclaw/`; they happen here, get committed, and propagate via `git pull && ./deploy.sh` on the host.

## What's currently live

Three openclaw cron jobs run on the host:

- **Reddit Scan** — id `398290ae-3b3c-4b62-b89e-594cadf21916`, backed by the `vabene-reddit-monitor` skill
- **Lead Digest** — id `7d4260c7-9f21-4c62-a171-2ef2c39dfa7f`, no skill (inline prompt; lives in `prompts/lead-digest.md`)
- **Interview Finder** — id `fc20c038-32aa-4d20-a310-f8469453f5b5`, backed by the `vabene-interview-finder` skill

Skill source-of-truth lives under `skills/<skill-name>/`. `deploy.sh` symlinks each subdirectory into `~/.openclaw/skills/` on the host.

## Change workflow

1. Edit on dev (`skills/vabene-reddit-monitor/SKILL.md`, `prompts/lead-digest.md`, etc.)
2. `git commit -m "..."` with rationale in the body, push
3. SSH to host: `ssh bmatton@macbookpro.<your-tailnet>.ts.net`
4. `cd ~/Developer/vabene-agents && git pull && ./deploy.sh`
5. Test (see below)
6. Update the skill's `README.md` change log on dev with the date and what changed

## Test loop (paste-ready, run on the host)

```bash
# Trigger a one-off run
openclaw cron run --id 398290ae-3b3c-4b62-b89e-594cadf21916

# Watch Telegram for output, then check the run record
openclaw cron runs --id 398290ae-3b3c-4b62-b89e-594cadf21916 --limit 1
```

Substitute the cron id for whichever job you're testing.

## Bringing up a new host

See [`deploy/README.md`](deploy/README.md) for the host bootstrap checklist (Node, openclaw CLI, env vars, LaunchDaemon, clone, deploy).

## Scope

This repo is **agent-infra strategy only**: skills, crons, prompts, agent-side rationale. Broader VaBene product strategy (positioning, "celebration not bachelorette," self-hosting birthday celebrant in SF, Rule of One) lives in `~/Developer/EventPlanning/` and is referenced from there, not duplicated here. Avoiding drift means keeping that line firm — if a strategy decision is about how the product is positioned, it goes in EventPlanning. If it's about how an agent decides what to flag or skip, it goes here.
