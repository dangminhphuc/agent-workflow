---
id: bootstrap
name: Đưa kiến thức repo vào git
summary: Một lần cho mỗi repo: AGENTS.md, Makefile, ARCHITECTURE.md, ADR có sẵn — để phiên agent mới chỉ cần repo, không phải đoán
argument_hint: (không tham số)
runs_on_main_checkout: true
---

# Make the repo the system of record (bootstrap)

**Not a phase** — once per repo, or after a big layout change. Goal: a fresh agent session with **only the repo** (no chat, Jira, Confluence, no asking people) answers, each from a committed file:

1. What is this system? → `AGENTS.md`
2. How is it organised, and why? → `AGENTS.md` § Map, module `ARCHITECTURE.md`, ADR directory
3. How to run it? → `make setup`
4. How to verify it? → `make test`, `make lint`, `make security` (the commands CI runs)
5. Where are we now? → `AGENTS.md` § Status, pointing to where progress lives

This is **putting decisive information where it is found**, not writing more docs. Talk to the human in Vietnamese; files you write are Vietnamese except fixed headings (`## Map`, `## Commands`, `## Rules`, `## Decisions`, `## Status`, `## Decision`, `## Sources`).

## On the main checkout

Step 0 says **ĐANG Ở CHECKOUT CHÍNH** → only this section; write nothing in the main checkout.

1. Run `aw doctor`, `aw conventions check`, `aw adr check`, `aw rule check`; summarise the labels in 3–5 lines.
2. Propose a worktree as in `/aw-intake` "Create the worktree": type `chore` (docs, Makefile, CI only), description `agent-knowledge`. `aw worktree new chore agent-knowledge` prints the proposal; show it verbatim; the **human picks the base**; then `--create --base <exact ref>`.
3. Stop: the human runs the printed prepare command and opens a **new** session in the worktree, then runs this command again. No `intake.md` is needed.

## In the worktree

Report file: `<dir>/bootstrap.md` (outside git). One commit per step below, on this branch; before each commit run that step's checks — red → do not commit.

### 1. Survey (write nothing in the repo)

Read README, existing `docs/`, CI pipeline files, build manifests, the top two directory levels, `git log --oneline -200` (framework switches, module splits, migrations). Build the **knowledge table** in the report: one row per important decision or constraint — content, evidence (`file:line` or commit sha), in repo already? (yes / no), where it belongs.

### 2. Conventions

`aw conventions check`. `docs/agent-workflow/conventions.md` not committed on the base but present in the main checkout (created by `aw init`) → copy it **unchanged** into this worktree and commit it. Values that look wrong for this repo (`test_files`, `production_code`, `sensitive_code`, `knowledge_*`) → list in the report with evidence; the human edits them (this job reads the main checkout's copy until merged).

### 3. `Makefile`

None → copy `templates/target-repo/Makefile`. Exists → add missing targets only: `setup test lint security security-secret security-sast security-sca`. Each target runs **exactly the command CI runs** (read the pipeline). No equivalent → keep `chua_khai` (exit 1) and list it in the report — never a target that is green by default. Switch CI to call `make …` only if CI behaviour stays identical. Report the `config.sh` lines each teammate sets locally: `TEST_CMD="make test"`, `SECURITY_CMDS` with `secret: make security-secret` etc.

Check: `make setup`, `make test`, `make lint` on this worktree; record the real outcome.

### 4. `AGENTS.md` (+ `CLAUDE.md`)

None → copy `templates/target-repo/AGENTS.md`, fill every `<…>`, delete the leading comment block; a section that does not apply says `None`. **50–100 lines; points to, never copies rules.** `## Map`: one line per top-level directory. `## Commands`: only `make …`. `## Rules`: hard repo-wide constraints, one checkable line each, each with evidence. `## Decisions`: ADR directory index and module `ARCHITECTURE.md` files. `## Status`: where real progress lives (issue tracker, milestones, plans directory) — agent-workflow job state is outside git, never copied here. Repo uses Claude Code and has no `CLAUDE.md` → one line `@AGENTS.md`.

### 5. Module `ARCHITECTURE.md`

Only for a module with **its own constraints backed by evidence**: dependency boundaries, who may call the DB, data formats, concurrency invariants, public API to keep. Nothing specific → no file. ≤ 50 lines: responsibility, outward interface, constraints (each with `file:line`), what is forbidden. Put it in the module's directory, name matching `knowledge_files`. Its scope is the directory holding it — later diffs touching it without updating it get flagged, so do not place it too high.

### 6. Existing decisions → ADR

New decisions go through D-xx + `- Promote: adr` + `aw adr promote`. Here: only decisions that **already exist**, are still in force, and have evidence. One file per decision, `<knowledge_adr_dir>/NNNN-<name>.md`, numbered after the highest existing:

```markdown
# ADR-NNNN: <title>

- Status: accepted
- Date: <date of the evidence>
- Scope: `<glob of the code it constrains>`
- Origin: <commit sha or original document>

## Decision

<Decision, context, rejected options — only what the evidence shows.>

## Sources

- <commit / file / versioned link>
```

Add a row per ADR to the index `README.md` table `| ADR | Title | Status | Scope |` (`| [NNNN](NNNN-….md) | <title> | accepted | \`<scope>\` |`), keeping text above the table. No evidence for the "why" → **no ADR**, a question in the report. Check: `aw adr check` → HỢP LỆ.

### 7. Business rules — candidates only

Find business invariants in code and tests (limits, valid states, permissions). **Do not** write `BR-` blocks: they need a versioned source and human approval, and enter through `/aw-spec` (`- Promote: BR-<DOMAIN>-NNN`) in the next job that touches them. List in the report: rule, evidence, proposed domain, who has authority to confirm. Check: `aw rule check` no worse than on the main checkout.

### 8. Fresh-session test

Hand the repo to a **blank-context** session (a subagent if your agent has one; otherwise ask the human to open a new session) and ask the five questions above plus "What must I respect when changing `<module>`?" and "What quality bar must pass before merge?". Record answers and the files used. Wrong, guessed, or needed many files → fix the map (usually a missing pointer in `AGENTS.md`), commit, retry — at most 3 rounds; remaining gaps go in the report.

## Finish

1. Rerun `aw conventions check`, `aw adr check`, `aw rule check`, `make test`, `make lint`; paste the real labels.
2. Complete the report: knowledge table with a before/after column; **visibility gap** = rows still outside the repo / all rows; questions for the human (missing "why", `BR-` candidates, `chua_khai` targets, convention values), each with evidence and a proposed answer; last fresh-session result; per-teammate `config.sh` lines.
3. Tell the human: branch ready, report path, use the report as the PR description. Push or open a PR only if the human asks; never merge. After merge: `aw worktree remove` from the main checkout.

## Forbidden

- **Inventing knowledge**: anything without evidence in the repo goes to the report as a question, never into a file.
- Copying rules into `AGENTS.md`, or copying PRD/Confluence text into the repo — each rule lives in one place.
- Overwriting what people wrote: edit existing `AGENTS.md`, `CLAUDE.md`, `Makefile`, `ARCHITECTURE.md` minimally; fix only what contradicts the code, and say so in the report.
- Writing `BR-` blocks, ticking approval boxes, editing production code or tests.
- Committing in the main checkout; committing a step whose checks are red.
