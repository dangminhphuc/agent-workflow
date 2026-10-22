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
  - repro.md (bugfix — written by aw check repro)
  - perf.md (perf — written by aw check perf)
implements: implement
provides:
  - change: diff
  - test-evidence: test-results.md
  - task-evidence: task-results.md
  - security-evidence: security-results.md
  - reproduction-evidence: repro.md
  - performance-evidence: perf.md
capabilities:
  - CAP-implement-02
  - CAP-implement-03
  - CAP-implement-04
  - CAP-implement-06
exit_machine:
  - aw check implement
exit_human: []
needs_clean_context: false
---

# Phase 04 — Implement

## Goal

Do each task in `plan.md` per `tdd.md`, **without leaving scope**. The typical failure is not wrong code but scope creep: fixing things "while there", changing signatures, tidying files.

`plan.md` is the only source of work; `tdd.md` says how (contract, data, flow, DEC-xxx); `spec.md` says why. Test file patterns and `covers:` syntax: conventions.

## Loop

```
aw ready <dir>
    CHƯA SẴN SÀNG → stop, tell the human (red tests on untouched code = environment or base broken)
loop:
  T = aw task next <dir>
      HẾT TASK   → aw check implement <dir> → ĐẠT: stop, report
                                              KHÔNG ĐẠT: fix that violation, rerun
      KẸT, DỪNG  → stop, tell the human
  aw task start <dir> T
  do T — only within T's "Expected files"
  aw task done <dir> T          (no command in Verify: --manual "<what you did, what you saw>")
      ĐỎ   → fix within T, rerun done
      DỪNG → record "Unplanned" (what you tried, the error), stop, tell the human
      XONG → commit T
```

- **Doing T:** tag each test `covers: REQ-NNN`. A REQ not testable automatically → `plan.md` "Manual verification" + reason.
- **Promote when the task covers it — never write by hand** (the machine compares with the approved item): DEC with `Promote: adr` → `aw adr promote <dir> DEC-NNN`; REQ with `Promote: BR-…` → `aw rule promote <dir> REQ-NNN`. Do it in the task that implements that DEC / REQ.
- **Commit T** right after it goes `[x]`: stage by path only T's files, its "Unplanned" files and the ADR / rule files it promoted (never `git add -A`), message `TSK-NNN: <task title>` unless repo rules set a format. Nothing uncommitted may remain at the end — `/aw-ship` will not commit for you.
- **`aw check implement`** writes results stamped with the code tree: code changed afterwards, even uncommitted → rerun. Scans only: `aw check security <dir>`. Fix every warning it prints now; `/aw-review` blocks on them. Same violation twice in a row → stop, tell the human.

## Unplanned

Every surprise goes to `plan.md` "Unplanned" (task, what came up, extra files in backticks, resolution). Then:

| Situation | After recording |
|---|---|
| A file outside T's "Expected files" is unavoidable for T itself | **Continue** |
| A repo rule asks for work outside T, or contradicts `tdd.md` | **Continue**, without doing what it asks |
| `DỪNG`, `KẸT`; work not in any task; `tdd.md`/`spec.md`/a DEC-xxx must change (DEC-xxx → `/aw-design`) | **Stop**, tell the human |
| An existing test is really wrong; a scan finding is a false positive (+ evidence) | **Stop**, tell the human — they decide |

## By work type

| Type | Order / rule |
|---|---|
| `bugfix` | Write the repro test → `aw check repro <dir>` **before touching code** → then fix |
| `refactor` | Never delete old tests; declare edited ones in "Modified existing tests" |
| `perf` | Like refactor; `aw check perf <dir> --before` **before the change**, `--after` after |
| `chore` | No production code; declare "Dependency upgrades" |

Forgot `repro`/`--before` and already changed code → the script refuses: `git stash`, rerun, `git stash pop`.

## Forbidden

- Editing `Status` in `plan.md` yourself; editing `tdd.md`/`spec.md`.
- Editing or disabling tests to go green (`.only(`, `.skip(`, `@Disabled`…).
- `covers:` on a test that does not really check that REQ.
- Ignoring lint/type errors as "unrelated".
- Making scans green by loosening tools (`nosemgrep`, `.gitleaksignore`, `.trivyignore`, lower thresholds, removing lines from `SECURITY_CMDS`).
