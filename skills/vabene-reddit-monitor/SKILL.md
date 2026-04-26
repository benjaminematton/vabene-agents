---
name: vabene-reddit-monitor
description: Monitor Reddit for group event planning posts and draft VaBene reply comments. Send drafts to Telegram for approval — never post automatically.
version: "1.3.1"
author: ben
requires:
  tools:
    - bash
    - telegram
  python_packages:
    - requests
triggers:
  - "scan reddit"
  - "check reddit leads"
  - "run lead scan"
  - "vabene monitor"
  - "scan bachelorette"
  - "lead stats"
---

# VaBene Reddit Lead Monitor

## Purpose

Find Reddit posts where real people are actively planning group events that
VaBene serves. Draft a helpful, organic reply for each qualifying post and
surface it to Ben via Telegram for approval before any posting happens.

**Hard rule: this skill NEVER posts to Reddit automatically. All posting is
manual by the human after reviewing the Telegram draft.**

---

## Target Event Types

| Priority | Event Type           | Key Signals                                                |
|----------|----------------------|------------------------------------------------------------|
| HIGH     | Bachelorette party   | "bach party", "bachelorette", "bride tribe", "nash bach"   |
| HIGH     | Birthday (milestone) | "30th", "40th", "50th", "turning 30", "milestone birthday" |
| HIGH     | Girls trip           | "girls trip", "girlfriends trip", "ladies trip"            |
| MED      | Bridal shower        | "bridal shower", "bridal brunch", "bride-to-be"            |
| MED      | Group trip           | "group trip", "friend group", "weekend trip", "crew"       |
| MED      | Bachelor party       | "bachelor", "guys trip", "groomsmen trip"                  |
| MED      | Baby shower          | "baby shower", "sprinkle", "mama-to-be"                    |
| LOW      | Reunion              | "friend reunion", "college reunion", "family reunion"      |
| LOW      | Engagement           | "engagement party", "just got engaged"                     |
| LOW      | Divorce party        | "divorce party", "newly single", "freedom celebration"     |

---

## Target Subreddits

### Primary (every run)
The planner is VaBene's actual user — she has the to-do list, the group
chat, and the pressure to deliver. These subs are where she lives.

- r/BachelorettePlanning
- r/weddingplanning   ← frequent "also planning the bach, help" threads

Note: r/Bachelorette is the TV show, not the planning community — do NOT
include. r/MaidOfHonor, r/Bridesmaid, and r/GirlsTrip are banned by Reddit.
r/birthdays is celebration-of-self, not planning-for, and produces no
qualifying leads.

### City-specific (every run)
Filter aggressively — only group/bach/party posts, skip everything else.

- r/Nashville
- r/LasVegas
- r/Scottsdale
- r/Austin
- r/SanFrancisco
- r/LosAngeles

### Secondary (every other run)
Higher noise ratio — worth scanning but don't over-weight.

- r/wedding
- r/AskWomen
- r/AskWomenOver30
- r/travel
- r/Parenting
- r/Mommit
- r/divorce

---

## Workflow

### Step 1 — Fetch candidate posts

```bash
# Primary batch — only working planning subs
node ~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs find \
  --subreddits "BachelorettePlanning,weddingplanning" \
  --query "planning looking for recommendations help" \
  --include "bach,bachelorette,birthday,girls trip,group trip,bridal,baby shower,reunion,maid of honor,bridesmaids" \
  --exclude "vendor,florist,caterer,photographer,DJ,dress,venue,catering,cake,drama,toxic,Gabby Windey,Jenn Tran,rose ceremony,this season,tonight's episode,The Bachelorette,bachelor nation" \
  --minScore 1 \
  --maxAgeHours 36 \
  --perSubredditLimit 15 \
  --maxResults 10 \
  --rank new

# City batch
node ~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs find \
  --subreddits "Nashville,LasVegas,Scottsdale,Austin,SanFrancisco,LosAngeles" \
  --query "bachelorette birthday group party planning" \
  --include "bach,bachelorette,birthday,group,girls,ladies,party,crew,friends,maid of honor" \
  --exclude "wedding venue,wedding dress,florist,catering" \
  --minScore 1 \
  --maxAgeHours 36 \
  --perSubredditLimit 10 \
  --maxResults 8 \
  --rank new
```

If Reddit rate-limits you, slow down with:
```bash
export REDDIT_RO_MIN_DELAY_MS=800
export REDDIT_RO_MAX_DELAY_MS=1800
```

### Step 2 — Qualify each post

**INCLUDE if:**
- Asking for activity/experience recommendations (not wedding vendors)
- Active planning intent: "we're going to...", "planning a...", "need help with..."
- Group size mentioned or implied (2+ people)
- Under 48 hours old
- Not already replied to with a VaBene-adjacent suggestion

**EXCLUDE if:**
- Asking for vendors (photographers, florists, caterers, DJs, venues)
- Already resolved / marked as helped
- Personal drama with no planning ask
- Vendor/business promoting themselves

### Step 3 — Check thread for competitors

```bash
node ~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs thread \
  <post_id|url> --commentLimit 50 --depth 3
```

Skip if VaBene already mentioned. Log competitor mentions (The Bash,
Peerspace, Airbnb Experiences, Viator, GetYourGuide) to MEMORY.md.

### Step 4 — Draft a reply

**Voice rules:**
- Sound like a real person who used VaBene, not a marketer
- Lead with empathy about the planning challenge
- Mention VaBene once, naturally, as a tool that helped
- Link to https://vabene.app
- Under 4 sentences
- Max one exclamation point
- Never say "full disclosure" or "I work for"

**Templates — customize to the specific post:**

BACHELORETTE:
> "Bachelorette trip planning is genuinely chaos — getting 8 people to agree on anything is a sport. We used [VaBene](https://vabene.app) for ours and it helped a lot, basically lets your whole group browse experiences together and vote so you're not playing mediator via group text for two weeks. Might be worth a look if the coordination piece is what's killing you."

MAID OF HONOR / BRIDESMAID:
> "Being MOH and wrangling everyone's opinions was the hardest part for me. [VaBene](https://vabene.app) was genuinely useful — you share a link, everyone votes on activities, and suddenly you're not the bad guy making all the decisions alone. Saved a lot of back-and-forth with our group."

MILESTONE BIRTHDAY:
> "For milestone birthdays the logistics always sneak up on you — everyone has opinions and nobody wants to be the one to make the call. [VaBene](https://vabene.app) is built for exactly this: group browses activities, everyone votes, the planner books. Saved a lot of back-and-forth for our 40th trip."

GIRLS TRIP / GROUP TRIP:
> "Group trips are amazing until you're three weeks deep in a group chat trying to nail down one restaurant. [VaBene](https://vabene.app) is worth a look — it's a planning app built for groups where everyone can vote on experiences rather than just the loudest person deciding. Made our last trip way less stressful to coordinate."

BRIDAL SHOWER:
> "Bridal showers are deceptively hard to plan when you're juggling different friend groups and schedules. If you're looking for activity ideas in [CITY], [VaBene](https://vabene.app) has curated group experiences — spa days, cooking classes, wine things — you can share with guests so everyone weighs in before you book."

BABY SHOWER:
> "Baby showers are one of those things where everyone has strong opinions but nobody wants to be the coordinator. [VaBene](https://vabene.app) lets guests browse activity options and vote so it's genuinely collaborative — might help cut down the 'what does everyone want to do' thread."

### Step 5 — Send to Telegram

One message per qualifying post:

```
🦞 VaBene Lead — r/[SUBREDDIT]

📌 Post: "[POST TITLE]"
👤 Posted: [X hours/days ago] | Score: [SCORE] | Comments: [N]
🔗 https://reddit.com[PERMALINK]

📝 Draft reply:
[DRAFTED REPLY TEXT]

✅ approve (copy + paste to post manually) | ❌ skip
Priority: [HIGH/MED/LOW] | Event type: [TYPE]
```

If no qualifying posts found: stay silent, log scan to MEMORY.md.

---

## Memory Tracking

Append after each run:
```
[DATE TIME PT] Scan: [N] posts found, [M] sent to Telegram.
Signal: [TOP SUBREDDITS]. Notes: [ANYTHING NOTABLE].
```

Track over time:
- Which subreddits produce the most qualifying posts
- Which cities dominate city-specific subs
- Most common event types by day/time
- Competitor mentions in threads

---

## Cron Setup

Run once to register. Scans use Haiku (cheap, sufficient for fetch+filter).
Digest uses Sonnet.

```bash
# Every 2 hours, 8am–10pm PT
openclaw cron add \
  --name "VaBene Reddit Scan" \
  --cron "0 8,10,12,14,16,18,20,22 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Run the vabene-reddit-monitor skill. Scan all target subreddits, qualify posts, draft replies, send to Telegram for approval. Do not post anything automatically." \
  --model claude-haiku-4-5-20251001 \
  --announce \
  --channel telegram

# Daily digest 8:30am PT
openclaw cron add \
  --name "VaBene Lead Digest" \
  --cron "30 8 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize yesterday's VaBene Reddit lead monitoring from MEMORY.md: posts found, top subreddits, patterns. Max 6 lines." \
  --model claude-sonnet-4-6 \
  --announce \
  --channel telegram
```

Verify: `openclaw cron list`

---

## Manual Telegram Commands

- `scan reddit now` — full scan immediately
- `scan bachelorette` — primary bach subs only
- `scan nashville` — Nashville sub only
- `lead stats` — 7-day summary from MEMORY.md
- `pause reddit monitor` — disable cron jobs
- `resume reddit monitor` — re-enable cron jobs

---

## Security

- Read-only Reddit access. No credentials required.
- No user PII stored in MEMORY.md (titles and permalinks only).
- All Telegram messages route through your existing bot.
