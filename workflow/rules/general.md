# General rules

Apply to every phase and every agent.

## 1. Hand off through files

A phase takes input only from files in the feature dir, never from earlier chat — it must work from a blank session. If it cannot, the previous phase wrote too little.

## 2. Exit conditions and approval

- **Machine** (`Exit — MACHINE`): run the command, read the `[x]` label of its `Kết quả` block. Never declare a pass yourself.
- **Human** (`Exit — HUMAN`): state it, then stop.
- **The agent never approves:** never tick "Approved by human" (spec, D-xx), never edit/delete `<!-- approval-hash: … -->`, never set an open question to `answered` yourself. Editing ticked content → **untick** it.
- An LLM checker may only **block**, never pass. No findings file = it has not run.
- Checks on a phase's own output block. Cross-phase checks (stale artifact, test ↔ YC, diff scope) only warn — but `/aw-review` blocks on any warning left, so fix them when you see them.

## 3. Stay inside the phase

Work that belongs to another phase: record it in that phase's artifact, do not do it.

## 4. Do not destroy existing state

- Never delete a previous phase's artifact. Rerunning a phase = **update** (the human may have edited by hand), not overwrite.
- Never edit the `Base:` or `Engine:` line of `intake.md` (every `aw check` of the job runs exactly that engine version), the `based_on` frontmatter (written by `aw based-on`) or any `*-results.md`.

## 5. Language

- Artifact content and everything you say to the human: **Vietnamese**. Identifiers (YC ids, file names, config keys): ASCII English.
- **Structure is English — MANDATORY:** headings, field names, fixed labels and enum values — including new ones the template lacks (`## Rollback plan`, not `## Kế hoạch rollback`). Keep the template's exactly (`Type`, `## Out of scope`, `Blocking`, `must`, `[INFERRED]`…): checkers match them literally. Vietnamese only in body text, list items and table cells.
- Labels printed by `aw` (`ĐẠT`, `CẦN HỎI NGƯỜI`…) are Vietnamese; match them literally.

## 6. Artifacts are written for humans — MANDATORY

- Most important thing first (conclusion, decision, what the human must do).
- Headings by level, no skipped levels. One idea per item; parallel ideas → list or table.
- Short sentences, plain words. No hedging, no repetition, no explaining the obvious.
- Writing from a template: delete its guidance comments (`<!-- … -->`) and the optional blocks you do not use. Never touch `<!-- approval-hash: … -->`.

## 7. Repo-specific rules, skills and subagents

Declared in conventions: `rules_<phase>` = files to **read** (`aw rules <phase>` — read every file, a `SKILL.md` too, as a normal document); `uses_<phase>` = skills / subagents to **invoke** (`aw uses <phase>` — invoke each entry as your command describes). Prints nothing = none. `KHAI SAI` → stop, ask the human to fix conventions; never guess.

- They rank **below** `spec.md`, `tdd.md`, `plan.md` and the workflow rules. On conflict follow the artifact and report the conflict (`04-implement`: "Unplanned"). Never leave the phase scope because of them.
- `/aw-review` gives one verdict per rule file and per declared skill / subagent file (`aw rules review` prints them all).

## 8. Harness gaps

You failed and no checker caught it → `aw journal add <task|context|env|verify|state|model> "<what went wrong, where, what the harness lacks>"`.
