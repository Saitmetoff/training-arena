# Fault — Codex and OpenCode delegation

This is the required execution policy for every stage in `D:\TrainingArena\docs\FAULT_WEBSITE_PROMPTS.md`. The owner requested that Codex use OpenCode for specified smaller or repetitive, context-heavy tasks to reduce Codex usage, and selected **OpenCode Go** as the provider and **DeepSeek V4.1 Flash** as the model.

## Ownership

Codex owns task decomposition, positioning, design direction, architecture, security-sensitive implementation, external-service operations, integration, final review, and release decisions. OpenCode executes the bounded work listed in each stage prompt. Codex invokes OpenCode itself; the user should not have to manually ferry worker prompts or results.

The stage's required OpenCode assignments MUST be delegated through the OpenCode CLI when the tool/provider is working. They are not optional suggestions. On a rerun, reuse an accepted assignment's artifacts if its inputs have not changed; record that reuse rather than paying to regenerate it. A plain CLI/parser is still the right tool for deterministic counting, file searches, formatting, and log filtering; batch their results into an OpenCode assignment only when synthesis or editing is needed.

If OpenCode is unavailable, authentication fails, permissions block the task, or Go quota is exhausted, record the concrete blocker and continue independent Codex-owned work. Do not silently claim delegation occurred, switch provider, buy credits, or use a different model tier. The unresolved delegated assignment remains visible in the handoff.

## Model routing

Use the explicit `--model opencode-go/deepseek-v4.1-flash` argument for every assignment so tasks do not inherit an unknown last-used model:

| Assignment | Default model |
| --- | --- |
| Evidence inventories, short summaries, copy variants, sanitized report triage, content drafts | `opencode-go/deepseek-v4.1-flash` |
| Components from a finished specification, scoped CSS fixes, meaningful regression cases, local asset-processing helpers | `opencode-go/deepseek-v4.1-flash` |

This is the owner's required model for both text and coding tasks. Its ID was listed by the installed CLI and DeepSeek V4.1 Flash was listed in the [OpenCode Go documentation](https://opencode.ai/docs/go/) on 4 October 2026. Verify access at the first actual worker dispatch. Provider credentials being present does not prove model access or remaining quota. Do not substitute another model automatically; only an explicit later owner selection changes this requirement.

Use the OpenCode Go provider only. Keep global OpenCode configuration and credentials unchanged. `small_model` is not the delegated-task selector: OpenCode documents it for auxiliary work such as title generation. Pass the task model explicitly instead. [Configuration reference](https://opencode.ai/docs/config/).

## Dispatch procedure

1. **Scope before reading broadly.** Identify a coherent assignment from the current stage. Use file search and metadata to select inputs; let the worker do the specified inventory/synthesis rather than doing the entire inventory yourself first. Codex still checks the sources behind consequential conclusions.
2. **Write a small task packet.** Start from `D:\TrainingArena\prompts\fault-website\opencode-task-template.md`. Fill in one outcome, the selected model, exact read paths, exact editable paths or read-only mode, settled decisions, relevant constraints, acceptance checks, and report destination. Keep it around 400–800 words unless the task truly needs more. Include necessary repository instructions, including the `rtk` shell prefix. Do not attach the whole chat, entire repository, all stage prompts, or every skill.
3. **Pass only applicable knowledge.** Codex loads the stage skills and gives OpenCode the relevant implementation rules and, when needed, exact local skill paths for at most a few relevant references. OpenCode does not automatically inherit Codex's chat, tools, MCP authentication, or skills. Codex uses its MCP connections to obtain concise relevant documentation or sanitized input snapshots. The worker uses local files and approved CLI commands; no duplicate MCP setup is needed.
4. **Protect existing work.** Record the existing diff for the allowed files before dispatch. Use one worker at a time in this shared checkout and leave its editable paths alone until it finishes. Give file-level ownership, not permission to reorganize the repository. Read-only assignments use the `plan` agent; editing assignments use `build` with an explicit file allowlist. Prompt allowlists are instructions, not an OS sandbox.
5. **Invoke the CLI.** Use a new session for an unrelated assignment. Reuse a session only for a bounded correction to the same task. Save the event stream locally under `D:\TrainingArena\tmp\fault-opencode\`; create the directory before redirecting logs. Read only the compact final response/report into Codex, opening raw log excerpts when diagnosing a failure. Long logs stay local and out of source control.
6. **Review and accept.** Inspect the actual new diff against the pre-dispatch baseline, source citations for important claims, and the relevant check output. Worker assertions alone are not proof. Fix or reject out-of-scope changes without discarding pre-existing user work. Rerun checks when integration or new evidence warrants it. Codex owns the final stage handoff.

The installed Windows CLI was checked as version 1.18.34 and exposes `run`, `--dir`, `--model`, `--agent`, `--file`, and `--format json`. The `.cmd` shim is available, avoiding PowerShell wrapper ambiguity. Recheck `run --help` if a later version changes the interface. [CLI reference](https://opencode.ai/docs/cli/).

For a prepared read-only task packet, Codex runs this command through its shell tool:

```powershell
rtk proxy opencode.cmd run 'Complete only the attached task. Return the requested compact report.' --dir 'D:\TrainingArena' --model 'opencode-go/deepseek-v4.1-flash' --agent plan --format json --file 'D:\TrainingArena\tmp\fault-opencode\01-inventory.task.md' > 'D:\TrainingArena\tmp\fault-opencode\01-inventory.events.jsonl'
```

For a scoped implementation packet, substitute the actual packet/log paths and `--agent build`; keep `--model opencode-go/deepseek-v4.1-flash`. Store multiline task text in the packet rather than embedding it into the shell command. Do not use automatic session sharing or blanket permission bypass flags. If a permission prompt prevents noninteractive completion, report the blocked operation and narrow the task or use existing permissions.

For read-only work, Codex saves the compact final response to the planned report file; the worker itself does not write files. Editing workers may write a report only to the exact allowed report path. Keep source, reports, and raw events distinct.

## Keep overhead bounded

- Batch related inventory, copy, or component work into a single coherent assignment. A five-second shell action does not need an LLM worker.
- Give the worker the settled design/API contract. Do not delegate unresolved architecture merely because it is token-heavy.
- Request a final report of at most 300 words: outcome, changed/output files, evidence/checks, and blockers. Large generated content belongs in a file; reference its path instead of echoing it into Codex's context.
- Allow one initial attempt and at most one focused correction per assignment. After that, Codex diagnoses the failure and either completes the repair or reports the external blocker. Do not recursively launch workers.
- Never run Codex and OpenCode through the same broad analysis just to compare them. Review the evidence needed to accept the work.
- Run local tests/builds through ordinary commands. OpenCode is useful for diagnosing substantial output and implementing a specified fix, not for restating a successful build.
- Keep production credentials, subscriber-level data, and raw email lists out of worker packets. Codex supplies aggregate or synthetic inputs and retains service-side operations.

OpenCode runs still consume their own provider allowance. This workflow is intended to reduce Codex usage; total tokens or monetary savings are not guaranteed. Record available usage from worker events or OpenCode statistics as reported, with provider/model and units. A reported zero-dollar subscription run is not zero token consumption. Never invent a percentage saved or a hard token cap unsupported by the CLI.

## Responsibilities by stage

| Stage | Required OpenCode work | Codex retains |
| --- | --- | --- |
| 1. Brief | Source/asset inventory with file-and-line citations; factual copy/FAQ variants from the verified facts Codex supplies | Verification of material claims, audience and positioning decisions |
| 2. Design | Compare supplied design references; produce token/component inventories and routine layouts from Codex's chosen specifications | Three creative directions, wordmark judgment, visual review and recommendation |
| 3. Build | Bounded presentational components, email-template markup from approved copy, event-name mapping, and scoped meaningful regression cases | Architecture, schema/RLS decisions, server-side signup and token flow, webhook/security review, live MCP writes |
| 4. Polish | Specified CSS/responsive adjustments, metadata and caption-formatting helpers, repetitive motion states after the signature pattern is fixed | Signature animation, final copy/footage selection, visual and motion quality |
| 5. Release | Summarize sanitized build/accessibility/performance reports; fix allowlisted low-risk defects; assemble the evidence index | Relevant independent verification, sensitive fixes, DNS, production configuration and deployment |
| 6. Growth | Summarize aggregate exports, draft hook/script/caption variants and email copy, populate the content calendar | Interpretation of metrics, experiment choice, claim accuracy, any approved publishing/sending |

Batch assignments when their dependencies are ready. Do not send facts for copy drafting before Codex verifies them, or ask the worker to implement a component before its contract exists.

## Evidence in every stage handoff

Add an `OpenCode delegation` section to the stage's existing handoff, containing:

- Assignment ID and status: accepted, reused, rejected, or blocked.
- Actual provider/model, session ID if available, and local task/report/log paths.
- Files or output produced and the checks supporting acceptance.
- Reported usage if available; otherwise `not reported`.
- Any work Codex repaired or completed after the bounded worker attempts.

A stage is not fully complete while a required assignment is unresolved. If a worker is blocked, distinguish finished independent work from the remaining dependency and tell the user exactly what prevented completion.
