#!/usr/bin/env bash
# Materializes each skills/<name>/ subdirectory as a real directory at
# ~/.openclaw/skills/<name>/ via rsync. Replaces an earlier symlink-based
# deploy that openclaw v2026.4.26 rejects under its symlink-escape policy.
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

# Convention: every vabene-agents skill must be vabene-* prefixed so the
# orphan sweep below can distinguish ours from ClawHub-installed skills,
# which share ~/.openclaw/skills/. Fail fast if a new skill skips the prefix.
for skill in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill")"
  case "$name" in
    vabene-*) ;;
    *) echo "ERROR: skill '$name' must use vabene-* prefix" >&2; exit 1;;
  esac
done

# Defensive: clear any lingering vabene-* symlinks (from the pre-2026.4.26
# symlink-based deploy). Self-healing across the transition; safe to leave
# in permanently. Scoped to vabene-* so we never touch ClawHub installs.
find "$TARGET_DIR" -maxdepth 1 -type l -name 'vabene-*' -delete

# Sync each skill subdirectory from the repo into ~/.openclaw/skills/<name>/.
# Trailing slashes on both source and dest mean: copy CONTENTS into dest dir.
for skill in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill")"
  dest="$TARGET_DIR/$name"
  mkdir -p "$dest"
  rsync -a --delete "$skill" "$dest/"
  echo "synced $name -> $dest"
done

# Orphan sweep, prefix-scoped: only touch vabene-* dirs. Removes a skill
# that was previously deployed but has since been removed from the repo.
# CRITICAL: the vabene-* glob is the only thing keeping us from rm -rf'ing
# ClawHub-installed skills — do not broaden it.
for installed in "$TARGET_DIR"/vabene-*/; do
  [ -d "$installed" ] || continue
  name="$(basename "$installed")"
  if [ ! -d "$REPO_DIR/skills/$name" ]; then
    rm -rf "$installed"
    echo "removed orphan: $name"
  fi
done

echo "done. verify with: openclaw cron list"
