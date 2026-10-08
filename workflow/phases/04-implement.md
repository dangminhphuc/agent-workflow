---
id: implement
name: Hiện thực
summary: Bước 5/6 · Làm từng task trong plan.md; task chỉ xong khi test xanh
required: true
inputs:
  - intake.md
  - plan.md
  - tdd.md
  - spec.md
outputs:
  - diff
  - plan.md (task status updated)
  - task-results.md
  - test-results.md
  - security-results.md
exit_machine:
  - aw check implement
exit_human: []
needs_clean_context: false
---

# Phase 04 — Implement

## Goal

Do each task in `plan.md` following `tdd.md`, **without leaving scope**. The typical agent failure here is not wrong code but scope creep (fixing things "while there", changing signatures, tidying files).

## Input

- `plan.md` — the only source of work; passes `aw check plan`.
- `tdd.md` — how (contract, data, flow, D-xx). `spec.md` — *why*, when needed.
- `../conventions.md` — test file patterns, `covers:` tag syntax, base branch.
- `aw rules implement` — coding style, patterns; read all. `aw uses implement` — repo skills / subagents to invoke. Both **before the first task**.

## Steps

0. **`aw ready <thư-mục-feature>` before the first task.** Tests red on untouched code = environment not prepared (`WORKTREE_SETUP_CMD`) or broken base → **stop, tell the human**. Never fix/disable existing tests.
1. **One task at a time, state kept by the machine** — never edit `Status` yourself, never batch tasks:
   - `aw task next <thư-mục-feature>` — next task (one in `[~]` comes first);
   - `aw task start <thư-mục-feature> T-NN` — `[ ]` → `[~]` (refused if another task is `[~]` or a dependency is not `[x]`);
   - `aw task done <thư-mục-feature> T-NN` — runs the backticked `Verify` command, writes output to `task-results.md`; only **green** moves to `[x]`. Manual-only verify: `--manual "<what you did, what you saw>"`.
   - `[x]` without green evidence matching the current `Verify` → `aw check implement` blocks (also when `Verify` is edited afterwards).
2. **Tag tests** per `conventions.md` (e.g. `// covers: YC-001`). YC not testable automatically → `plan.md` "Manual verification" + reason.
3. **Verify right after each task** (`aw task done`). Red → fix within that task, rerun. Red `MAX_RED_RUNS` times in a row (default 3) → machine says **DỪNG**: record what you tried and the error in "Unplanned", tell the human.
4. **Something the plan did not foresee → stop and report.** Record it in `plan.md` "Unplanned". Touches a D-xx → reopen that D in `02-design`, not here.
5. **Follow repo rules** in code you write. A rule asking for work outside the task or contradicting `tdd.md` → don't; record in "Unplanned".
6. **Keep the diff in scope.** Touch files outside "Expected files" only when unavoidable — record the file (in backticks) + reason in "Unplanned".
   - The ADR task: `aw adr promote <thư-mục-feature> D-NN` — never write or edit an ADR by hand (the machine compares it with the approved D).
   - The rule task: `aw rule promote <thư-mục-feature> YC-NNN` — never write or edit a `BR-` block by hand (the machine compares it with the approved YC).
7. **`aw check implement`** — runs the test command and security scans (`SECURITY_CMDS`, same as CI) itself and writes `test-results.md`, `security-results.md` (never write these yourself). Scans only: `aw check security <thư-mục-feature>`.

## Running as a loop (optional)

No human gate, so it can run unattended:

```
loop:
  T = aw task next <dir>
      HẾT TASK  → aw check implement → ĐẠT: stop, report
                                       KHÔNG ĐẠT: fix that violation, rerun
      KẸT, DỪNG → stop, tell the human
  aw task start <dir> T
  do T (only within T's "Expected files")
  aw task done <dir> T
      ĐỎ   → fix within T, rerun done
      DỪNG → record "Unplanned", stop, tell the human
```

Stop immediately when: something unforeseen (recorded in "Unplanned"); a file outside "Expected files" is needed; `tdd.md`/`spec.md` must change or a D-xx reopened; `aw check implement` fails on the same violation twice in a row.

## By work type — blocking

| Type | Order / rule | Machine checks |
|---|---|---|
| `bugfix` | Write repro test → `aw check repro <thư-mục-feature>` **before touching code** → then fix | `repro.md`: test red while the diff touches only test files. Missing or green → block |
| `refactor` | Never delete old tests; declare edited ones in "Modified existing tests" | Deleted → block; undeclared edit → warn |
| `perf` | Like refactor; `aw check perf <thư-mục-feature> --before` **before the change**, `--after` after | `perf.md` missing a measurement → block |
| `chore` | No production code; declare "Dependency upgrades" | Touches `production_code` → block; touches `dependency_files` undeclared, declared major, or no green `sca` command in `security-results.md` → block |

Forgot `repro`/`--before` and already changed code → the script **refuses**: `git stash`, rerun, `git stash pop`.

## Cross-checks — warn here, `review` blocks

| Warning | Fix |
|---|---|
| YC without a `covers:` test | Add a test, or "Manual verification" + reason |
| Changed file outside "Expected files"/"Unplanned" | Revert, or "Unplanned" + reason |
| Stale artifact (`based_on` hash mismatch) | Rerun the phase that produced it |
| Work type vs branch prefix mismatch | Fix `intake.md`, or `aw rename` |
| refactor/perf: old test edited, undeclared | Declare in "Modified existing tests", or revert |
| `review-blocking` question still open | Ask the human to run `clarify` — never answer it yourself |
| **New** test line with `.only(`, `.skip(`, `xit(`, `@Disabled`… (`skipped_test_regex`) | Remove it; if really needed, record the file in "Unplanned" + reason |
| Durable knowledge may be stale: diff touches the scope of a module doc / ADR / rule file that did not change | Update that doc if the change makes it wrong; otherwise `review` gives a verdict |
| Active `BR-` rule in the diff's scope has no `covers:` test | Add a test tagged `covers: BR-…` (warning only) |

## Output

- Code changes; `plan.md` updated (status, "Unplanned", "Manual verification").
- Written by the machine: `task-results.md` (per-task evidence), `test-results.md`, `security-results.md` (real output with `HEAD`, `Tree`, time). Changing code afterwards, even uncommitted → review blocks until rerun.

## Forbidden

- Work not in `plan.md`; starting a task while another is `[~]`.
- Editing `Status` yourself or writing `task-results.md`.
- Editing `tdd.md`/`spec.md` — if wrong, stop and report.
- **Declaring done without running tests.**
- Editing/disabling tests to go green. An old test really wrong → "Unplanned".
- `covers:` on a test that does not really check that YC.
- Ignoring lint/type errors as "unrelated".
- Making scans green by loosening tools (`nosemgrep`, `.gitleaksignore`, `.trivyignore`, lower thresholds, removing lines from `SECURITY_CMDS`). Real false positive → "Unplanned" + evidence; the human decides.

## Exit conditions — there is no separate test phase: not green = not done

**Machine:** `aw check implement` → `[x] ĐẠT` — input passes `aw check plan`; test command and every scan **XANH** with real output in `test-results.md` / `security-results.md`; each `Promote: adr` D has an ADR matching the approved D; each `Promote: BR-…` YC has a rule block matching the approved YC; **every** task `[x]` with green evidence matching the current `Verify`; no merge conflict markers. No test or scan command configured → **KHÔNG ĐẠT**, not "skipped".

## When the agent fails and no checker caught it

```
aw journal add <task|context|env|verify|state|model> "<what went wrong, where, what the harness lacks>"
```
