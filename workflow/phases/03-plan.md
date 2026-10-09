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

Split the **approved** `tdd.md` into executable tasks. `plan.md` only manages execution — **no new technical choices** (this phase has no human gate). `open-questions.md` tells which tasks stand on a temporary assumption.

`chore` (no `tdd.md`): input is the approved `spec.md`; tasks have no `Based on: D-xx`.

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
3. **Every YC is covered by a task or listed in `## Deferred` with a reason.** Prefer deferring `should`; deferring `must` warns — tell the human.
4. **`## Manual verification`:** YCs that cannot be tested automatically + reason (missing → implement warns, review blocks).
5. **By work type:**
   - `bugfix`: first task **writes the repro test**, separate from the fix task (`aw check repro` runs between them).
   - `perf`: first task **measures before** (`aw check perf <dir> --before`).
   - `refactor`/`perf`: old tests expected to change → `## Modified existing tests`.
   - `chore`: dependency bumps → `## Dependency upgrades` (`patch | minor` only).
   - D with `Promote: adr` → a task `Based on: D-NN` whose `Expected files` include the ADR directory (`docs/adr/*` by default) and whose `Verify` is `aw adr check`.
   - YC with `Promote: BR-<DOMAIN>-NNN` → a task covering it whose `Expected files` include the rule file (`docs/product/rules/<domain>.md` by default) and whose `Verify` is `aw rule check`.
6. **Record inputs:** `aw based-on <dir> plan.md spec.md tdd.md` (chore: drop `tdd.md`).

## Forbidden

- **Writing code.**
- Technical choices not in `tdd.md` — go back to `02-design` (reopen/add a D).
- Requirements not in `spec.md` — go back to `01-spec`.
- Tasks that map to no `YC-NNN`; tasks like "refactor all of module X", "clean up old code" (no done criterion).
