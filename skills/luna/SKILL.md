---
name: luna
description: Delegate bounded coding work to a versioned Luna worker. Use for $luna or requests to assign work to luna6-worker or luna56-worker; keep ambiguous scoping and final acceptance with the primary agent.
---

# Luna Delegation

Delegate the user's concrete coding task to one versioned Luna agent:

- `luna6-worker` uses `gpt-6-luna` when the user names `luna6-worker` or explicitly requests GPT-6 Luna.
- `luna56-worker` uses `gpt-5.6-luna` when the user names `luna56-worker` or explicitly requests GPT-5.6 Luna. Plain `$luna` and unversioned "luna-worker" requests also use this agent for compatibility.

If the user names both versions without choosing one, clarify which version should execute the task before spawning. Never silently substitute one version for the other.

## Workflow

1. Extract the requested implementation, constraints, owned files or modules, and acceptance checks from the user's prompt and current repository context.
2. Keep ambiguous requirements, architecture decisions, destructive actions, and scope expansion with the primary agent. If necessary, reduce a large request to one bounded implementation slice before delegating.
3. Spawn exactly one selected Luna agent for the bounded coding work. Tell it which files or responsibility it owns, that other work may exist in the shared worktree, and that it must not revert or overwrite unrelated edits.
4. Ask it to inspect existing code before editing, make the smallest defensible change, and run the minimum relevant validation.
5. Wait for the worker to finish. Review the actual shared-worktree diff and validation output; do not rely only on its summary.
6. Fix or return follow-up instructions when necessary, then report the final changes, validation, and remaining risks to the user.

Do not run multiple write-capable agents on overlapping files. If the selected agent is unavailable, say so explicitly instead of silently substituting another agent or model. Include the selected agent and model in the final report.
