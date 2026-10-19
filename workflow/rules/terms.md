# Terms

Use these exact terms when talking to the human — never a Vietnamese translation of them
("điểm mù", "cổng người", "lỗi thời"…). The sentence around them stays Vietnamese:
"YC-003 còn một `open question` chặn design".

| Term | Meaning |
|---|---|
| `requirement` | One thing the product must do: `YC-NNN` in `spec.md` |
| `decision` | Technical choice with ≥ 2 options: `D-NN` in `tdd.md`, one approval each |
| `finding` | LLM checker result on the design: `PH-NN` in `design-findings.md` |
| `task` | Plan step: `T-NN` in `plan.md` |
| `business rule` | Approved YC promoted to a product invariant: `BR-<DOMAIN>-NNN` |
| `ADR` | Approved D-xx promoted to `docs/adr/` of the target repo |
| `phase` | One workflow step (`00-intake` … `06-ship`), run by `/aw-<phase>` |
| `utility command` | Non-phase command: `/aw-clarify`, `/aw-import`, `/aw-bootstrap` |
| `job` | One unit of work through the workflow: one branch, one worktree, one job dir |
| `job type` | `Type` in `intake.md`: `feature \| bugfix \| refactor \| perf \| chore` |
| `job dir` | `.agent-workflow/<branch>/` — the job's artifacts |
| `artifact` | File written into the job dir (`spec.md`, `tdd.md`…) |
| `input` | The sources spec reads: `## Input` of `intake.md` |
| `source label` | `[CONFLUENCE]`, `[JIRA]`, `[FILE]`, `[INFERRED]`, `[OPEN-QUESTION]`, `[HUMAN]` |
| `Quote` | Source sentences copied verbatim under a YC's `Source:`, one `> …` line each |
| `open question` | Something the source does not say; agent assumes, human answers: `open-questions.md` |
| `Blocking` | Level of an open question: `blocking`, `review-blocking`, `non-blocking` |
| `Risk` | `high \| normal` in `spec.md`; `high` → design Mode 2 |
| `Mode 1` | Design: agent writes every D-xx, human approves |
| `Mode 2` | Design: human drafts D-xx first, agent only critiques |
| `Promote` | Human marks a D-xx or YC to become durable knowledge |
| `durable knowledge` | What stays true after the job, in the target repo's git: conventions, ADR, BR-, `ARCHITECTURE.md` |
| `machine checker` | `aw check <name>`: exact checks, machine exit of a phase |
| `LLM checker` | Clean-context subagent that writes findings; may only block, never pass |
| `human gate` | Human exit of a phase: state what the human must do, then stop |
| `approval checkbox` | `- [ ] **Approved by human**`; only the human ticks it |
| `approval hash` | `<!-- approval-hash: … -->`; content changed after it → approval needed again |
| `approval guard` | `aw guard` hook that unticks approvals the agent made |
| `block` | `✗` line: violation, the phase does not pass |
| `warn` | `!` line: implement lets it pass, review blocks |
| `entry check` | A checker re-runs the previous phase's checker on its input |
| `based_on` | Hashes of an artifact's inputs (`aw based-on`) |
| `stale` | Artifact built from an older version of its input; rerun the phase that made it |
| `cross-check` | Check across phases (stale, test ↔ YC, diff scope); warn in implement, block in review |
| `harness journal` | `aw journal`: agent mistakes no checker caught |
| `engine` | Checkers, phases, templates, adapters, cached in `~/.agent-workflow/engine/<V>/` |
| `wrapper` | `aw` installed once per machine; picks the version, verifies, dispatches |
| `pinned version` | `Engine: <V>` in `intake.md`; every check of the job runs it |
| `adapter` | Generates `/aw-*`, subagents, skills for one agent from the phase files |
| `target repo` | The project repo running the workflow |
| `main checkout` | The original clone, always on `base_branch` |
| `worktree` | The job's own `git worktree`, outside the repo |
| `base` | Branch/commit the job forks from; chosen by the human |
| `fresh session` | New agent session with no earlier chat; every phase must work from one |
| `clean context` | Same as fresh session; mandatory for review and LLM checkers |
