#!/usr/bin/env bash
# Symlinks each skills/<name>/ subdirectory into ~/.openclaw/skills/<name>.
# Idempotent. Runs on the openclaw host, not on the dev machine.
# Override the openclaw home with OPENCLAW_HOME=/some/path ./deploy.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="${OPENCLAW_HOME:-$HOME/.openclaw}"
TARGET_DIR="$OPENCLAW_DIR/skills"

if [[ ! -d "$OPENCLAW_DIR" ]]; then
  echo "openclaw not installed at $OPENCLAW_DIR — run this on the host, not on dev." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

for skill in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill")"
  link="$TARGET_DIR/$name"
  if [[ -L "$link" ]]; then
    ln -sfn "$skill" "$link"
  elif [[ -e "$link" ]]; then
    echo "refusing to overwrite non-symlink at $link (move it aside or pass --force; this script does not implement --force yet)" >&2
    exit 1
  else
    ln -s "$skill" "$link"
  fi
  echo "linked $name -> $skill"
done

echo "done. verify with: openclaw cron list"
