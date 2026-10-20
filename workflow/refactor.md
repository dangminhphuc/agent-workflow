---
id: refactor
choice_ui: true
name: Ghi nhận yêu cầu refactor
summary: Review và phản biện từng yêu cầu refactor của bạn, rồi ghi lại (nguyên văn + bản tóm tắt, chưa làm); xong thì chỉ lệnh intake tiếp theo
arguments: mixed
argument_hint: [yêu-cầu] [tên-feature]
---

# Record refactor requests (refactor)

**Not a phase**, runs any time in a job's worktree. The human states refactorings they want; you **review and challenge** each one, then **only record** it in `<dir>/refactor-requests.md` (template `templates/refactor-requests.md`). Nothing gets implemented here. Talk to the human in Vietnamese.

Start:
- Arguments (minus a feature name) → they are the first request: step 1.
- No arguments, `refactor-requests.md` has `open` RFRs → one choice question: `Thêm yêu cầu` (→ ask "Bạn muốn refactor gì?", step 1) / `Chọn đường đi cho N RFR đang chờ` (→ step 4).
- Otherwise → ask "Bạn muốn refactor gì?".

Rerun with an existing file = append; never rewrite or renumber.

## 1. Review the request (write nothing yet)

Read `intake.md` (`Type`, `Goal`, `Base`), the existing RFRs, and the code the request names — only enough to check it, never to design the change. Look for:

| Check | Raise when |
|---|---|
| Clarity | No visible end state ("dọn module X": what is different after?) |
| Really a refactor | Externally observable behaviour changes (error codes, order, output) → that is feature/bugfix |
| Premise | The code does not match what the human says (counts, duplication, who calls it) — cite `file:line` |
| Protecting tests | The area has no test on `Base` → behaviour preservation cannot be shown; tests must come first |
| Scope and risk | Many callers, public API, `sensitive_code`, migration; a smaller change reaching the same aim |
| One request or several | Independent changes in one sentence → propose splitting |
| Existing RFRs | Duplicate, contradicts, or must come before/after an RFR |
| Current job | Touches files this job changes (`git diff <Base>`) → merge conflict risk |

Only real issues, each backed by code or the request text. None → say so in one line; never invent objections.

## 2. Debate once, then the human decides

Present in one message: each concern (max 5) — evidence, why it matters, your counter-proposal; then a draft **Summary** (1–2 sentences: what changes, where, behaviour kept) and the `Location` you verified.

Then one choice question "Ghi RFR-NNN thế nào?" — recommended first, label starting `(Đề xuất)`:
- `Ghi như đề xuất` — Summary as drafted, the human's request verbatim;
- `Tách thành N yêu cầu` — only if you proposed a split;
- `Bỏ yêu cầu này` — nothing is written.

Free text = the human's answer to your concerns, or a restated request (the new wording becomes the verbatim `Request`). Discussion ("Chat about this") is one round: answer, then ask the same question again. **The human has the last word**: they keep the request despite a concern → record it, with the concern and their answer.

## 3. Record

Append `### RFR-NNN — <short title>` under `## Requests` (next number; first use → create from the template, delete its comments):
- `Summary`: the approved draft. `Request`: the human's words **verbatim**. `Requested by`: who + today.
- `Location`: only places you saw exist; otherwise `None`.
- `Review`: each concern raised + the human's answer verbatim; none raised → `None`.
- `Status: open`.

Then ask "Còn yêu cầu nào nữa không?" — `Thêm yêu cầu` / `Xong — đã đủ`. Free text = the next request → back to step 1 (review it against the RFRs already recorded too).

Only the human edits a `Request` or drops an RFR (`dropped: <their reason>`).

## 4. After the last request: next step

List the `open` RFRs (id + Summary, one line each), then one choice question "Đưa các yêu cầu này đi đâu?":

| Option | Recommended when | Tell the human |
|---|---|---|
| `Gộp vào việc này` | `Type: refactor` and the RFRs fit its `Goal` | "This job" |
| `Việc refactor riêng` | Any other case | "Separate job" |
| `Để đó, quyết sau` | Never | Rerun `/aw-refactor` without arguments to come back here; the RFRs stay `open` |

`Gộp vào việc này` is not offered when `Type` ≠ `refactor`: one job = one type; a refactor riding a feature has no preserve REQ, no protecting test, no separate MR.

After the human picks a route, set those RFRs to `routed: this-job` or `routed: separate-job` (only status the route; `open` = not routed yet). Then print commands for the human to run; run none of them yourself.

### This job

1. Run `/aw-intake <dir>/refactor-requests.md` in this worktree — rerun appends the file as a `[FILE]` input.
2. Then `/aw-spec` (REQs `preserve`/`structural`, cited `[FILE] … § RFR-NNN`; approved spec → re-approve); `tdd.md`/`plan.md` exist → `/aw-design`, `/aw-plan`.

### Separate job

1. Finish this job as planned, through `/aw-ship`; the RFRs do not enter its spec or plan.
2. On the main checkout: `/aw-intake` with the RFRs' `Request` lines as arguments (print them as one copyable block) → `[HUMAN]` input, type `refactor`. Base: this job's base once it merged; RFRs on code this job adds that cannot wait → stack on this branch (review warns).
3. In the new worktree: copy the file into the new job dir and append it as input, so the spec can cite `§ RFR-NNN` and the `Review` notes:
   ```sh
   cp <dir>/refactor-requests.md <new-worktree>/docs/sdlc/<new-branch>/
   ```
   then `/aw-intake docs/sdlc/<new-branch>/refactor-requests.md` there. Do this before `/aw-ship` cleans up this worktree (afterwards the file is only in the archive).

## Forbidden

- **Implementing:** editing code, tests, `intake.md`, `spec.md`, `tdd.md`, `plan.md` or their boxes. Only `refactor-requests.md` is written.
- Writing an RFR before the human chose; paraphrasing `Request` or the human's answers; a `Summary` the human did not see.
- Dropping, weakening or blocking a request because you disagree; adding your own refactor ideas as RFRs.
- Designing the change (that is `/aw-design`); choosing the route; creating a worktree or branch.
