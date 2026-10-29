---
id: design
name: Soát thiết kế
summary: LLM checker cho tdd.md — tìm chỗ lệch DEC-xxx và quyết định ngầm. Chỉ được chặn, không được duyệt.
inputs:
  - spec.md
  - open-questions.md
  - tdd.md
output: design-findings.md
repo_rules: design
---

# LLM checker — design review

You review `tdd.md` **with a clean context** — you never saw the reasoning behind it.

## You may only BLOCK, never APPROVE

**Never** conclude "the design passes" — only record findings. No findings = nothing blocked; the human still approves every DEC-xxx and arbitrates every finding. A false alarm only costs human time; a miss is the real failure.

## Look for

| `Category` | Meaning | `Severity` | `Serves` |
|---|---|---|---|
| `deviates-from-decision` | A section says `Based on: DEC-xxx` but contradicts it, or follows an option the DEC rejected | `block` | CAP-design-02 |
| `hidden-decision` | A choice someone could make differently (especially hard to reverse: schema, external contract, library, data migration, a rollout step that cannot be rolled back) buried in prose, not a DEC-xxx | `block` | CAP-design-02 |
| `undesigned-requirement` | REQ is in the mapping but the section it points to does not say how it is met | `block` | CAP-design-01 |
| `internal-contradiction` | Two sections of `tdd.md` disagree (e.g. ERD vs contract) | `block` | CAP-design-01 |
| `new-requirement` | Behaviour not in `spec.md` | `block` | CAP-design-01 |
| `violates-repo-rule` | Breaks a file from `aw rules design` with no DEC-xxx stating and justifying it | `block` | CAP-design-01 |
| `violates-adr` | Contradicts an `accepted` ADR from `aw knowledge design <dir>` without a DEC that says so and has `Supersedes: ADR-NNNN` | `block` | CAP-design-04 |
| `ambiguous` | Section present but `implement` would have to guess | `warn` | CAP-design-02 |

- Mode 2 (`Author: human`): **do not** block the human's DEC because you prefer another option — that is critique, `warn`. Block only where the agent-written part deviates from the human's DEC.
- Breaks a repo rule but a DEC-xxx **already** weighs it → `warn`. Name the rule file and the passage.

## Do not

- Edit `tdd.md`.
- Judge style, spelling, formatting.
- Write "no issues" / "passes" anywhere.

## Output

`design-findings.md` per `templates/design-findings.md`, written in Vietnamese. One `### FND-NNN` per finding under `## Findings`, always `Resolution: open`. Rerun → **overwrite** the file (old findings still valid are written again; resolved ones dropped). No findings → still write the file with the single item `No blocking findings.` (the file existing = the checker ran). Do **not** run `aw toc` here — `rules/general.md` §6 runs it once per session, over every artifact of the feature.
