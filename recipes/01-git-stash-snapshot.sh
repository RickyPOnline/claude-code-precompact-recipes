#!/usr/bin/env bash
# 01-git-stash-snapshot.sh · PreCompact recipe
#
# Auto-stash uncommitted changes in the current repo before /compact runs,
# so a half-edit mid-conversation isn't lost when the harness summarizes.
#
# Recoverable via: git stash list | grep pre-compact
#                  git stash apply stash@{N}
#
# Exits 0 always — never block the compact.
set -u

LOG="$HOME/.claude/hooks/precompact-stash.log"
mkdir -p "$(dirname "$LOG")"

# Read hook event from stdin (we only need to know we fired)
HOOK_JSON=$(cat 2>/dev/null || echo '{}')
TS=$(date -u '+%Y-%m-%d %H:%M:%S')

echo "[$TS] FIRED" >> "$LOG"

# Discover the agent's current working directory from the JSON payload
CWD=$(echo "$HOOK_JSON" | python3 -c "import sys,json; print(json.loads(sys.stdin.read() or '{}').get('cwd',''))" 2>/dev/null)
CWD="${CWD:-$PWD}"

cd "$CWD" 2>/dev/null || { echo "[$TS] CWD_FAIL · $CWD" >> "$LOG"; exit 0; }

# Only stash if we're in a git repo with uncommitted changes
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "[$TS] NOT_A_REPO · $CWD" >> "$LOG"
  exit 0
fi

if git diff --quiet && git diff --cached --quiet; then
  echo "[$TS] CLEAN · nothing to stash" >> "$LOG"
  exit 0
fi

STASH_MSG="pre-compact-$(date -u +%Y%m%d-%H%M%S)"
git stash push -u -m "$STASH_MSG" >> "$LOG" 2>&1 && \
  echo "[$TS] STASHED · $STASH_MSG" >> "$LOG" || \
  echo "[$TS] STASH_FAILED" >> "$LOG"

exit 0
