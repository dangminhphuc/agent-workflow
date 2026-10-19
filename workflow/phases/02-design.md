---
id: design
name: Thiết kế kỹ thuật
summary: Bước 3/6 · Cần spec đã duyệt. Viết tdd.md, tách mỗi lựa chọn thành quyết định DEC-xxx để người duyệt
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
  - The human approves EACH DEC-xxx decision in tdd.md (ticks that D's "Approved by human" box)
  - The human arbitrates the LLM checker's findings (confirm, or reject with a reason)
needs_clean_context: true
llm_checker: workflow/checkers/design.md
trace_rule: true
---

# Phase 02 — Technical design

`tdd.md` = **Technical Design Document** (not Test-Driven Development).

## Goal

Write everything `04-implement` needs to be technically right, **within the repo's existing architecture**, and pull real choices out as **DEC-xxx** items so the human *decides* instead of proofreading prose.

- `chore`, and `bugfix`/`refactor` with `Design: skip` in `spec.md`, **have no design phase** — go straight to `/aw-plan`.
- `refactor`/`perf`: design is the main work — target structure and DEC-xxx on how to get there.
- A `blocking` open question not `answered` → stop, ask the human to run `/aw-clarify`. `review-blocking`/`non-blocking` → design on the temporary assumption.

## Choose the mode

| `Risk` in `spec.md` | Mode | Who writes DEC-xxx |
|---|---|---|
| `normal` | **1** | Agent writes all of `tdd.md`, the human approves each DEC |
| `high` | **2** | **The human drafts DEC-xxx first** (`Author: human`); the agent writes the rest and only **critiques** the human's DEC |

Mode 2 prevents anchoring on the agent's option. Never edit the human's D; write critique right under it: `- Critique (agent): …`.

### Mode 2 — guide the human to draft

`high` with no `Author: human` DEC → do not just stop; **interview the human** so they write the DEC-xxx. Facts and questions only — never an option, a leaning or a recommendation.

1. Do step 1 below (survey existing code) first.
2. Show the **decision points**, one line each, as questions: what must be decided, which REQ/constraint forces it, facts found (call sites, data volume, external consumers, existing ADR), why it may be hard to reverse. Ask the human to add, drop or merge points.
3. Go through the points **one at a time**, with open questions. A point settled → **write nothing yet**; keep the human's words and go to the next point:
   - "What ways do you see to do this?" — ≥ 2 options; if they give one: "What else could someone choose?"
   - Per option: "What does it buy? What does it cost?" You may point out a **fact** they missed ("`X` is called from 14 places"), never an option or a verdict.
   - "Which one, and why?" then "What would make this hard to undo?"
4. The human asks you for options or "what would you do" → decline in one line (Mode 2 is anti-anchoring); offer only neutral dimensions to think through (reversibility, migration, compatibility, call sites, operations, testing). If they insist, they may lower `Risk` via `/aw-clarify` (their call).
5. All points settled (or the human says `dừng`: only the settled ones, then stop — rerunning `/aw-design` continues with the rest) → show **one** preview: every DEC-xxx as it will be written, in the human's own words (fix format only), `Author: human`, box unticked, numbered consecutively. Ask once: "ghi như vậy được không?". Corrections → fix only those DEC, show only them, ask again. Then write them all into `tdd.md` in one go.
6. The human prefers to write `tdd.md` alone → stop, tell them the DEC format and to rerun `/aw-design`.
7. Preview confirmed and written → continue with **Steps**: critique each human DEC, write the rest.

## Steps

1. **Survey existing code before designing.** `aw knowledge design <dir>` first (ADR index), read every file it prints. Find where similar problems are solved; record modules to touch and conventions to follow in `## Existing code`. Then run `aw knowledge design <dir>` again to get the ADRs and module docs (`ARCHITECTURE.md`) for what you touch.
2. **State DEC-xxx.** Every choice someone could make differently — especially hard to reverse (many call sites, data migration, external interface): problem, ≥ 2 options + trade-offs, choice, `Author`, `- [ ] **Approved by human**` **unticked**. Obvious points need no D; zero DEC is allowed.
   - A DEC going against an `accepted` ADR: say so and add `- Supersedes: ADR-NNNN` (needs `- Promote: adr`). Never silently diverge from an ADR.
   - A DEC that stays true after this job (cross-module, hard to reverse): propose `- Promote: adr` + `- Scope: <glob>`. `04-implement` copies it to an ADR once approved.
3. **Write the sections** per the template: target structure (before → after), data + ERD, contract/API, flow + sequence/state (Mermaid), rollout & rollback (what cannot be undone), non-functional, test strategy, REQ → section mapping (every REQ). A section relying on a DEC says `Based on: DEC-xxx`. Not applicable: `Not applicable: <reason>`, never empty.
4. **Record inputs:** `aw based-on <dir> tdd.md spec.md open-questions.md`.
5. **Run the LLM checker** → `design-findings.md`. Fix what you agree with (`Resolution: fixed`); the human arbitrates the rest via `/aw-clarify`.
6. **Run `aw check design <dir>`**, then stop for the human to approve each DEC.

## Reopening a DEC-xxx

- Reopen **exactly one** DEC, edit in place (git keeps history). Untick it, add `Reopen reason:` (unticked + reason = `reopened`).
- `aw task reopen <dir> DEC-xxx` → only tasks `Based on` it go back to `[ ]`.
- The human re-approves only the reopened DEC. `/aw-plan` blocks until then.

## Forbidden

- **Writing code**, even "sample code" (API/schema signatures in the contract are fine).
- Requirements not in `spec.md` — go back to `01-spec`.
- **Ticking a DEC-xxx box**, editing/deleting its approval hash. Editing a ticked DEC → untick it (adding `- Critique (agent):` does not count).
- Mode 2: editing/replacing the human's DEC instead of critiquing.
- Mode 2: writing or showing DEC-xxx one by one for confirmation instead of one preview after all points.
- Mode 2: proposing, ranking or hinting at an option before the human has written their D; putting words in the human's DEC they did not say.
- Hiding a real choice in prose instead of a DEC.
- Treating "LLM checker reported nothing" as a pass when it has not run.
