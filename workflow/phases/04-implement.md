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
  - plan.md (task status, "Unplanned", "Manual verification")
  - task-results.md (written by aw task done)
  - test-results.md (written by aw check implement)
  - security-results.md (written by aw check implement)
exit_machine:
  - aw check implement
exit_human: []
needs_clean_context: false
---

# Phase 04 — Implement

## Goal

Do each task in `plan.md` per `tdd.md`, **without leaving scope**. The typical failure is not wrong code but scope creep: fixing things "while there", changing signatures, tidying files.

`plan.md` is the only source of work; `tdd.md` says how (contract, data, flow, D-xx); `spec.md` says why. Test file patterns and `covers:` syntax: conventions.

## Steps

**Before the first task:** `aw ready <dir>`. Tests red on untouched code = environment not prepared (`WORKTREE_SETUP_CMD`) or broken base → **stop, tell the human**.

1. **One task at a time; the machine keeps state:**
   - `aw task next <dir>` — next task (one in `[~]` comes first);
   - `aw task start <dir> T-NN` — `[ ]` → `[~]` (refused if another task is `[~]` or a dependency is not `[x]`);
   - `aw task done <dir> T-NN` — runs the task's backticked `Verify` command and records it in `task-results.md`; only **green** → `[x]`. Manual-only verify: `--manual "<what you did, what you saw>"`.
2. **Tag tests** `covers: YC-NNN` (syntax per conventions). YC not testable automatically → `plan.md` "Manual verification" + reason.
3. **Red** → fix within that task, rerun `aw task done`. Machine says **DỪNG** (`MAX_RED_RUNS` reds in a row, default 3) → record what you tried and the error in "Unplanned", tell the human.
4. **Unforeseen → stop and report** in `plan.md` "Unplanned". Touches a D-xx → reopen it in `/aw-design`, not here.
5. **Keep the diff in scope.** A file outside the task's "Expected files" only when unavoidable → "Unplanned" (path in backticks + reason). Follow repo rules in code you write; one asking for out-of-task work or contradicting `tdd.md` → don't; "Unplanned".
6. **Promote tasks — never write by hand** (the machine compares with the approved item): ADR → `aw adr promote <dir> D-NN`; business rule → `aw rule promote <dir> YC-NNN`.
7. **`aw check implement <dir>`** runs the tests and security scans (`SECURITY_CMDS`, same as CI) and writes the results files. Code changed afterwards, even uncommitted → rerun. Scans only: `aw check security <dir>`. Its warnings block `/aw-review`, not this phase; each names its fix — fix now.

### Unattended loop (optional)

```
loop:
  T = aw task next <dir>
      HẾT TASK  → aw check implement <dir> → ĐẠT: stop, report
                                             KHÔNG ĐẠT: fix that violation, rerun
      KẸT, DỪNG → stop, tell the human
  aw task start <dir> T
  do T (only within T's "Expected files")
  aw task done <dir> T
      ĐỎ   → fix within T, rerun done
      DỪNG → record "Unplanned", stop, tell the human
```

Also stop when `tdd.md`/`spec.md` must change, or `aw check implement` fails on the same violation twice in a row.

## By work type

| Type | Order / rule | Machine blocks when |
|---|---|---|
| `bugfix` | Write the repro test → `aw check repro <dir>` **before touching code** → then fix | `repro.md` missing, or the test was green / the diff touched non-test files |
| `refactor` | Never delete old tests; declare edited ones in "Modified existing tests" | An old test is deleted |
| `perf` | Like refactor; `aw check perf <dir> --before` **before the change**, `--after` after | `perf.md` misses a measurement |
| `chore` | No production code; declare "Dependency upgrades" | Touches `production_code`; touches `dependency_files` undeclared, declared major, or without a green `sca` scan |

Forgot `repro`/`--before` and already changed code → the script refuses: `git stash`, rerun, `git stash pop`.

## Forbidden

- Work not in `plan.md`; editing `Status` or any `*-results.md` yourself.
- Editing `tdd.md`/`spec.md` — if wrong, stop and report.
- **Declaring done without running tests.**
- Editing or disabling tests to go green (`.only(`, `.skip(`, `@Disabled`…). An old test really wrong → "Unplanned".
- `covers:` on a test that does not really check that YC.
- Ignoring lint/type errors as "unrelated".
- Making scans green by loosening tools (`nosemgrep`, `.gitleaksignore`, `.trivyignore`, lower thresholds, removing lines from `SECURITY_CMDS`). Real false positive → "Unplanned" + evidence; the human decides.

## Common failures

- No test or scan command configured → `KHÔNG ĐẠT`, not "skipped": ask the human to set `TEST_CMD` / `SECURITY_CMDS`.
- `Verify` edited after the task went `[x]` → evidence no longer matches: rerun `aw task done`.
- Merge conflict markers left in the diff.
