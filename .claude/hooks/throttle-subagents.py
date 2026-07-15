#!/usr/bin/env python3
"""
PreToolUse burst-rate limiter for the Task (subagent) tool.

Prevents fanning out too many subagents at once — the failure that repeatedly tripped
the session usage limit during the Reddit-analysis job. Logs each launch timestamp and
DENIES a launch when more than MAX launches occurred in the last WINDOW seconds.

Normal small parallel use (2-4 agents) passes untouched. On deny, it feeds Claude a
message telling it to pace into smaller waves and relaunch after the window — and because
well-designed batch jobs write results to disk and resume from what's missing, a denied
launch loses no work.

Tune MAX / WINDOW below.
"""
import sys, os, json, time

MAX = 8         # max Task launches allowed within the window
WINDOW = 120    # rolling window, seconds

LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".subagent-launches.log")

def read_stdin():
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}

def main():
    data = read_stdin()
    # Only throttle the subagent-spawning tool; allow everything else through.
    if data.get("tool_name") not in ("Task", "Agent"):
        return 0

    now = time.time()
    # Append this launch (append is atomic enough for short lines under concurrency).
    try:
        with open(LOG, "a") as f:
            f.write(f"{now}\n")
    except Exception:
        # Never let a logging failure block real work.
        return 0

    # Read all timestamps, keep those within the window.
    recent = []
    try:
        with open(LOG) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    t = float(line)
                except ValueError:
                    continue
                if now - t <= WINDOW:
                    recent.append(t)
    except Exception:
        return 0

    # Best-effort prune so the log can't grow unbounded.
    if len(recent) < 500:  # only rewrite when it's cheap / not racing a huge file
        try:
            with open(LOG, "w") as f:
                f.write("".join(f"{t}\n" for t in recent))
        except Exception:
            pass

    count = len(recent)
    if count > MAX:
        wait = int(WINDOW - (now - min(recent))) + 1
        reason = (
            f"Subagent burst limit: {count} Task launches in the last {WINDOW}s "
            f"(cap {MAX}). This is the guardrail against the fan-out that trips the "
            f"session usage limit. Launch subagents in smaller waves: let the current "
            f"wave finish (results write to disk), then relaunch only the missing "
            f"batches in ~{wait}s. See CLAUDE.md 'Subagent Fan-Out at Scale'."
        )
        out = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }
        print(json.dumps(out))
        return 0

    return 0

if __name__ == "__main__":
    sys.exit(main())
