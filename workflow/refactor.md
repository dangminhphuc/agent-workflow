---
id: refactor
choice_ui: true
name: Ghi nhận yêu cầu refactor
summary: Ghi lại các yêu cầu refactor của bạn trong việc hiện tại (nguyên văn, chưa làm); xong thì đề xuất đưa chúng vào việc nào
arguments: mixed
argument_hint: [yêu-cầu] [tên-feature]
---

# Record refactor requests (refactor)

**Not a phase**, runs any time in a job's worktree. The human lists refactorings they want; you **only record** them in `<dir>/refactor-requests.md` (template `templates/refactor-requests.md`). Nothing gets implemented here. Talk to the human in Vietnamese.

## 1. Collect, one request per turn

The arguments (minus a feature name) are the first request; no arguments → ask "Bạn muốn refactor gì?".

For each request:
1. **Read only to locate:** the human names a file, symbol or area → find it; write `Location` only for a place you saw exists. Not found or ambiguous → ask, never guess. Nothing named → `None`.
2. **Append** `## RF-NNN — <short title>` (next number; create the file from the template on first use, delete its comments). `Request:` = the human's words **verbatim** on the `>` line; `Requested by:` who + today's date; `Status: open`.
3. Same as an existing RF → tell the human, append nothing unless they insist.
4. Ask one choice question: "Ghi RF-NNN rồi. Còn yêu cầu nào nữa không?" — `Thêm yêu cầu` / `Xong — đã đủ`. Free text = the next request, verbatim.

Rerun with an existing file = append. Never rewrite or renumber. Only the human changes a `Request:` line or drops an RF (`dropped: <their reason>`).

## 2. After the last request: route them

Read `intake.md` (`Type`, `Goal`) and which artifacts exist (`spec.md` approved? `plan.md`? code commits since `Base:`?). List the `open` RFs (id + title, one line each), then ask **one** choice question "Đưa các yêu cầu này đi đâu?" — recommended option first, label starting `(Đề xuất)`:

| Option | When it is recommended | Do |
|---|---|---|
| `Việc refactor riêng` | `Type` ≠ `refactor`, or the RFs are outside this job's `Goal` | Below: "Separate job" |
| `Gộp vào việc này` | `Type: refactor` and the RFs fit its `Goal` | Below: "This job" |
| `Để đó, quyết sau` | Never recommended | Keep `open`, stop |

Not offered: putting RFs into a `feature`/`bugfix`/`perf`/`chore` job. One job = one type; a refactor riding a feature has no preserve YC, no protecting test and no separate MR.

### Separate job

Do **not** create the worktree from here (it is created on the main checkout). Tell the human:
1. Finish this job as planned (through `/aw-ship`); the RFs do not enter its spec or plan.
2. Start the refactor job on the main checkout: `/aw-intake` with the RFs' requests as arguments. Print those `>` lines as one copyable block — they become a verbatim `[HUMAN]` input. Base: this job's base once it merged; RFs about code this job adds and cannot wait → stack on this branch (review warns).
3. When the human says the new job exists, set those RFs to `moved: <new-branch>`.

The file survives worktree cleanup in the archive (`aw worktree remove` copies the job dir there).

### This job

1. Add the file as input: `aw input --skip <dir>/intake.md <dir>/refactor-requests.md`, **append** stdout to `## Input` of `intake.md`, run `aw check intake <dir>`.
2. `spec.md` is now stale: `/aw-spec` writes YCs from the RFs (`preserve`/`structural` only), citing `[FILE] … § RF-NNN`. Approved spec → the human re-approves; `tdd.md`/`plan.md` exist → rerun `/aw-design`, `/aw-plan` after.
3. Implementation started → say which tasks are done and that the new YCs go to new tasks; never edit code here.

## Summary

Two to four lines: RFs recorded (count, ids), where they go, the next command for the human.

## Forbidden

- **Implementing:** editing code, tests, `spec.md`, `tdd.md`, `plan.md` or their boxes. Only `refactor-requests.md` and, in "This job" step 1, `intake.md` `## Input`.
- Paraphrasing a request, adding a solution or your own refactor ideas as RFs.
- Choosing the route for the human; creating a worktree or branch.
