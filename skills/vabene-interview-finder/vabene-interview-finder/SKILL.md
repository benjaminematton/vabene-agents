---
name: vabene-interview-finder
description: >-
  Find Reddit users worth interviewing for JTBD customer development.
  Score posts for interview-worthiness, draft personalized outreach DMs,
  and send candidates to Telegram for review. Never message anyone automatically.
version: "1.0.0"
author: ben
requires:
  tools:
    - bash
    - telegram
triggers:
  - "find interviews"
  - "find interviewees"
  - "interview scan"
  - "find people to interview"
  - "custdev scan"
  - "who should I talk to"
---

# VaBene Interview Candidate Finder

## Purpose

Surface Reddit users who are actively experiencing celebration-planning pain
and would be valuable JTBD interview candidates. Draft a personalized outreach
DM for each and send to Telegram for Ben to review and send manually.

**Hard rule: this skill NEVER messages anyone on Reddit. All outreach is
manual by the human after reviewing the Telegram draft.**

---

## What Makes Someone Worth Interviewing

Not every person complaining about party planning is a good interview.
The best candidates have multiple of these signals:

| Signal | Why It Matters | Weight |
|--------|---------------|--------|
| **Recency** (posted < 7 days) | Still in the planning cycle, will remember details | Required |
| **High severity pain** | Strong emotions = rich interview | High |
| **Identifiable trigger event** | "turning 30", "engagement" = actively planning | High |
| **Named a workaround** | "we tried Partiful", "group chat is chaos" = tried things | High |
| **Bad outcome** | "trip fell through", "it was a disaster" = strongest motivation to talk | Highest |
| **Wish statement** | "I wish there was..." = already reflecting on what should exist | Medium |
| **Detailed post** (100+ words) | Longer posts = more reflective person = better interviewee | Medium |
| **Multiple comments** | Engaged in discussion = more likely to respond to DM | Low |

### Scoring

Score each post 0-5:
- +1 if severity seems high (strong negative language, specific failures described)
- +1 if a trigger event is identifiable (milestone birthday, engagement, someone leaving)
- +1 if they name a tool/workaround they tried (Partiful, group chat, spreadsheet, hired someone)
- +1 if the outcome was bad or the event was abandoned
- +1 if they have a wish statement or express what should exist
- +1 bonus if post is 150+ words with specific details (causal language, not pablum)

**Minimum score to surface: 3/6.** Below that, too thin for a useful interview.

---

## Target Subreddits

### Primary (every run) — Where planners vent about pain

- r/Bachelorette
- r/BachelorettePlanning
- r/MaidOfHonor
- r/weddingplanning
- r/birthdays
- r/GirlsTrip
- r/AskWomen
- r/AskWomenOver30

### Secondary (every other run) — Broader planning pain

- r/wedding
- r/Parenting
- r/Mommit
- r/travel
- r/relationships
- r/TwoXChromosomes

### Pain-specific queries for r/all (every run)

These catch posts in niche subs you'd never think to monitor:

```bash
node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs search all \
  "planning nightmare group fell apart" --limit 10
node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs search all \
  "birthday party planning stress gave up" --limit 10
node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs search all \
  "bachelorette planning disaster nobody committed" --limit 10
```

---

## Queries — Pain Language, Not Recommendation Seeking

The vabene-reddit-monitor skill looks for people seeking recommendations
(acquisition leads). This skill looks for people experiencing pain
(interview candidates). Different queries.

**Include keywords** (pain signals):
```
nightmare,disaster,fell apart,gave up,nobody committed,so stressful,
never again,ruined,chaos,impossible to coordinate,lost money,
spent hours,exhausted,resentful,embarrassed,wish there was,
someone should build,why is this so hard,worst part was
```

**Exclude keywords** (wrong context):
```
vendor,florist,caterer,photographer,DJ,dress,cake,
recipe,decoration,DIY,craft,wedding venue,registry
```

---

## Workflow

### Step 1 — Fetch candidate posts

Use TWO strategies: browse recent posts (catches everything new) AND search for pain keywords (catches older high-signal posts).

**Strategy A: Browse new posts in high-signal subreddits.**
These subs are small enough that scanning the last 25 new posts catches everything from the past week.

```bash
# Browse recent posts — these are the highest-signal subs
for sub in MaidOfHonor BachelorettePlanning Bachelorette GirlsTrip; do
  node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs posts "$sub" \
    --sort new --limit 25
done

# Higher-volume subs — use search within them to filter
node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs search weddingplanning \
  "planning stress nightmare chaos help" --limit 15

node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs search AskWomen \
  "planning party birthday bachelorette group stress" --limit 15

node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs search AskWomenOver30 \
  "planning birthday party group trip stress" --limit 15
```

**Strategy B: Search r/all for pain language.**
Catches posts in niche subs you'd never think to monitor.

```bash
node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs search all \
  "planning bachelorette nightmare stress" --limit 10

node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs search all \
  "birthday party planning disaster gave up" --limit 10

node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs search all \
  "group trip planning fell apart nobody committed" --limit 10
```

**Filtering:** From all results, keep only posts from the last 7 days. Discard anything older. The `posts` command returns creation timestamps — check them.

### Step 2 — Read full thread for top candidates

For any post that looks promising from title/snippet, fetch the full thread:

```bash
node {baseDir}/../reddit-readonly/scripts/reddit-readonly.mjs thread \
  <post_id|url> --commentLimit 30 --depth 3
```

Reading the full post + comments is essential for scoring. A title like
"birthday planning help" could be pablum or could contain a 400-word
story about a coordination disaster. You need the body.

### Step 3 — Score each post

Read the full post text and score 0-6 using the criteria above.
Only surface posts scoring 3+.

For each qualifying post, extract:
- **Trigger event**: what life event kicked this off?
- **Current workaround**: what are they using now? (group text, Partiful, spreadsheet, delegated to someone, nothing)
- **What went wrong**: the specific failure or pain
- **Emotional tone**: stress, resentment, embarrassment, overwhelm?

### Step 4 — Draft outreach DM

**Voice rules for DMs:**
- Lead with their specific situation (proves you read their post)
- Be honest: "I'm building an app for group event planning"
- Ask for 15 minutes of their time
- Offer compensation ($20 gift card)
- Sound like a founder, not a researcher
- Under 5 sentences
- No exclamation marks
- Never mention "JTBD", "customer development", or "research sprint"

**Template — customize heavily to each post:**

> Hi! I saw your post about [SPECIFIC SITUATION from their post]. I'm
> building an app specifically for [THEIR EVENT TYPE] planning — the
> coordination/booking part that seems like it was [THEIR SPECIFIC PAIN].
> Would you be open to a 15-min call? I'm trying to understand what
> actually goes wrong when groups try to plan together. Happy to send a
> $20 [Amazon/Starbucks] gift card for your time.

**Customize based on what you extracted:**

- If they named a workaround: "I saw you tried [TOOL] — I'd love to hear what worked and what didn't about it"
- If the event was abandoned: "It sounds like [EVENT] didn't end up happening — I'd really like to understand what the breaking point was"
- If they expressed a wish: "You mentioned wanting [THEIR WISH] — that's exactly what I'm trying to figure out how to build"
- If they delegated: "It sounds like [PERSON] ended up taking it over — I'm curious what made you want to hand it off"

### Step 5 — Send to Telegram

One message per qualifying candidate:

```
🎯 Interview Candidate — r/[SUBREDDIT]

📌 "[POST TITLE]"
👤 u/[USERNAME] | Posted: [X days ago] | Score: [N]
🔗 https://reddit.com[PERMALINK]

📊 Interview Score: [X]/6
  • Trigger: [trigger event or "not identified"]
  • Workaround: [what they're using or "not identified"]  
  • Pain: [one-line summary of what went wrong]
  • Outcome: [happened well / went badly / abandoned / unclear]

💬 Draft DM:
---
[DRAFTED DM TEXT]
---

Copy DM → open reddit.com[PERMALINK] → click username → Send Message
```

**If no qualifying candidates found**: send a single summary:
```
🎯 Interview scan complete — no candidates scored 3+ today.
Scanned [N] posts across [M] subreddits.
Closest miss: "[TITLE]" (score 2, missing [WHAT]).
```

---

## Memory Tracking

Append after each run to MEMORY.md:
```
[DATE TIME PT] Interview scan: [N] posts scanned, [M] candidates surfaced (scores: [LIST]).
Top subs: [SUBREDDITS]. Event types: [TYPES].
```

Track over time:
- Which subreddits produce the best interview candidates
- Common trigger events and workarounds seen
- Response rate if Ben tracks which DMs got replies
- Patterns in what scores 4+ vs 3

---

## Cron Setup

Interview candidates don't expire as fast as promotional leads.
Once daily is sufficient.

```bash
# Daily scan, 9am PT
openclaw cron add \
  --name "VaBene Interview Finder" \
  --cron "0 9 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Run the vabene-interview-finder skill. Scan all target subreddits for interview candidates, score posts, draft outreach DMs, send qualifying candidates to Telegram. Never message anyone automatically." \
  --model claude-sonnet-4-6 \
  --announce \
  --channel telegram
```

Uses Sonnet (not Haiku) because scoring and DM drafting require nuance.
The monitor skill can use Haiku for simple fetch+filter, but interview
scoring needs to distinguish pablum from causal language.

Verify: `openclaw cron list`

---

## Manual Telegram Commands

- `find interviews` — full scan immediately
- `interview scan` — same as above
- `custdev scan` — same as above
- `who should I talk to` — same as above

---

## Relationship to vabene-reddit-monitor

These are sibling skills with different goals:

| | reddit-monitor | interview-finder |
|---|---|---|
| **Goal** | Find leads to promote VaBene to | Find people to learn from |
| **Output** | Public reply draft (promotional) | Private DM draft (research) |
| **Scoring** | Planning intent + recency | Pain severity + workaround + outcome |
| **Frequency** | Every 2 hours | Once daily |
| **Model** | Haiku (simple filter) | Sonnet (nuanced scoring) |
| **Queries** | "planning, recommendations, help" | "nightmare, disaster, gave up, chaos" |
| **Window** | 36 hours | 7 days |

A post can qualify for both — someone asking for recs while describing
pain is both a lead and an interview candidate. That's fine. The outputs
don't conflict.

---

## Security

- Read-only Reddit access. No credentials required.
- No user PII stored in MEMORY.md (usernames and permalinks only).
- All Telegram messages route through your existing bot.
- DMs are drafted only — never sent automatically.
