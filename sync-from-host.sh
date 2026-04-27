#!/usr/bin/env bash
# Snapshots the live openclaw cron config into the repo.
# Runs on the host. Writes:
#   - crons/jobs.json          (gitignored — raw, contains chat IDs)
#   - crons/jobs.example.json  (sanitized — safe to commit)
# Override the openclaw home with OPENCLAW_HOME=/some/path ./sync-from-host.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${OPENCLAW_HOME:-$HOME/.openclaw}"

if [[ ! -f "$SRC/cron/jobs.json" ]]; then
  echo "no jobs.json at $SRC/cron/jobs.json — run this on the host." >&2
  exit 1
fi

cp "$SRC/cron/jobs.json" "$REPO_DIR/crons/jobs.json"

# Sanitize: replace numeric Telegram chat IDs and bot tokens with placeholders.
# Chat IDs may appear as strings ("to": "123...") or bare numbers ("to": 123...) — handle both.
# Telegram bot tokens look like "<digits>:<base64-ish>".
sed -E \
  -e 's/"to":[[:space:]]*"[0-9]+"/"to": "<TELEGRAM_CHAT_ID>"/g' \
  -e 's/"to":[[:space:]]*[0-9]+/"to": "<TELEGRAM_CHAT_ID>"/g' \
  -e 's/"token":[[:space:]]*"[0-9]+:[A-Za-z0-9_-]+"/"token": "<TELEGRAM_BOT_TOKEN>"/g' \
  "$REPO_DIR/crons/jobs.json" > "$REPO_DIR/crons/jobs.example.json"

echo "synced."
echo "review crons/jobs.example.json before committing — grep for the literal chat ID to confirm redaction."
echo "if anything slipped through, extend the sed pipeline in sync-from-host.sh before commit."
