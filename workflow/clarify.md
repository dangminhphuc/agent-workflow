---
id: clarify
choice_ui: true
name: Chốt việc chờ người
summary: Dẫn bạn chốt từng `open question` và `finding` của checker đang chặn phase, việc gấp nhất trước; hoặc đổi một REQ bạn không đồng ý
arguments: mixed
argument_hint: [REQ-NNN] [tên-feature]
trace_rule: true
---

# Settle what waits on the human (clarify)

**Not a phase** — runs any time after `/aw-spec`. Collects everything the human must decide into one queue and walks them through it item by item, then writes every decision **in one go** (one preview, one confirmation — section 3). The agent **guides** (analyses, asks, records); the **human decides**. Talk to the human in Vietnamese.

## Two sources

| Source | File | Human does | Blocks |
|---|---|---|---|
| Open question | `open-questions.md` | **Answers** (often has to ask PO/BA) | By `Blocking` (`rules/source-tracing.md`) |
| LLM checker finding | `<checker>-findings.md` (`spec-findings.md`, `design-findings.md`) | **Arbitrates**: agree (fix) or reject + reason | `block`: the next phase (`spec-findings.md` → `/aw-design`, or `/aw-plan` when design is skipped; `design-findings.md` → `/aw-plan`); `warn`: nothing |

Blocking levels and `Severity` are proposed by the agent, changed **only by the human**.

The human may also **change a REQ** they disagree with (`/aw-clarify REQ-NNN`, or says so mid-queue). Not in `aw pending` — do it first: section 5.

## 1. List — for you to read, NOT to paste

`aw pending <dir>` — order set by the machine, never re-sort: unlevelled → `blocking` → `block` findings → `review-blocking` → `warn` findings → `non-blocking` (within questions: `must` before `should`, more tasks on the assumption first, then by id).

The human sees **one line**:

```
Còn 6 việc chờ bạn: 3 đang chặn (REQ-001, REQ-002 chặn /aw-design; FND-003 chặn /aw-plan), 3 chưa chặn. Bắt đầu từ REQ-001.
```

Print the full list (id + title + group, one per line) only if the human asks.

| Result `[x]` | Do |
|---|---|
| `KHÔNG CÒN VIỆC CHỜ NGƯỜI` | One line (plus the `[ĐÃ XỬ LÝ]` group if any — step 4), stop |
| `CÓ VIỆC ĐANG CHẶN` | Summary line, go to step 2 |
| `CÒN VIỆC CHỜ NGƯỜI, CHƯA CHẶN` | Summary line, ask with choices "Giải quyết luôn" / "Để sau" |
| `THIẾU ĐẦU VÀO` | No `spec.md`/`open-questions.md` → run `/aw-spec` first |

## 2. Ask one item per turn, in order

### Think before asking

Choices are **solution options**, not procedure. Before each item:
1. **Read enough:** the source passage, the REQ in `spec.md`, related `tdd.md`/`plan.md`/code, `conventions.md`. LLM finding: read exactly its `Location`.
2. **Split decisions:** an item bundling independent decisions → one question per decision, asked together in that turn (max 4).
3. **Find 2–3 options that differ in consequences** — from the source, common practice, constraints of existing code. No filler options; only one sensible option → offer one.
4. **Pick a recommendation:** weigh safety, rework cost, external impact, reversibility. The recommended option goes **first**, its label starts with `(Đề xuất)`.

Each choice: a short **label** naming the option; a one-line **description** of consequence/trade-off (differs from the temporary assumption → say what must be redone; taken from the source → cite it, e.g. `theo Input 2 § 4`; equals the temporary assumption → say "đang dùng làm giả định tạm").

Context right before the question, max 4 lines: id · group · what it blocks · position in queue; what the source says; why you recommend.

The human **always** has two exits, **last** in the list: type their own answer, and "Chat about this" (discuss before deciding):

```
  N.   Type something.  — tự nhập câu trả lời khác
  N+1. Chat about this.  — trao đổi thêm trước khi chốt
```

If the choice UI already provides them (e.g. Claude Code) → **do not** add duplicates. No choice UI → print those two lines yourself, numbered after the options.

### 2a. Open question

Example (human-facing text stays Vietnamese):

```
REQ-006 · CHẶN REVIEW · 5/9 · 2 quyết định
Nguồn: Input 1 chỉ nói "chỉ client trong allowlist được gọi"; không nói mã lỗi, không nói route chưa khai.
Vì sao đề xuất: 403 tách khỏi 401 nên đối tác biết là thiếu quyền chứ không sai key;
  từ chối mặc định để route mới không lọt ra ngoài khi quên khai.

(1/2) Credential hợp lệ nhưng ngoài allowlist thì trả gì?
  1. (Đề xuất) 403 problem+json, mã lỗi riêng — đang dùng làm giả định tạm
  2. 404 — giấu route khỏi bên dò quét; đối tác khó debug
  3. 403 không body chi tiết — đơn giản; đối tác phải hỏi support
  4. Chưa trả lời được — soạn tin gửi chủ admin-portal; /aw-review sẽ chặn
  5. Type something.  — tự nhập câu trả lời khác
  6. Chat about this.  — trao đổi thêm trước khi chốt

(2/2) Route chưa có definition thì chặn hay cho qua?
  …
```

Order (max 4): `(Đề xuất) <option>` → 1–2 other options (from the source first) → **Chưa trả lời được** (you draft a message to `<Ask>`). Free text also accepts "đổi mức `Blocking` sang …" or "bỏ qua".

`CHƯA PHÂN MỨC` item: the first question picks the level (`blocking`/`review-blocking`/`non-blocking`), the one implied by "If wrong, redo" first as `(Đề xuất)` — then ask for the answer.

### 2b. LLM checker finding

```
FND-003 · CHẶN · đang chặn /aw-plan · 3/6 · hidden-decision
tdd.md § Contract API: chọn gRPC cho webhook nội bộ nhưng không nêu thành DEC-xxx.
  Checker nói: khó đảo ngược (contract ngoài); người khác có thể chọn REST.
  Vì sao đề xuất: hai service gọi tới đều đã có client gRPC (src/clients/*); đổi REST là thêm việc.

Xử lý phát hiện FND-003 thế nào?
  1. (Đề xuất) Nêu thành DEC-xxx: giữ gRPC, phương án loại REST — bạn duyệt DEC sau
  2. Đổi sang REST cho khớp contract hiện có — sửa § Contract + § Flow
  3. Bác bỏ — nhập lý do ở ô tự nhập
  4. Type something.  — tự nhập cách xử lý khác
  5. Chat about this.  — trao đổi thêm trước khi chốt
```

Order (max 4): `(Đề xuất) <fix>` (what, which section) → 0–1 genuinely different fix → **Bác bỏ** ("nhập lý do ở ô tự nhập") → for `warn`: **Để sau** (then only one fix). If you think the finding is wrong → put `(Đề xuất) Bác bỏ — <reason>` first; the human still chooses. Rejection without a reason → ask for it (`aw check` blocks empty rejections).

### Always

- After asking, **stop and wait**. Never ask the next item before this one is decided.
- Decided → **write nothing yet**: keep the decision (verbatim words, who, date, the changes it implies) and go to the next item. Close it in one line (`FND-038: sửa theo phương án A — ghi cùng đợt.`), no preview.
- A later item touching what an earlier decision changes → build on the pending version, not on the file.
- **"Chat about this":** answer, explain consequences, quote more source — **write no files**. Once clear, ask the same question again as choices (options updated by the discussion). A decision stated in chat → confirm it via choices before recording.
- **Typed text is a question, not an answer** (asks what a term/screen/option means, asks to confirm your reading, ends in `?`, "phải không", "là gì"…) → handle as "Chat about this": answer it, quoting the source passage verbatim (file + section); not in the documents → say so. **Never** record it as `Answer:` or a rejection reason. Then ask the same question again as choices. Unsure whether it is a question or an answer → ask which, before recording anything.

## 3. Record — one preview, one write

Write when the queue is done, or earlier when the human says so: stops (`dừng`, `để sau phần còn lại`) → write what is decided, the rest stays `open`; `ghi luôn` → write what is decided, then continue the queue. Nothing decided → write nothing.

### 3.1 Preview, confirm once

Build every change from all decided items (3a, 3b, section 5), then show **one** preview, grouped by file (`open-questions.md`, `spec.md`, `tdd.md`, findings file), each change tagged with its item id:
- edited text in `spec.md` / `tdd.md` → before → after (`-` / `+` lines), only the lines that change;
- new blocks (a DEC-xxx) → `+` lines;
- bookkeeping (`Answer`, `Status`, `Resolution`, `Blocking`, source label, removed `Assumption`, untick) → one line per item, no diff;
- same section changed by several items → one combined before → after naming all of them; new DEC-xxx numbered consecutively across the batch.

Then ask once: "ghi như vậy được không?" (agreement in chat is enough). Human corrects some lines → fix only those, show only the corrected parts, ask again. Human withdraws a decision → drop its changes; the item stays `open` for the next run.

### 3.2 Write

Write everything, then: `aw task reopen <dir> REQ-NNN` once per REQ whose description/criteria changed (no `plan.md` → nothing to do); `aw check spec <dir>` if `spec.md` / `open-questions.md` changed; `aw check design <dir>` if `tdd.md` / findings changed. Paste the real results. Not `[x] ĐẠT` → make the files agree; a fix that changes lines the human confirmed → show that part and ask again.

### 3a. Open question — what to write

**Human answered:**
1. `open-questions.md`: `Answer:` = the human's **verbatim** words + who + date (e.g. `"Hoàn tiền tối đa 30 ngày" — PO, 2026-10-04`); `Status: answered`. Human **picked** an option → verbatim = its label (without `(Đề xuất)`) plus `(chọn từ phương án agent đề xuất)`. Several questions → record each answer.
2. `spec.md`: change the REQ's source label to `[FILE]` [open-questions.md § REQ-NNN](open-questions.md#req-nnn) (or the source the human named), and its `Quote:` to the `Answer:` words (or that source's sentence), verbatim. Remove that REQ's `Assumption` line.
3. **Answer differs from the assumption:** edit the description / criteria of **that REQ only** (before → after in the preview). Append `(đã xác nhận sửa REQ-NNN)` to `Answer:`; reopen its tasks (3.2). Same as the assumption → only change the label.
4. Spec was ticked and steps 2–3 change it → **untick** (you may untick, never tick). Remind the human to re-tick in the summary.

**Cannot answer yet:** draft a message to `Ask`, self-contained (readable without the repo): the question, what the documents say, the assumption in use, impact if wrong, which phase is waiting. Show it right away (the human sends it); keep `open`, next item.

**Human changes the level:** write exactly the level they said into `Blocking:`. You may only **propose raising** it, never lower it.

### 3b. LLM checker finding — what to write

**Agree:**
1. `tdd.md`: edit only where the finding points (before → after in the preview).
2. Needs a decision (`hidden-decision`, or `deviates-from-decision` where the human wants to change the DEC) → add/edit a DEC-xxx with an **unticked** box (editing an approved DEC: follow "Reopening a DEC-xxx" in `/aw-design`).
3. `new-requirement` → **remove that behaviour from `tdd.md`**. Human wants to keep it → it is a new requirement: back to `/aw-spec`, never add a REQ yourself.
4. Findings file: `Resolution: fixed`.

**Reject:** `Resolution: rejected: <verbatim reason> — <who>, <date>`. Do not edit `tdd.md`.

**Để sau** (`warn` only): keep `open`, next item.

## 4. Summary

After the write (3.2), rerun `aw pending` (read, do not paste), then say briefly:
- what still blocks which phase; which questions wait on whom (drafted messages);
- findings closed but not arbitrated by the human this round (group `[ĐÃ XỬ LÝ]`, usually self-fixed in `/aw-design`): id + one line;
- new/edited DEC-xxx awaiting approval; spec just unticked → human re-ticks;
- artifacts now stale because inputs changed (`tdd.md`, `plan.md`): answer **matches** the assumption → rerun that phase to refresh the input hash; **differs** (or a REQ was changed, section 5) → `/aw-design` redoes what "If wrong, redo" lists, then `/aw-plan`. `tdd.md` just edited for a finding and `plan.md` exists → rerun `/aw-plan`.

## 5. Changing a REQ (human-initiated)

The human disagrees with how the spec reads a source — description, criteria or `Priority` of an existing REQ. The change is recorded as an **answered open question**, so the human's words become the REQ's source and `aw check spec` cross-checks the two files.

| Request | Route |
|---|---|
| REQ still `[OPEN-QUESTION]` | Ordinary open question: 2a, 3a |
| Change an existing REQ | This section |
| Add a REQ, drop one, move something in/out of `## Out of scope` | Scope change: the human adds it to `intake.md` as `[HUMAN]` input, then `/aw-spec`. Never add/delete a REQ here |
| `Blocking` | 3a "Human changes the level" |
| `Risk`, `Design`, `## Constraints & dependencies` | Before → after in the batch preview (section 3), write exactly what the human said, untick the spec. `tdd.md` exists → rerun `/aw-design` (`Risk` now `high` → Mode 2). `Design` now `required` with no `tdd.md` → `/aw-design`, then `/aw-plan` |

1. **Read** the REQ, its `Source:` passage, what depends on it: `tdd.md` (`REQ mapping`, `Based on: DEC-xxx` of those sections), `plan.md` (`Covers: REQ-NNN`).
2. **Ask** as in 2a. Context: what the source says, what the REQ says now, what must be redone (step 1). Options: the human's change as they stated it, keep the current reading, at most one other reading the source supports.
3. **`open-questions.md`** (written in 3.2, like everything else) — the REQ's entry; create `### REQ-NNN — <same title as spec>` under `## Questions` if missing (replacing a "No open questions." line):
   - `Source says` verbatim; `Question`: the reading in dispute; `Ask`: the human; `Assumption`: the previous reading; `If wrong, redo`: what step 1 found;
   - `Status: answered`; `Answer:` verbatim + who + date + `(đã xác nhận sửa REQ-NNN)`.
   - Entry already answered → move the old answer to `- **Superseded answer:** …`, then write the new `Answer:`.
4. **`spec.md`**: before → after of that REQ's lines in the batch preview; edit **that REQ only**; source label → `[FILE]` [open-questions.md § REQ-NNN](open-questions.md#req-nnn), `Quote:` → the new `Answer:` words verbatim. **Untick** the spec.
5. After the write: `aw task reopen <dir> REQ-NNN` and `aw check spec <dir>` (3.2) — paste both real results.
6. Summary (section 4): spec unticked → the human re-ticks. `tdd.md` exists → `/aw-design` updates the sections mapped to REQ-NNN (a DEC-xxx no longer fits → "Reopening a DEC-xxx"), then `/aw-plan`.

## Forbidden

- **Deciding for the human:** answering, agreeing/rejecting, writing `answered`/`fixed`/`rejected` before the human said so.
- Paraphrasing answers or rejection reasons instead of verbatim.
- Treating your recommendation as the decision before the human chose.
- Lowering/changing `Blocking` without the human; changing a finding's `Severity`.
- Ticking approval boxes, editing/deleting `<!-- approval-hash: … -->` (you may only **untick** the spec: 3a step 4, section 5).
- Writing any file before the human confirmed the batch preview, or changing lines that were not in it.
- Writing per item (preview → confirm → write, then the next item) instead of one batch — unless the human asked `ghi luôn`.
- Editing `plan.md` (only `aw task reopen` resets tasks) or code, or rerunning the LLM checker to "clean" findings — just say which phase to rerun.
