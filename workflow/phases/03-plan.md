---
id: plan
name: Lập kế hoạch
summary: Bước 4/6 · Cần D-xx đã duyệt. Chia thiết kế thành task nhỏ, có thứ tự, ghi plan.md
required: true
approval_gate: true
inputs:
  - intake.md
  - spec.md
  - tdd.md
  - open-questions.md
outputs:
  - plan.md
exit_machine:
  - aw check plan
exit_human: []
needs_clean_context: true
---

# Phase 03 — Plan

## Goal

Split the **approved** `tdd.md` into executable tasks. `plan.md` only manages execution — **no new technical choices** (this phase has no human gate).

## Input

- `spec.md`, `tdd.md` — pass `aw check design`, **every D-xx approved by the human** (ticked, hash matches).
- `open-questions.md` — to know which tasks stand on a temporary assumption.
- `aw rules plan` — read every file it prints.

`chore` (no `tdd.md`): input is `spec.md` — passes `aw check spec`, "Approved by human" ticked, no open `blocking` question. Tasks have no `Based on: D-xx`.

## Steps

1. **Split into tasks.** Each task:
   - `Covers:` ≥ 1 `YC-NNN` from `spec.md`;
   - `Based on: D-xx` if it implements a decision;
   - `Design: tdd.md § …`;
   - `Expected files:` — paths in backticks, globs allowed (`src/todo/*`) — used to check diff scope;
   - `Verify:` — command in backticks + what to observe;
   - `Depends on:` if any;
   - small enough to finish in one go without breaking the build on its own.
2. **Tasks on a temporary assumption:** `On assumption: **yes** — open-questions.md § YC-NNN`, else `no`.
3. **Defer with a reason:** a YC no task covers → `## Deferred` + reason. Prefer deferring `should`; deferring `must` warns — tell the human.
4. **`## Manual verification`:** YCs that cannot be tested automatically + reason (missing → implement warns, review blocks).
5. **By work type:**
   - `bugfix`: first task **writes the repro test**, separate from the fix task (`aw check repro` runs between them).
   - `perf`: first task **measures before** (`aw check perf <thư-mục-feature> --before`).
   - `refactor`/`perf`: old tests expected to change → `## Modified existing tests`.
   - `chore`: dependency bumps → `## Dependency upgrades` (`patch | minor` only).
6. **Record inputs:** `aw based-on <thư-mục-feature> plan.md spec.md tdd.md` (chore: drop `tdd.md`).

## Output

`plan.md` per `templates/plan.md`.

## Forbidden

- **Writing code.**
- Technical choices not in `tdd.md` — go back to `02-design` (reopen/add a D).
- Tasks that map to no `YC-NNN`; tasks like "refactor all of module X", "clean up old code" (no done criterion).
- Requirements not in `spec.md` — go back to `01-spec`.

## Exit conditions

**Machine:** `aw check plan` → `[x] ĐẠT` — input passes `aw check design`, every D approved; every task has valid `Covers:`, non-empty `Expected files:`, `Verify:`, `Based on:` pointing to a real D; every YC covered by a task **or** in "Deferred" with a reason.
