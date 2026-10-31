# OpenCode task packet template

Codex copies this template into `D:\TrainingArena\tmp\fault-opencode\<task-id>.task.md`, fills every bracketed field, and attaches that completed packet to `opencode run`. This template itself is not a runnable assignment.

```text
You are the OpenCode worker for a bounded Fault website assignment. Codex owns integration and the final decision.

Task ID: [stage-number and short task name]
Outcome: [one concrete result]
Working directory: D:\TrainingArena
Required model: opencode-go/deepseek-v4.1-flash (owner-selected; no automatic substitution)
Mode: [read-only plan / scoped build]

Read only these task inputs plus applicable repository instructions:
[exact file paths, relevant sections, and any small sanitized snapshot]

Settled facts and contracts:
[verified claims, design tokens, component API, event schema, or other constraints needed for this task]

Relevant skill guidance:
[short applicable instructions; exact skill paths only when needed]

Editable files:
[NONE for read-only; otherwise exact source/output paths and optional report path]
Preserve existing edits. If another file or changed contract is necessary, return that dependency to Codex before expanding scope.

Implementation steps:
[small bounded action list]

Checks:
[meaningful commands or evidence required to verify the result]
Prefix every shell command with rtk. Use rtk proxy for unsupported commands. Use local files and the specified commands; service-side writes, deployment, emails, commits, and other workers are outside this assignment. Keep secrets and subscriber data out of outputs.

Return at most 300 words containing outcome, changed/output files, checks with actual results, and blockers. Cite exact file/line evidence for source claims. Put large generated content only in the allowed output file. For read-only mode, return the report as your final response; do not write a report file. If blocked, report the missing input or capability rather than broadening the task.
```
