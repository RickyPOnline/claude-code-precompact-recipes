#!/usr/bin/env bash
# 05-decision-log.sh · PreCompact recipe
#
# Appends a "context boundary at T" marker to a long-running decision log
# so months later you can see "this is where the agent's memory got
# summarized — anything earlier was re-derived from a compact."
#
# Useful for debugging "why did the agent suddenly forget X" — you can
# trace back to the exact compact boundary that dropped the context.
#
# Exits 0 always.
set -u

LOG_DIR="$HOME/.claude/decision-log"
LOG_FILE="$LOG_DIR/decisions.md"
HOOK_LOG="$HOME/.claude/hooks/precompact-decision-log.log"

mkdir -p "$LOG_DIR" "$(dirname "$HOOK_LOG")"

HOOK_JSON=$(cat 2>/dev/null || echo '{}')
TS_UTC=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
TS_LOCAL=$(date '+%Y-%m-%d %H:%M:%S %Z')

echo "[$TS_UTC] FIRED" >> "$HOOK_LOG"

# Pull session id + trigger from the payload for the marker
SESSION_ID=$(echo "$HOOK_JSON" | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read() or '{}')
    p = d.get('transcript_path', '')
    print(p.rsplit('/', 1)[-1].rsplit('.', 1)[0] if p else '?')
except Exception:
    print('?')
" 2>/dev/null)

TRIGGER=$(echo "$HOOK_JSON" | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read() or '{}')
    print(d.get('trigger', d.get('matcher', '?')))
except Exception:
    print('?')
" 2>/dev/null)

# Append a horizontal-rule marker; easy to grep later
{
  echo ""
  echo "---"
  echo ""
  echo "## ⏸ Context boundary · $TS_UTC ($TS_LOCAL)"
  echo ""
  echo "- Session: \`$SESSION_ID\`"
  echo "- Trigger: \`$TRIGGER\`"
  echo "- Note: Conversation context was summarized at this point."
  echo "  Everything below this marker happened in a fresh post-compact view."
  echo ""
} >> "$LOG_FILE"

echo "[$TS_UTC] APPENDED · $LOG_FILE" >> "$HOOK_LOG"
exit 0
