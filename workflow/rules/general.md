# General rules

Apply to every phase and every agent. Rationale: `docs/kien-truc.md` in the engine repo.

## 1. Hand off through files

- A phase takes input only from files in `<artifact_dir>/<branch-name>/`, never from earlier chat.
- Every phase must run from a blank session. If it cannot, the previous phase wrote too little.

## 2. Exit conditions

- **Machine** (`exit_machine`): run the command, read the label marked `[x]` in the `Kết quả` block at the end of its output. Never declare a pass yourself.
- **Human** (`exit_human`): state it, then stop. Never approve on the human's behalf.

**The agent never approves:**
- Never tick an "Approved by human" box (spec, D-xx). Never edit/delete `<!-- approval-hash: … -->`.
- Never change `[OPEN-QUESTION]` to `answered` yourself.
- If you edit content that is already ticked, **untick** it.
- An LLM checker may only **block**, never pass. No findings file = the checker has not run.

**Block or warn:** checks on the phase's own output contract block. Cross-phase checks (stale artifact, test ↔ YC, diff scope) only warn — but `05-review` blocks on any warning left. Fix warnings when you see them.

## 3. Stay inside the phase

Each phase has a **Forbidden** section. Work that belongs to another phase: record it in that phase's artifact, do not do it. Most common: `01-spec` picking a technical solution; `04-implement` fixing things "while there".

## 4. Do not destroy existing state

Never delete a previous phase's artifact. Re-running a phase = **update** (the human may have edited by hand), not overwrite.

## 5. Language

- Artifact content and everything you say to the human: **Vietnamese**.
- Identifiers (YC ids, file names, config keys): ASCII English.
- Headings, field names, values and fixed labels from the templates (`Type`, `Risk`, `Source`, `## Out of scope`, `Blocking`, `## Lens 1`, `high`, `must`, `[INFERRED]`…): keep **exactly** as in the template — checkers match them literally.
- **English structure — MANDATORY.** In every artifact or template you create or edit, all headings, field names, fixed keywords/labels and enum values are **English**, including ones the template does not have (e.g. a new `## Rollback plan`, not `## Kế hoạch rollback`). Vietnamese only in body text, list items and table cells under them. Never translate an existing English heading or keyword.
- Labels printed by `aw` (`ĐẠT`, `CẦN HỎI NGƯỜI`…) are Vietnamese; match them literally.

## 6. Artifacts are written for humans — MANDATORY

- Headings by level, no skipped levels. One idea per item; parallel ideas → list or table.
- Most important thing (conclusion, decision, what the human must do) first.
- Short sentences, plain words. No hedging, no repetition, no explaining the obvious.
- Syntax required by templates/checkers stays as is.

## 7. Repo-specific rules

Declared under `rules_<phase>` in `conventions.md` (files committed in the repo).

- **At phase start:** run `aw rules <phase>`, read **every file** it prints (including `SKILL.md` — read it as a normal document). Prints nothing = none. `KHAI SAI` → stop, ask the human to fix `conventions.md`; do not guess a replacement.
- **Priority:** repo rules rank **below** `spec.md`, `tdd.md`, `plan.md` and the workflow rules. On conflict follow the artifact and report the conflict (`04-implement`: "Unplanned"). Never leave the phase scope because of a repo rule.
- **`05-review`** checks the diff against every rule file, one verdict per file in `review.md`.
