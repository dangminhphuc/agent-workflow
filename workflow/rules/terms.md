# Terms

Name workflow concepts with these exact terms — in chat with the human and in the Vietnamese body text
of artifacts. Never use a Vietnamese translation of them; column `Not` lists the ones seen before.
The sentence around a term stays Vietnamese: "REQ-003 còn một `open question` chặn design".

`aw check implement` warns and `aw check review` blocks on a `Not` phrase in an artifact (except
`intake.md`, `refactor-requests.md`, `*-results.md` and `>` quote lines, which hold the human's words).

| Term | Meaning | Not |
|---|---|---|
| `requirement` | One thing the product must do: `REQ-NNN` in `spec.md` | |
| `decision` | Technical choice with ≥ 2 options: `DEC-NNN` in `tdd.md`, one approval each | |
| `finding` | LLM checker result: `FND-NNN` in `spec-findings.md` or `design-findings.md` | |
| `task` | Plan step: `TSK-NNN` in `plan.md` | |
| `review finding` | Review `Blocker` / `Should fix` item: `RVW-NNN` in `review.md`; a fix task names it in `Fixes:` | |
| `refactor request` | Human's refactoring wish, recorded only: `RFR-NNN` in `refactor-requests.md` | |
| `business rule` | Approved REQ promoted to a product invariant: `BR-<DOMAIN>-NNN` | luật nghiệp vụ bền |
| `ADR` | Approved DEC-xxx promoted to `docs/adr/` of the target repo | |
| `phase` | One workflow step (`00-intake` … `06-ship`), run by `/aw-<phase>` | |
| `stage` | One step of the SDLC interface (`sdlc/stages/`: plan … operate); a phase `implements:` one | |
| `stage status` | How fully the engine implements a stage: `implemented \| partial \| gap`, derived from the capabilities its phases claim (`tools/check-sdlc.sh`) | |
| `invariant` | Cross-stage rule `INV-NNN` in `sdlc/invariants.md`, enforced by a machine checker | |
| `capability` | What a stage must do when complete: `CAP-<stage>-NN` in `sdlc/stages/`; a phase claims it in `capabilities:` | |
| `profile` | What a job type changes in the SDLC interface: stages skipped, artifacts and invariants added (`sdlc/profiles/<job-type>.md`) | |
| `utility command` | Non-phase command: `/aw-clarify`, `/aw-import`, `/aw-bootstrap` | lệnh tiện ích |
| `job` | One unit of work through the workflow: one branch, one worktree, one job dir | |
| `job type` | `Type` in `intake.md`: `feature \| bugfix \| refactor \| perf \| chore` | loại việc |
| `job dir` | `docs/sdlc/<branch>/` — the job's artifacts; committed on the job branch, removed from it before the MR | thư mục việc |
| `artifact` | File written into the job dir (`spec.md`, `tdd.md`…) | |
| `input` | The sources spec reads: `## Input` of `intake.md` | |
| `source label` | `[CONFLUENCE]`, `[JIRA]`, `[ISSUE]`, `[FILE]`, `[INCIDENT]`, `[INFERRED]`, `[OPEN-QUESTION]`, `[HUMAN]` | nhãn nguồn |
| `Quote` | Source sentences copied verbatim under a REQ's `Source:`, one `> …` line each | |
| `open question` | Something the source does not say; agent assumes, human answers: `### Q-NNN` in `open-questions.md`, covering one or more REQs | điểm mù |
| `Blocking` | Level of an open question: `blocking`, `review-blocking`, `non-blocking` | mức chặn |
| `Risk` | `high \| normal` in `spec.md`; `high` → design Mode 2 | |
| `Mode 1` | Design: agent writes every DEC-xxx, human approves | |
| `Mode 2` | Design: human drafts DEC-xxx first, agent only critiques | |
| `Design: skip` | Small bugfix/refactor skips design; plan works from spec | |
| `Promote` | Human marks a DEC-xxx or REQ to become durable knowledge | |
| `ref` | Pointer to a durable-knowledge block: `<file>` or `<file>#<anchor>` (anchor = verbatim `##` heading or `BR-…` id) | |
| `durable knowledge` | What stays true after the job, in the target repo's git: conventions, ADR, BR-, `ARCHITECTURE.md` | kiến thức bền |
| `machine checker` | `aw check <name>`: exact checks, machine exit of a phase | checker máy |
| `LLM checker` | Clean-context subagent that writes findings; may only block, never pass | checker llm |
| `human gate` | Human exit of a phase: state what the human must do, then stop | cổng người, gate người |
| `approval checkbox` | `- [ ] **Approved by human**`; only the human ticks it | ô duyệt |
| `approval hash` | `<!-- approval-hash: … -->`; content changed after it → approval needed again | dấu duyệt |
| `approval guard` | `aw guard` hook that unticks approvals the agent made | gác ô duyệt |
| `block` | `✗` line: violation, the phase does not pass | |
| `warn` | `!` line: implement lets it pass, review blocks | |
| `Kết quả` | Last block of every `aw` output; read its `[x]` label, not the exit code | |
| `entry check` | A checker re-runs the previous phase's checker on its input | |
| `based_on` | Hashes of an artifact's inputs (`aw based-on`) | |
| `stale` | Artifact built from an older version of its input; rerun the phase that made it | lỗi thời |
| `cross-check` | Check across phases (stale, test ↔ REQ, diff scope); warn in implement, block in review | kiểm chéo |
| `covers:` | Test tag linking a test to a REQ or BR- | |
| `Expected files` | Diff boundary of a task; others go to `## Unplanned` | |
| `Tree` | Code tree hash a result (test, scan, review) belongs to | |
| `Lens 1–4` | The four angles of `review.md`: spec, design and scope, quality, security | |
| `Blocker` | Review finding: must not merge | |
| `Should fix` | Review finding: should be fixed | |
| `Nit` | Review finding: author decides | |
| `Security reviewer` | Name of the human who reviewed security; the agent never fills it | |
| `DỪNG` | `aw task` label: `MAX_RED_RUNS` red runs in a row; report to the human | |
| `KẸT` | `aw task` label: every remaining task waits on a dependency; report to the human | |
| `harness journal` | `aw journal`: agent mistakes no checker caught | nhật ký harness |
| `retro` | `aw journal retro`: end-of-job summary written to `jobs.tsv`; human part (wrong blocks, minutes) entered by the human | tổng kết cuối việc |
| `engine` | Checkers, phases, templates, adapters, cached in `~/.agent-workflow/engine/<V>/` | |
| `wrapper` | `aw` installed once per machine; picks the version, verifies, dispatches | |
| `pinned version` | `Engine: <V>` in `intake.md`; every check of the job runs it | version ghim |
| `adapter` | Generates `/aw-*`, subagents, skills for one agent from the phase files | |
| `target repo` | The project repo running the workflow | repo đích |
| `main checkout` | The original clone, always on `base_branch` | checkout chính |
| `worktree` | The job's own `git worktree`, outside the repo | |
| `base` | Branch/commit the job forks from; chosen by the human | |
| `conventions.md` | Target repo conventions, in git; a job reads the version at its fork point | |
| `config.sh` | Per-clone config, not committed: `TEST_CMD`, `SECURITY_CMDS`, `ADAPTER`… | |
| `rules_<phase>` | `conventions.md` key: files the agent reads in that phase | |
| `uses_<phase>` | `conventions.md` key: skills/subagents the agent calls in that phase | |
| `production_code` | `conventions.md` glob: production files | |
| `test_files` | `conventions.md` glob: test files | |
| `sensitive_code` | `conventions.md` glob: files that need a `Security reviewer` | |
| `fresh session` | New agent session with no earlier chat; every phase must work from one | phiên trắng |
| `clean context` | Same as fresh session; mandatory for review and LLM checkers | ngữ cảnh sạch |
