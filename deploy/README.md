# deploy/

Operational notes for running the openclaw host.

## Current host

Laptop, reachable via Tailscale at `macbookpro.<your-tailnet>.ts.net`.

## SSH

```bash
ssh bmatton@macbookpro.<your-tailnet>.ts.net
```

Note: the host uses the `bmatton` account, not `benjaminmatton` (which is the dev machine). Tailscale handles routing — no IP fiddling, no port forwarding.

## Host bootstrap checklist (for a new machine, e.g. a DigitalOcean droplet)

1. Install Node 20+ (`nvm install 20` or distro package)
2. Install the openclaw CLI (`npm i -g openclaw` or whatever the current install path is)
3. Set environment:
   - `ANTHROPIC_API_KEY` — Claude API key
   - Telegram bot token (in openclaw config or env, per CLI docs)
   - Telegram chat id for delivery
4. Install the cron daemon:
   - macOS: a LaunchDaemon plist that runs `openclaw cron daemon`
   - Linux: a systemd unit doing the same
5. Clone this repo: `git clone git@github.com:benjaminematton/vabene-agents.git ~/Developer/vabene-agents`
6. Run `cd ~/Developer/vabene-agents && ./deploy.sh` — symlinks skills into `~/.openclaw/skills/`
7. Re-create cron jobs from `crons/jobs.example.json` via `openclaw cron create ...` (substituting real chat id)
8. Verify: `openclaw cron list` should show all three jobs

The bootstrap is intentionally not automated — it touches secrets and platform-specific daemons. Do it once per host, by hand, with this checklist.

## Trajectory

- **Today:** host = the laptop. Convenient because it's where everything was originally set up.
- **Soon:** host = a small DigitalOcean droplet. Decouples agent uptime from laptop being awake/online and reduces the blast radius of "I closed my laptop and the leads stopped flowing."

The repo abstracts the host away — that's the whole point. Migrating means: spin up droplet → run the bootstrap checklist above → tear down the laptop's LaunchDaemon. Skills, crons, and prompts all come from this repo.

## Future tooling

Once `deploy.sh`, `sync-from-host.sh`, and a future `validate.sh` (lints SKILL.md frontmatter) are stable, consider a `Makefile` or `justfile` so the commands are `make deploy` / `just sync` instead of remembering script names. Not worth the indirection until there are 4+ scripts.
