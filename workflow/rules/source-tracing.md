# Rule: source traceability

Applies to `01-spec`; later checkers re-run the spec checker.

Most dangerous failure: the agent invents a requirement and presents it as if the source said it. This rule turns that into a machine-checkable error.

## Source labels

Every `### REQ-NNN` in `spec.md` has **exactly one** `Source:` line with one label:

| Label | Meaning | Must include |
|---|---|---|
| `[CONFLUENCE]` | Quoted from a Confluence page | Page URL + heading; `Quote:` |
| `[JIRA]` | Quoted from a Jira issue | Issue key + URL; `Quote:` |
| `[ISSUE]` | Quoted from a GitHub/GitLab issue, PR, MR or work item, a GitHub discussion, Gitea/Forgejo issue or Bitbucket issue/PR | Issue/PR/MR/work-item/discussion URL (`…/issues/N`, `…/pull/N`, `…/pulls/N`, `…/discussions/N`, `…/pull-requests/N`, `…/-/merge_requests/N`, `…/-/work_items/N`); `Quote:` |
| `[FILE]` | Quoted from a file in the repo | Path + heading; `Quote:` found in that file |
| `[INFERRED]` | Technical decision you derived | Reason + the REQ it serves |
| `[OPEN-QUESTION]` | No source yet, temporary assumption | Link to its question: `[open-questions.md § Q-NNN](open-questions.md#q-nnn)` |

No seventh label. Does not fit the six → not a requirement → put it in `open-questions.md`.

`Quote:` = the source sentences **verbatim**, one `> …` line each, right under `Source:`:

```markdown
- Source: `[FILE]` [docs/brd.md](docs/brd.md) § Hoàn tiền
- Quote:
  > Khách được hoàn tiền trong vòng 30 ngày kể từ ngày thanh toán.
```

`[FILE]` path: `intake.md` / `open-questions.md` = the feature directory; anything else = repo root.

## `[INFERRED]` vs `[OPEN-QUESTION]`

- `[INFERRED]` — a **technical** decision the source need not state, obvious to any reader. E.g. index on `created_at` when the BRD asks to filter by date.
- `[OPEN-QUESTION]` — a **business** decision the source leaves open, someone could choose differently. E.g. BRD says "notify" but not email vs in-app.

Test: could the BA/PO say "no, I meant something else"? → `[OPEN-QUESTION]`. Labelling a business decision `[INFERRED]` is worse than a missing label — no machine catches it.

## Blocking levels of `[OPEN-QUESTION]`

The agent proposes `Blocking`, the human approves. Choose by "if the assumption is wrong, what must be redone". Only the human may lower it.

| Level | When | What it blocks |
|---|---|---|
| `blocking` | Wrong → the whole design changes direction | `02-design` (no design phase: `03-plan`) and every later phase, until `answered` |
| `review-blocking` | Wrong → part of the code is redone | Flow continues on the assumption; `04-implement` warns, `05-review` blocks |
| `non-blocking` | Wrong → small fix, may ship first | Nothing; review marks that REQ `pending` |

## Question ↔ REQ

- A question is `### Q-NNN — <short question>` in `open-questions.md`, numbered on its own. Old entries `### REQ-NNN` stay readable; new ones use `Q-NNN`.
- The link lives **only** in the REQ's `Source:` line; never list REQs in the question. The machine derives which REQs a question covers.
- One question may cover several REQs; a REQ stands on at most one question (exactly one `Source:`).
- The assumption lives only in the question. Never copy question fields into the REQ, or REQ text into the question.

Answering an open question: write `Answer:`, set `Status: answered`, **and** change the source label of **every** REQ pointing to it (e.g. `[FILE]` [open-questions.md § Q-001](open-questions.md#q-001)) and their `Quote:` to the answer words. The checker blocks if the two files disagree.

## Common failures

- A REQ's region ends at the next `##`/`###` heading: a `Source:` or criterion under `### Ghi chú` does not count for the REQ above (split a REQ with `####`).
- An acceptance criterion still `<...>` or inside an HTML comment does not count.
- A source (`[JIRA]` key, `[CONFLUENCE]` or `[ISSUE]` URL, `[FILE]` path) not in `intake.md` `## Input` gets a warning: a real input → add it to intake; otherwise use a source you were given.
- `open-questions.md` and the spec disagree: `open` ↔ every REQ pointing to it still `[OPEN-QUESTION]`; `answered` ↔ has `Answer` and no REQ pointing to it is still `[OPEN-QUESTION]`.
- A question still `open` that no REQ points to — link it from the REQ's `Source:` or delete it.
- `## Constraints & dependencies`, `## Out of scope`, `## Source conflicts` left empty — write "Không có…" / "Không phát hiện mâu thuẫn." instead.
- `Quote:` not character-for-character: added quotation marks, fixed typos, dropped markdown (`**`, links). Whitespace and line breaks do not count.
