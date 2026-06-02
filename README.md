# claude-code-precompact-recipes

Tiny, forkable hook scripts that fire **right before Claude Code summarizes your context** — the moment when most agents lose state they didn't realize was about to vanish.

The `PreCompact` hook event has been in Claude Code for a while. Almost nobody uses it. This repo is six clean examples that show what it's for.

## What is PreCompact?

Claude Code's harness fires a configurable hook *just before* a `/compact` (manual or auto-triggered by context-limit). Your script runs to completion (within its declared timeout) before the summarizer takes over. Anything you save to disk in those few seconds survives the compaction — anything you don't is reconstructed from the harness's generic summary.

Two matchers:

- `"manual"` — fires when the operator types `/compact`
- `"auto"` — fires when the harness auto-compacts because context is full

Wiring example in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/your/hook.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

Your script reads a JSON event from stdin. It exits 0 (so compaction proceeds) regardless of internal errors — never block the compact, just save what you can.

## The recipes

| File | What it does |
|---|---|
| `recipes/01-git-stash-snapshot.sh` | Auto-stash uncommitted changes before context-loss, with a recoverable tag |
| `recipes/02-transcript-backup.sh` | Copy the JSONL transcript to a timestamped backup before summary overwrites it |
| `recipes/03-handoff-memo.sh` | Generate a "what's in flight" handoff note that the next session reads on resume |
| `recipes/04-todo-persist.sh` | Serialize current TODO state to disk in a structured format |
| `recipes/05-decision-log.sh` | Append a "context boundary at T" marker to a long-running decision log |
| `recipes/06-memory-road-snapshot.sh` | Pointer recipe that triggers a full structured memory snapshot (see "What's next" below) |

Each recipe is a standalone bash script. Drop it in `~/.claude/hooks/`, point `settings.json` at it, done.

## Quickstart

```bash
git clone https://github.com/RickyPOnline/claude-code-precompact-recipes
cd claude-code-precompact-recipes
cp recipes/01-git-stash-snapshot.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/01-git-stash-snapshot.sh
# Then edit ~/.claude/settings.json to wire the PreCompact hook
```

Verify it fires:

```bash
echo '{"hook_event_name":"smoke","trigger":"manual"}' | \
  ~/.claude/hooks/01-git-stash-snapshot.sh
# Check the log file the recipe declared (each one logs to ~/.claude/hooks/*.log)
```

## The pattern

The unlock isn't `/compact`'s built-in summary — that already exists. The unlock is **your version of "what matters" winning over the harness's generic summary**, because *you* know which file mid-edit, which TODO mid-thought, which decision rationale is load-bearing for the next session.

Hook writes a structured file (markdown / JSON / git stash). A `SessionStart` hook re-loads it on resume. Compact stops being a memory wipe — it becomes a snapshot boundary.

## What's next — Memory Road

If you like what `PreCompact` does for one hook, the natural next question is: *what if every layer of an agent's memory had its own snapshot path, and they all survived /compact, /clear, cold boots, and crashes?*

That's Memory Road — a layered Claude Memory architecture (Layers 0-12) that treats agent memory the way databases treat durability: substrate is sacred, comprehension is replaceable, every boundary event triggers a structured save. The `06-memory-road-snapshot.sh` recipe in this repo is the smallest entry point to the full system.

Full architecture, kernel code, and the 11-layer model live at:

→ **github.com/RickyPOnline/memory-road**

`PreCompact` is the first hook. Memory Road is what you build on top of it once you realize one hook isn't enough.

## License

MIT. Fork freely.

## Credits

Built from real production use in a Claude Code session that was burning subscription quota to 2% by Monday morning. Event-driven hooks fixed it. Sharing the pattern so other operators don't rediscover the same wheel.
