---
id: design
name: Thiết kế kỹ thuật
summary: Bước 3/6 · Cần spec đã duyệt. Viết tdd.md, tách mỗi lựa chọn thành quyết định D-xx để người duyệt
required: true
approval_gate: true
inputs:
  - intake.md
  - spec.md
  - open-questions.md
outputs:
  - tdd.md
  - design-findings.md
exit_machine:
  - aw check design
exit_human:
  - The human approves EACH D-xx decision in tdd.md (ticks that D's "Approved by human" box)
  - The human arbitrates the LLM checker's findings (confirm, or reject with a reason)
needs_clean_context: true
llm_checker: workflow/checkers/design.md
trace_rule: true
---

# Phase 02 — Technical design

`tdd.md` = **Technical Design Document** (not Test-Driven Development).

## Goal

Write everything `04-implement` needs to be technically right, **within the repo's existing architecture**, and pull real choices out as **D-xx** items so the human *decides* instead of proofreading prose.

- `chore` **has no design phase** — go straight to `/aw-plan`.
- `refactor`/`perf`: design is the main work — target structure and D-xx on how to get there.
- A `blocking` open question not `answered` → stop, ask the human to run `/aw-clarify`. `review-blocking`/`non-blocking` → design on the temporary assumption.

## Choose the mode

| `Risk` in `spec.md` | Mode | Who writes D-xx |
|---|---|---|
| `normal` | **1** | Agent writes all of `tdd.md`, the human approves each D |
| `high` | **2** | **The human drafts D-xx first** (`Author: human`); the agent writes the rest and only **critiques** the human's D |

Mode 2 prevents anchoring on the agent's option. `high` with no `Author: human` D → **stop, ask the human to draft**. Never edit the human's D; write critique right under it: `- Critique (agent): …`.

## Steps

1. **Survey existing code before designing.** `aw knowledge design <dir>` first (ADR index), read every file it prints. Find where similar problems are solved; record modules to touch and conventions to follow in `## Existing code`. Then run `aw knowledge design <dir>` again to get the ADRs and module docs (`ARCHITECTURE.md`) for what you touch.
2. **State D-xx.** Every choice someone could make differently — especially hard to reverse (many call sites, data migration, external interface): problem, ≥ 2 options + trade-offs, choice, `Author`, `- [ ] **Approved by human**` **unticked**. Obvious points need no D; zero D is allowed.
   - A D going against an `accepted` ADR: say so and add `- Supersedes: ADR-NNNN` (needs `- Promote: adr`). Never silently diverge from an ADR.
   - A D that stays true after this job (cross-module, hard to reverse): propose `- Promote: adr` + `- Scope: <glob>`. `04-implement` copies it to an ADR once approved.
3. **Write the sections** per the template: data + ERD, contract/API, flow + sequence/state (Mermaid), non-functional, test strategy, YC → section mapping (every YC). A section relying on a D says `Based on: D-xx`. Not applicable: `Not applicable: <reason>`, never empty.
4. **Record inputs:** `aw based-on <dir> tdd.md spec.md open-questions.md`.
5. **Run the LLM checker** → `design-findings.md`. Fix what you agree with (`Resolution: fixed`); the human arbitrates the rest via `/aw-clarify`.
6. **Run `aw check design <dir>`**, then stop for the human to approve each D.

## Reopening a D-xx

- Reopen **exactly one** D, edit in place (git keeps history). Untick it, add `Reopen reason:` (unticked + reason = `reopened`).
- Grep `Based on: D-xx` in `plan.md` → only those tasks go back to `[ ]`.
- The human re-approves only the reopened D. `/aw-plan` blocks until then.

## Forbidden

- **Writing code**, even "sample code" (API/schema signatures in the contract are fine).
- Requirements not in `spec.md` — go back to `01-spec`.
- **Ticking a D-xx box**, editing/deleting its approval hash. Editing a ticked D → untick it (adding `- Critique (agent):` does not count).
- Mode 2: editing/replacing the human's D instead of critiquing.
- Hiding a real choice in prose instead of a D.
- Treating "LLM checker reported nothing" as a pass when it has not run.
