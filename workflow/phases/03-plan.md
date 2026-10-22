---
id: plan
name: Lập kế hoạch
summary: Bước 4/6 · Cần DEC-xxx đã duyệt. Chia thiết kế thành task nhỏ, có thứ tự, ghi plan.md
required: true
approval_gate: true
inputs:
  - intake.md
  - spec.md
  - tdd.md
  - open-questions.md
outputs:
  - plan.md
implements: breakdown
provides:
  - task-plan: plan.md
capabilities:
  - CAP-breakdown-01
  - CAP-breakdown-02
exit_machine:
  - aw check plan
exit_human: []
needs_clean_context: true
---

# Phase 03 — Plan

## Goal

Split the **approved** `tdd.md` into executable tasks. `plan.md` only manages execution — **no new technical choices** (this phase has no human gate). `open-questions.md` tells which tasks stand on a temporary assumption.

No design phase (`chore`, or `Design: skip` in `spec.md`) → no `tdd.md`: input is the approved `spec.md`; tasks have no `Based on: DEC-xxx` and no `Design:` line.

## Steps

1. **Split into tasks.** Each task:
   - `Covers:` ≥ 1 `REQ-NNN` from `spec.md`;
   - `Based on: DEC-xxx` if it implements a decision;
   - `Design: [tdd.md § …](tdd.md#…)`;
   - `Expected files:` — paths in backticks, globs allowed (`src/todo/*`) — used to check diff scope, per task. Keep each pattern narrow: `aw check plan` warns when one matches more than `scope_glob_max_files` tracked files;
   - `Verify:` — command in backticks + what to observe;
   - `Depends on:` if any;
   - small enough to finish in one go without breaking the build on its own.
2. **Tasks on a temporary assumption:** `On assumption: **yes** — [open-questions.md § REQ-NNN](open-questions.md#req-nnn)`, else `no`.
3. **Every REQ is covered by a task or listed in `## Deferred` with a reason.** Prefer deferring `should`; deferring `must` warns — tell the human.
4. **`## Manual verification`:** REQs that cannot be tested automatically + reason (missing → implement warns, review blocks).
5. **By work type:**
   - `bugfix`: first task **writes the repro test**, separate from the fix task (`aw check repro` runs between them).
   - `perf`: first task **measures before** (`aw check perf <dir> --before`).
   - `refactor`/`perf`: old tests expected to change → `## Modified existing tests`.
   - `chore`: dependency bumps → `## Dependency upgrades` (`patch | minor` only).
   - DEC with `Promote: adr` → a task `Based on: DEC-NNN` whose `Expected files` include the ADR directory (`docs/adr/*` by default) and whose `Verify` is `aw adr check`.
   - REQ with `Promote: BR-<DOMAIN>-NNN` → a task covering it whose `Expected files` include the rule file (`docs/product/rules/<domain>.md` by default) and whose `Verify` is `aw rule check`.
6. **Record inputs:** `aw based-on <dir> plan.md spec.md tdd.md` (no design phase: drop `tdd.md`).

## Forbidden

- **Writing code.**
- Technical choices not in `tdd.md` — go back to `02-design` (reopen/add a DEC).
- Requirements not in `spec.md` — go back to `01-spec`.
- Tasks that map to no `REQ-NNN`; tasks like "refactor all of module X", "clean up old code" (no done criterion).
