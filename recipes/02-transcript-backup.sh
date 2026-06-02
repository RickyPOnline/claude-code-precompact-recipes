#!/usr/bin/env bash
# 02-transcript-backup.sh · PreCompact recipe
#
# Copy the JSONL transcript to a timestamped backup before compaction
# rewrites it. Useful for forensic recovery if compact corrupts the
# session, or just for having an archival copy of what was said.
#
# Backups land in ~/.claude/precompact-backups/
# Auto-prunes anything older than 14 days.
#
# Exits 0 always.
set -u

LOG="$HOME/.claude/hooks/precompact-transcript.log"
BACKUP_DIR="$HOME/.claude/precompact-backups"
RETAIN_DAYS=14

mkdir -p "$(dirname "$LOG")" "$BACKUP_DIR"

HOOK_JSON=$(cat 2>/dev/null || echo '{}')
TS=$(date -u '+%Y-%m-%d %H:%M:%S')

echo "[$TS] FIRED" >> "$LOG"

# Extract transcript_path from the hook payload
TRANSCRIPT=$(echo "$HOOK_JSON" | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read() or '{}')
    print(d.get('transcript_path', ''))
except Exception:
    pass
" 2>/dev/null)

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  echo "[$TS] NO_TRANSCRIPT · $TRANSCRIPT" >> "$LOG"
  exit 0
fi

SESSION_ID=$(basename "$TRANSCRIPT" .jsonl)
DEST="$BACKUP_DIR/$(date -u +%Y%m%d-%H%M%S)-$SESSION_ID.jsonl"

cp "$TRANSCRIPT" "$DEST" 2>/dev/null && \
  SIZE=$(stat -c %s "$DEST" 2>/dev/null || stat -f %z "$DEST" 2>/dev/null) && \
  echo "[$TS] BACKED_UP · $DEST · ${SIZE} bytes" >> "$LOG" || \
  echo "[$TS] COPY_FAILED" >> "$LOG"

# Prune old backups
find "$BACKUP_DIR" -name '*.jsonl' -type f -mtime +$RETAIN_DAYS -delete 2>/dev/null

exit 0
