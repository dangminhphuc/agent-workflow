# Rule: source traceability

Applies to `01-spec`; the checkers of `02-design`, `03-plan`, `05-review` re-run the spec checker.

Most dangerous failure: the agent invents a requirement and presents it as if the source said it. This rule turns that into a machine-checkable error.

## Source labels

Every `### YC-NNN` in `spec.md` has **exactly one** `Source:` line with one label:

| Label | Meaning | Must include |
|---|---|---|
| `[CONFLUENCE]` | Quoted from a Confluence page | Page URL + heading |
| `[JIRA]` | Quoted from a Jira issue | Issue key + URL |
| `[FILE]` | Quoted from a file in the repo | Path + heading |
| `[INFERRED]` | Technical decision you derived | Reason + the YC it serves |
| `[OPEN-QUESTION]` | No source yet, temporary assumption | Entry with the same id in `open-questions.md` |

No sixth label. Does not fit the five → not a requirement → put it in `open-questions.md`.

## `[INFERRED]` vs `[OPEN-QUESTION]`

- `[INFERRED]` — a **technical** decision the source need not state, obvious to any reader. E.g. index on `created_at` when the BRD asks to filter by date.
- `[OPEN-QUESTION]` — a **business** decision the source leaves open, someone could choose differently. E.g. BRD says "notify" but not email vs in-app.

Test: could the BA/PO say "no, I meant something else"? → `[OPEN-QUESTION]`. Labelling a business decision `[INFERRED]` is worse than a missing label — no machine catches it.

## Blocking levels of `[OPEN-QUESTION]`

The agent proposes `Blocking`, the human approves. Choose by "if the assumption is wrong, what must be redone". Only the human may lower it.

| Level | When | What it blocks |
|---|---|---|
| `blocking` | Wrong → the whole design changes direction | `02-design` (chore: `03-plan`) and every later phase, until `answered` |
| `review-blocking` | Wrong → part of the code is redone | Flow continues on the assumption; `04-implement` warns, `05-review` blocks |
| `non-blocking` | Wrong → small fix, may ship first | Nothing; review marks that YC `pending` |

Answering an open question: write `Answer:`, set `Status: answered`, **and** change the YC's source label in the spec (e.g. `[FILE]` open-questions.md § YC-002). The checker blocks if the two files disagree.

## `aw check spec <thư-mục-feature>` checks

1. Every `### YC-NNN` has exactly one valid `Source:`. A YC's region ends at the next `##`/`###` heading (a `Source:` under `### Ghi chú` does not count for the YC above). No duplicate ids.
2. Every YC has `Priority: must | should` and at least one real `- [ ] …` (not `<...>`, not inside an HTML comment).
3. Every `[OPEN-QUESTION]` has a same-id entry in `open-questions.md` with `Assumption` and a valid `Blocking`.
4. Reverse: every `open-questions.md` entry points to a real YC; `Status: open | answered`; `open` ↔ spec still `[OPEN-QUESTION]`; `answered` ↔ has `Answer` and the spec label was changed. A 0-byte file is valid (reviewed, nothing found).
5. `spec.md` has `Risk: high | normal` and exactly one `- [ ] **Approved by human**` box in the header; if ticked, the approval hash must match the content.
6. `## Constraints & dependencies`, `## Out of scope`, `## Source conflicts` exist with real content (nothing → write "Không có…" / "Không phát hiện mâu thuẫn.").
7. Every conflict row's "Resolution" column points to an open question (`open-questions.md § YC-NNN`) or a settled source (`[CONFLUENCE]` `[JIRA]` `[FILE]`). Resolving a business conflict yourself = inventing a requirement.
8. `blocking` still `open` blocks design (chore: plan); `review-blocking` open: implement warns, review blocks.
