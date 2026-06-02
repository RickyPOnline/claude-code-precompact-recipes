#!/usr/bin/env bash
# 04-todo-persist.sh · PreCompact recipe
#
# Serializes the current TODO state (from Claude Code's TaskList tool)
# to a structured markdown file so the next session can read it back.
#
# Claude Code stores task state internally; this recipe demonstrates the
# pattern of dumping ANY structured working memory you maintain to a
# file the next session can re-load.
#
# This recipe assumes you've been writing TODOs to a file via the
# TaskCreate tool's metadata field (a common pattern). Adapt the
# SOURCE path to wherever your TODO state actually lives.
#
# Exits 0 always.
set -u

LOG="$HOME/.claude/hooks/precompact-todo.log"
TODO_OUT="$HOME/.claude/state/todo-snapshot.md"

# Adapt this — point at wherever your live TODO state lands
SOURCE="${PRECOMPACT_TODO_SOURCE:-$HOME/.claude/state/todo-live.json}"

mkdir -p "$(dirname "$LOG")" "$(dirname "$TODO_OUT")"

TS=$(date -u '+%Y-%m-%d %H:%M:%S')
echo "[$TS] FIRED" >> "$LOG"

# Drain stdin (hook payload — we don't need any specific field here)
cat >/dev/null 2>&1 || true

if [ ! -f "$SOURCE" ]; then
  echo "[$TS] NO_SOURCE · expected $SOURCE" >> "$LOG"
  # Write an empty stub so the SessionStart-side reader can still find SOMETHING
  printf "# TODO snapshot · %s\n\nNo live TODO state found at compact time.\n" "$TS" > "$TODO_OUT"
  exit 0
fi

# Render whatever's in $SOURCE as markdown
python3 - "$SOURCE" "$TODO_OUT" "$TS" <<'PY'
import sys, json, datetime
src, out, ts = sys.argv[1:4]
try:
    data = json.load(open(src))
except Exception as e:
    open(out, 'w').write(f"# TODO snapshot · {ts}\n\nCould not read source: {e}\n")
    sys.exit(0)

lines = [f"# TODO snapshot · {ts}\n",
         f"Captured before /compact. Source: `{src}`\n"]

tasks = data if isinstance(data, list) else data.get('tasks', [])
if not tasks:
    lines.append("No active tasks.\n")
else:
    lines.append("## Active tasks\n")
    for t in tasks:
        if not isinstance(t, dict):
            continue
        status = t.get('status', '?')
        subject = t.get('subject', t.get('title', '<unnamed>'))
        marker = '✅' if status == 'completed' else ('▶' if status == 'in_progress' else '·')
        lines.append(f"- {marker} **{subject}** _(status: {status})_")
        if t.get('description'):
            lines.append(f"  - {t['description']}")

open(out, 'w').write('\n'.join(lines) + '\n')
PY

echo "[$TS] WROTE · $TODO_OUT" >> "$LOG"
exit 0
