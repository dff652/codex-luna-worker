---
name: luna
description: Delegate a concrete, bounded coding implementation, bug fix, or small refactor to the luna-worker custom subagent. Use when the user explicitly invokes $luna or asks to hand clear execution work to Luna; keep architecture decisions, ambiguous scoping, final review, and acceptance with the primary agent.
---

# Luna Delegation

Delegate the user's concrete coding task to the `luna-worker` custom agent.

## Workflow

1. Extract the requested implementation, constraints, owned files or modules, and acceptance checks from the user's prompt and current repository context.
2. Keep ambiguous requirements, architecture decisions, destructive actions, and scope expansion with the primary agent. If necessary, reduce a large request to one bounded implementation slice before delegating.
3. Spawn exactly one `luna-worker` for the bounded coding work. Tell it which files or responsibility it owns, that other work may exist in the shared worktree, and that it must not revert or overwrite unrelated edits.
4. Ask it to inspect existing code before editing, make the smallest defensible change, and run the minimum relevant validation.
5. Wait for the worker to finish. Review the actual shared-worktree diff and validation output; do not rely only on its summary.
6. Fix or return follow-up instructions when necessary, then report the final changes, validation, and remaining risks to the user.

Do not run multiple write-capable agents on overlapping files. If `luna-worker` is unavailable, say so explicitly instead of silently substituting another custom agent.
