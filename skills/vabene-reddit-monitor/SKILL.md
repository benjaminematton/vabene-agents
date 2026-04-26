---
name: vabene-reddit-monitor
description: Find Reddit posts where someone is doing planning labor for a group celebration and is stuck. Draft a planner-pain-framed reply for each qualifying post and surface to Telegram for manual approval. Never posts automatically.
version: "2.0.0"
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
  - "scan sf"
  - "scan birthdays"
  - "scan trips"
  - "scan bach"
  - "scan bachelorette"
  - "lead stats"
---

# VaBene Reddit Lead Monitor

## Purpose

Find Reddit posts where a real person is doing the planning labor for a group celebration and is stuck — not enough hours, too many opinions, decisions piling up, group chat dying. Draft a planner-pain-framed reply for each qualifying post and surface it to Ben via Telegram for approval before any posting happens.

The user we serve is the **planner-friend**: the person who got handed the to-do list, has the group chat, and is going to be the one who books. The activity is not the pain. The coordination is the pain. Replies should speak to that.

**Hard rule: this skill NEVER posts to Reddit automatically. All posting is manual by the human after reviewing the Telegram draft.**

---

## Architecture: city-sub-first

Earlier versions of this skill led with planning-specific subs (Bachelorette, MaidOfHonor, GirlsTrip, weddingplanning). After Reddit banned several of those and r/Bachelorette turned out to be the TV show, the working planning-sub volume is too low to be the primary signal source. The actual lead source is **city subreddits filtered for celebration planning intent** — posts like "turning 30 in SF, 8 of us, what should we do" appear in r/AskSF, not r/birthdays.

City subs scan every run. Working planning subs scan as secondary signal.

---

## Target Subreddits

### Tier 1 — City subs, every run (SF-first)

These run every cron tick. SF and SF-adjacent are highest priority because SF is the launch market.

- r/SanFrancisco
- r/AskSF
- r/bayarea

### Tier 2 — City subs, every other run

Lower priority. Scanned alternating runs to keep volume manageable.

- r/LosAngeles
- r/AskLosAngeles
- r/Nashville
- r/LasVegas
- r/Austin
- r/Scottsdale

### Tier 3 — Working planning subs, every run

Low volume but high signal when posts exist. Always include because cost is negligible.

- r/BachelorettePlanning
- r/weddingplanning

### Tier 4 — High-volume general subs, every other run, strict filtering

Big subs with rich planner-pain content but high noise. Aggressive include filtering required (see Step 1).

- r/AskWomen
- r/AskWomenOver30
- r/travel

### Banned, dead, or wrong — DO NOT scan

Documented here as a tripwire so future iterations don't reintroduce them:

- r/Bachelorette — TV show, not planning
- r/MaidOfHonor — banned by Reddit
- r/GirlsTrip — banned by Reddit
- r/Bridesmaid — dead/banned
- r/dirtythirty — banned by Reddit (keyword still useful, see below)
- r/birthdays — celebration-of-self, not planning-for
- r/turning30 — dead community (one post in 18+ months; keyword still useful)

---

## Two-axis scoring

Each post gets a numeric score. Tiers are derived from the score.

### Hard exclusions — pre-scoring

If ANY of these terms appear in the post title or body, return excluded immediately. No scoring runs.

- vendor, florist, caterer, photographer, DJ, dress fitting, dress alterations
- Gabby Windey, Jenn Tran, rose ceremony, this season, tonight's episode
- The Bachelorette (capitalized as a show name), bachelor nation

These kill the post regardless of other signals. Vendor posts and TV-show crossposts are not VaBene leads under any score combination.

### Score components

- **+2** Celebration trigger keyword present in title or body. Triggers include:
  - Birthdays: birthday, bday, 30th, 35th, 40th, 50th, milestone birthday, milestone bday, dirty 30, dirty thirty, fab 40, the big 5-0, the big 3-0, round-number birthday, turning 30, turning 40
  - Weddings adjacent: bach, bach party, bachelorette, bridal shower, bridal brunch, bachelor party, groomsmen
  - Group trips: girls trip, girlfriends trip, ladies trip, group trip, friends trip, weekend trip, the crew, my crew
  - Other celebrations: baby shower, sprinkle, engagement party, just got engaged, anniversary trip, big anniversary, friend reunion, college reunion, family reunion

- **+2** Coordination-pain phrase present. The post must show the person is doing planning labor and stuck. Phrases include:
  - Planner identity: "I'm planning," "I'm in charge of," "I'm the planner," "MOH" / "maid of honor," "I'm the host," "everyone keeps asking me"
  - Group friction: "trying to coordinate," "everyone has different opinions," "can't get the group to agree," "group chat is dead," "nobody will commit," "playing mediator"
  - Decision-pending: "haven't booked yet," "still need to decide," "we need to figure out," "need to nail down," "haven't picked"
  - Frustration: "wish there was an easier way," "drowning in options," "this is so much work," "more work than I thought"

- **+1** Explicit group size of 3 or more. Examples: "8 of us," "10 girls," "the whole group," "12 people," "all my college friends"

- **+1** Decision-pending language present (counted separately from the pain axis even when triggered by the same phrase). The dual-counting is intentional — decision-pending is a strong VaBene-fit signal worth weighting twice.

- **+1** SF or SF-adjacent. Either the post is in r/SanFrancisco, r/AskSF, or r/bayarea, or the body explicitly names SF, San Francisco, the Bay Area, or a SF neighborhood (Marina, Mission, Hayes Valley, etc.).

- **−2** Soft penalty for gray terms. Reduces score but does not auto-exclude. Terms: drama, toxic, registry, ceremony order, dress code, save the date, save-the-date, table assignments

### Tiers

- **HIGH** — score 4 or higher
- **MED** — score 2 or 3
- **Excluded** — score below 2

### Tier semantics — read this

The math means a celebration trigger is effectively required, but pain language is not strictly required if the post has enough supporting signal. Concretely:

- "Turning 30 in SF, 8 of us, looking for ideas" → celebration (+2) + group size (+1) + SF (+1) = **4 = HIGH**, even with no explicit pain phrase. This is correct — that's a real VaBene lead.
- "I'm planning my friend's bach and drowning" → celebration (+2) + pain (+2) = **4 = HIGH**.
- "Anyone have ideas for a 30th birthday in SF" → celebration (+2) + SF (+1) = **3 = MED**. No group size, no pain, no decision-pending. Borderline; surfaces but flagged MED.
- "Looking for a wedding photographer in Austin" → vendor hard-exclusion → **excluded immediately**.

To restore strict two-axis behavior (require both celebration AND pain to reach HIGH): raise the HIGH floor from 4 to 5. That's the primary tuning knob.

---

## Workflow

### Step 1 — Fetch candidate posts

Per-call sub batching: maximum **4 subs per find call**. If a call returns an error or 404 for a specific sub, drop that sub from the batch and retry. This limits silent-degradation blast radius when a sub gets banned.

```bash
# SF batch — every run
node ~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs find \
  --subreddits "SanFrancisco,AskSF,bayarea" \
  --query "planning birthday group party trip celebration" \
  --include "birthday,30th,40th,milestone,bach,bachelorette,girls trip,group trip,weekend trip,baby shower,engagement,anniversary,reunion,planning,coordinate,group chat,MOH,maid of honor,dirty 30,turning 30,fab 40,big 5-0,wish there was,drowning in options,nobody will commit,haven't booked,still need to decide" \
  --exclude "vendor,florist,caterer,photographer,DJ,dress fitting,Gabby Windey,Jenn Tran,rose ceremony,this season,tonight's episode,The Bachelorette,bachelor nation,registry,ceremony order,save the date,save-the-date,table assignments" \
  --minScore 1 \
  --maxAgeHours 36 \
  --perSubredditLimit 15 \
  --maxResults 12 \
  --rank new

# Working planning subs — every run
node ~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs find \
  --subreddits "BachelorettePlanning,weddingplanning" \
  --query "planning trying to coordinate help group" \
  --include "planning,coordinate,group chat,MOH,maid of honor,nobody will commit,wish there was,drowning,haven't booked,still need to decide,8 of us,10 girls,the whole group,bach,birthday,group trip,bridal shower" \
  --exclude "vendor,florist,caterer,photographer,DJ,dress fitting,Gabby Windey,Jenn Tran,rose ceremony,this season,tonight's episode,The Bachelorette,bachelor nation,registry,ceremony order,save the date,save-the-date,table assignments" \
  --minScore 1 \
  --maxAgeHours 36 \
  --perSubredditLimit 15 \
  --maxResults 8 \
  --rank new

# Other city subs — every other run (alternate by checking if hour is even)
node ~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs find \
  --subreddits "LosAngeles,AskLosAngeles,Nashville,LasVegas" \
  --query "planning birthday group party trip celebration" \
  --include "birthday,30th,40th,milestone,bach,bachelorette,girls trip,group trip,weekend trip,baby shower,engagement,anniversary,reunion,planning,coordinate,MOH,maid of honor,dirty 30,turning 30,fab 40,big 5-0,wish there was,drowning in options,nobody will commit,haven't booked" \
  --exclude "vendor,florist,caterer,photographer,DJ,dress fitting,Gabby Windey,Jenn Tran,rose ceremony,this season,tonight's episode,The Bachelorette,bachelor nation,registry" \
  --minScore 1 \
  --maxAgeHours 36 \
  --perSubredditLimit 12 \
  --maxResults 8 \
  --rank new

# Other city subs round 2 — every other run, alternating from above
node ~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs find \
  --subreddits "Austin,Scottsdale" \
  --query "planning birthday group party trip celebration" \
  --include "birthday,30th,40th,milestone,bach,bachelorette,girls trip,group trip,weekend trip,baby shower,engagement,anniversary,reunion,planning,coordinate,MOH,maid of honor,dirty 30,turning 30,fab 40,big 5-0" \
  --exclude "vendor,florist,caterer,photographer,DJ,dress fitting,Gabby Windey,Jenn Tran,rose ceremony,this season,tonight's episode,The Bachelorette,bachelor nation,registry" \
  --minScore 1 \
  --maxAgeHours 36 \
  --perSubredditLimit 12 \
  --maxResults 6 \
  --rank new

# High-volume general subs — every other run
node ~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs find \
  --subreddits "AskWomen,AskWomenOver30,travel" \
  --query "planning birthday milestone bach group trip MOH coordinate" \
  --include "I'm planning,trying to coordinate,MOH,maid of honor,30th,40th,milestone birthday,dirty 30,fab 40,group trip,girls trip,bach,bachelorette,wish there was,drowning in options,nobody will commit,haven't booked,still need to decide,8 of us,10 girls,the whole group,planner friend" \
  --exclude "vendor,florist,caterer,photographer,DJ,dress fitting,Gabby Windey,Jenn Tran,rose ceremony,this season,tonight's episode,The Bachelorette,bachelor nation,registry,solo trip,traveling alone,backpacking solo" \
  --minScore 2 \
  --maxAgeHours 36 \
  --perSubredditLimit 10 \
  --maxResults 5 \
  --rank new
```

If Reddit rate-limits you, slow down with:
```bash
export REDDIT_RO_MIN_DELAY_MS=800
export REDDIT_RO_MAX_DELAY_MS=1800
```

If a sub returns an error, log the failure to MEMORY.md and continue with remaining subs. Do not let one banned sub kill the whole batch.

### Step 2 — Score each candidate

For each fetched post:

1. Run hard exclusion check (vendor, TV-show, ceremony-logistics terms). If any present, mark excluded and move on.
2. Compute score per the rubric above.
3. Determine tier (HIGH if score ≥ 4, MED if score 2–3, excluded if < 2).
4. For posts that pass scoring, also extract:
   - **Celebration type** (birthday, bach, group trip, baby shower, etc.)
   - **Group size** if mentioned
   - **City or region** if mentioned
   - **Decision-pending detail** — what specifically hasn't been decided yet

### Step 3 — Check thread for VaBene mentions and competitors

```bash
node ~/.openclaw/workspace/skills/reddit-readonly/scripts/reddit-readonly.mjs thread \
  <post_id|url> --commentLimit 50 --depth 3
```

Skip if VaBene already mentioned in the thread. Log competitor mentions (Partiful, The Bash, Peerspace, Airbnb Experiences, Viator, GetYourGuide, Batch) to MEMORY.md for tracking.

### Step 4 — Draft a reply

**Voice rules — planner-pain framing:**

- Lead with the coordination pain, not the activity discovery
- The reader is the planner-friend; speak to them, not to "your group"
- Mention VaBene once, naturally, as a tool that helped
- Link to https://vabene.app
- Under 4 sentences
- Max one exclamation point
- Never say "full disclosure," "I work for," "as the founder"
- Never claim a specific personal experience that isn't yours — generic empathy ("planning anything for a group is a lot") is fine; fabricated specifics ("when I planned my sister's bach in Nashville last spring") are not

**Templates — pivot from "your group can browse" to "you don't have to be the bottleneck":**

MILESTONE BIRTHDAY (highest priority — SF wedge):
> "Honestly the hardest part of planning a milestone birthday isn't picking the activity — it's getting eight people with eight schedules and eight opinions to commit to anything. [VaBene](https://vabene.app) is built for the person doing the planning labor: you put options in, the group votes, you book what wins. Cuts the back-and-forth way down for the planner-friend who's tired of being the bottleneck."

GROUP TRIP / GIRLS TRIP:
> "Group trips are amazing until you're three weeks deep in a group chat trying to nail down one restaurant while the planner-friend slowly loses their mind. [VaBene](https://vabene.app) is built for that exact problem — the person organizing puts options in, everyone votes, decisions get made. Worth a look if you're the one carrying it."

BACHELORETTE / MOH:
> "Being MOH and wrangling 8 people's opinions while the bride pretends she 'doesn't care' is its own job. [VaBene](https://vabene.app) was genuinely useful for ours — you put activity options in, everyone votes, and you stop being the bad guy making every decision alone. Saved a lot of group-chat back-and-forth."

BRIDAL SHOWER / BABY SHOWER:
> "Showers are deceptively hard because you're juggling friend-group A, friend-group B, family, and timing — and the person hosting ends up doing all of it. [VaBene](https://vabene.app) lets you put activity ideas in and have guests weigh in before you book, so it's not all on you."

ENGAGEMENT / ANNIVERSARY / REUNION:
> "The friend who plans everything for the group always ends up doing more than they signed up for — the activity is fine, the coordination is the problem. [VaBene](https://vabene.app) is built for that: planner puts options in, everyone votes, you book what wins. Worth a look if you're the one in charge."

GENERIC PLANNER-PAIN (use when celebration type is unclear but planner-pain is high):
> "Being the friend who plans everything is a lot, and the part that breaks people isn't the activity itself — it's getting eight schedules and eight opinions to converge. [VaBene](https://vabene.app) is built for exactly that. Might be worth a look if the coordination piece is what's killing you."

Customize each template to the specific post — drop in the city, the group size, the celebration type, the specific decision they're stuck on. A template that reads as a template gets ignored.

### Step 5 — Send to Telegram

One message per qualifying post:

```
🦞 VaBene Lead — r/[SUBREDDIT]

📌 "[POST TITLE]"
👤 Posted: [X hours ago] | Score: [REDDIT_SCORE] | Comments: [N]
🔗 https://reddit.com[PERMALINK]

📊 Lead score: [X]/7+
  • Celebration: [TYPE] (+2)
  • Pain language: [present / absent] ([+2 or 0])
  • Group size: [N or "not mentioned"] ([+1 or 0])
  • Decision-pending: [yes / no] ([+1 or 0])
  • SF-adjacent: [yes / no] ([+1 or 0])

📝 Draft reply:
[DRAFTED REPLY TEXT]

✅ approve (copy + paste to post manually) | ❌ skip
Tier: [HIGH/MED] | Event type: [TYPE]
```

If no qualifying posts found: stay silent (do not send a "0 leads" message — Lead Digest cron handles daily summaries). Log scan to MEMORY.md.

---

## Memory Tracking

Append after each run to MEMORY.md:

```
[DATE TIME PT] Scan: [N] posts fetched, [M] qualifying ([H] HIGH / [D] MED).

Subreddit yield this run:
  r/SanFrancisco: [F fetched, Q qualifying]
  r/AskSF: [F fetched, Q qualifying]
  ...

Trigger-pattern yield this run (which keyword combos surfaced qualifying posts):
  celebration+pain+group: [N posts]
  celebration+SF+group: [N posts]
  celebration+pain only: [N posts]
  ...

Notes: [competitor mentions, banned subs encountered, anything notable]
```

Track over time:
- **Subreddit yield** — which subs actually produce qualifying leads. After 2 weeks, prune subs with zero yield.
- **Trigger-pattern yield** — which keyword combinations surface real leads. Lets you tune the include keyword list empirically instead of guessing.
- **Competitor mentions** — Partiful, Batch, etc. — surfaces emerging competitive pressure.
- **Banned-sub events** — if a previously working sub starts returning errors, it may have been banned; flag for sub-list review.

---

## Cron Setup

Already configured. For reference / re-creation:

```bash
# Every 2 hours, 8am–10pm PT
openclaw cron add \
  --name "VaBene Reddit Scan" \
  --cron "0 8,10,12,14,16,18,20,22 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Run the vabene-reddit-monitor skill. Scan all target subreddits per the city-sub-first architecture, score posts, draft replies, send qualifying to Telegram for approval. Do not post anything automatically." \
  --model claude-haiku-4-5-20251001 \
  --to <TELEGRAM_CHAT_ID> \
  --announce \
  --channel telegram
```

Verify: `openclaw cron list`

---

## Manual Telegram Commands

- `scan reddit now` — full scan immediately
- `scan sf` — SF batch only (r/SanFrancisco, r/AskSF, r/bayarea)
- `scan birthdays` — all subs, milestone-birthday include filter only
- `scan trips` — all subs, group-trip include filter only
- `scan bach` — bachelorette-specific scan (r/BachelorettePlanning + bach include filter on city subs)
- `scan bachelorette` — alias for `scan bach`
- `lead stats` — 7-day summary from MEMORY.md
- `pause reddit monitor` — disable the scheduled cron
- `resume reddit monitor` — re-enable the scheduled cron

---

## Tuning levers (in priority order)

When iterating on this skill, tune in this order:

1. **HIGH score floor** — currently 4. Raise to 5 if Telegram is too noisy. Lower to 3 if too quiet. Single biggest knob.
2. **Hard exclusion list** — add new kill-words when a category of false positive surfaces. The current list catches vendor and TV-show; expand if a new pattern appears.
3. **Include keyword coverage** — if real leads are slipping through with no score signal, the include list needs new keywords. Add and re-run.
4. **Subreddit list** — last resort. Add or remove subs based on 2-week yield data, not gut feel. Don't add a sub without data showing it'll produce leads.

Do not change scoring weights without writing down why in MEMORY.md and the skill's README change-log. Weights are easy to fiddle and hard to reason about retroactively.

---

## Relationship to vabene-interview-finder

Sibling skill, different goal:

- This skill (reddit-monitor) finds **leads to reply to publicly** — people stuck in planning who'd benefit from VaBene as a tool.
- Interview-finder finds **research candidates to DM privately** — people experiencing planning pain who'd be valuable JTBD interview subjects.

A post can qualify for both. That's fine — the outputs go to different Telegram message formats and don't conflict.

When interview-finder gets its rewrite (deferred), the scoring scale in this skill should be unified across both for consistency.

---

## Security

- Read-only Reddit access. No credentials required.
- No user PII stored in MEMORY.md (post titles and permalinks only — no usernames, no real names).
- All Telegram messages route through the configured bot.
- No automatic posting to Reddit. All replies are drafted only; human approves and posts manually.
