#!/usr/bin/env bash
# 06-memory-road-snapshot.sh · PreCompact recipe
#
# Pointer recipe. Demonstrates how PreCompact composes with a layered
# memory architecture — Memory Road is one such architecture; you can
# build your own.
#
# Pattern: hook calls a snapshot script that runs N quick capture jobs
# (one per memory layer you care about), each one writing to its own
# durable file. SessionStart hooks then read those files back.
#
# This recipe is intentionally minimal — it just calls a placeholder
# script. Replace `your-snapshot-binary` with whatever drives YOUR
# memory layers (or use Memory Road's snapshot_l0_now.sh as-is —
# see https://github.com/YOUR_USERNAME/memory-road).
#
# Exits 0 always — never block the compact, even if snapshot fails.
set -u

LOG="$HOME/.claude/hooks/precompact-snapshot.log"
mkdir -p "$(dirname "$LOG")"

# Drain stdin (snapshot can be triggered without payload fields)
HOOK_JSON=$(cat 2>/dev/null || echo '{}')
TS=$(date -u '+%Y-%m-%d %H:%M:%S')

echo "[$TS] FIRED" >> "$LOG"

# Replace this with your real snapshot entry point.
# Memory Road's example:
#   SNAPSHOT_BIN="$HOME/.claude/hooks/snapshot_l0_now.sh"
#
# Or call your own:
SNAPSHOT_BIN="${PRECOMPACT_SNAPSHOT_BIN:-/path/to/your-snapshot-binary}"

if [ ! -x "$SNAPSHOT_BIN" ]; then
  echo "[$TS] NO_SNAPSHOT_BIN · set PRECOMPACT_SNAPSHOT_BIN env var or edit this script" >> "$LOG"
  exit 0
fi

# Fire the snapshot. Cap wall time so we never blow past the hook timeout.
echo "$HOOK_JSON" | timeout 150 "$SNAPSHOT_BIN" >> "$LOG" 2>&1
echo "[$TS] DONE · exit=$?" >> "$LOG"
exit 0
