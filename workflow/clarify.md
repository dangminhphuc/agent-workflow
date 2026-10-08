---
id: clarify
choice_ui: true
name: Chốt việc chờ người
summary: Dẫn bạn chốt từng điểm mù và phát hiện của checker đang chặn phase, việc gấp nhất trước
trace_rule: true
---

# Settle what waits on the human (clarify)

**Not a phase** — runs any time after `/aw-spec`. Collects everything the human must decide into one queue and walks them through it item by item. The agent **guides** (analyses, asks, records); the **human decides**. Talk to the human in Vietnamese.

## Two sources

| Source | File | Human does | Blocks |
|---|---|---|---|
| Open question | `open-questions.md` | **Answers** (often has to ask PO/BA) | By `Blocking` (`rules/source-tracing.md`) |
| LLM checker finding | `<checker>-findings.md` (currently `design-findings.md`) | **Arbitrates**: agree (fix) or reject + reason | `Chặn`: that phase's checker (`thiết kế` → `/aw-plan`); `Cảnh báo`: nothing |

The two files stay separate (one writer each, `based_on` hashes whole files); they merge only in what the human sees. Blocking levels are proposed by the agent, changed **only by the human**.

## 1. List — for you to read, NOT to paste

`aw pending <thư-mục-feature>` — order set by the machine, never re-sort: unlevelled → `blocking` → `Chặn` findings → `review-blocking` → `Cảnh báo` findings → `non-blocking` (within questions: `must` before `should`, more tasks on the assumption first, then by id).

The human sees **one line**:

```
Còn 6 việc chờ bạn: 3 đang chặn (YC-001, YC-002 chặn /aw-design; PH-03 chặn /aw-plan), 3 chưa chặn. Bắt đầu từ YC-001.
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
1. **Read enough:** the source passage, the YC in `spec.md`, related `tdd.md`/`plan.md`/code, `conventions.md`. LLM finding: read exactly its `Vị trí`.
2. **Split decisions:** an item bundling independent decisions → one question per decision, asked together in that turn (max 4).
3. **Find 2–3 options that differ in consequences** — from the source, common practice, constraints of existing code. No filler options; only one sensible option → offer one.
4. **Pick a recommendation:** weigh safety, rework cost, external impact, reversibility. The recommended option goes **first**, its label starts with `(Đề xuất)`.

Each choice: a short **label** naming the option; a one-line **description** of consequence/trade-off (differs from the temporary assumption → say what must be redone; taken from the source → cite it, e.g. `theo Input 2 § 4`; equals the temporary assumption → say "đang dùng làm giả định tạm").

Context right before the question, max 4 lines: id · group · what it blocks · position in queue; what the source says; why you recommend.

The human **always** has two exits, **last** in the list: type their own answer, and "Chat về câu này" (discuss before deciding):

```
  N.   Type something.  — tự nhập câu trả lời khác
  N+1. Chat about this.  — trao đổi thêm trước khi chốt
```

If the choice UI already provides them (e.g. Claude Code) → **do not** add duplicates. No choice UI → print those two lines yourself, numbered after the options.

### 2a. Open question

Example (human-facing text stays Vietnamese):

```
YC-006 · CHẶN REVIEW · 5/9 · 2 quyết định
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

Order (max 4): `(Đề xuất) <option>` → 1–2 other options (from the source first) → **Chưa trả lời được** (you draft a message to `<Ask>`). Free text also accepts "đổi mức chặn sang …" or "bỏ qua".

`CHƯA PHÂN MỨC` item: the first question picks the level (`blocking`/`review-blocking`/`non-blocking`), the one implied by "Nếu sai" first as `(Đề xuất)` — then ask for the answer.

### 2b. LLM checker finding

```
PH-03 · CHẶN · đang chặn /aw-plan · 3/6 · quyết định ngầm
tdd.md § Contract API: chọn gRPC cho webhook nội bộ nhưng không nêu thành D-xx.
  Checker nói: khó đảo ngược (contract ngoài); người khác có thể chọn REST.
  Vì sao đề xuất: hai service gọi tới đều đã có client gRPC (src/clients/*); đổi REST là thêm việc.

Xử lý phát hiện PH-03 thế nào?
  1. (Đề xuất) Nêu thành D-xx: giữ gRPC, phương án loại REST — bạn duyệt D sau
  2. Đổi sang REST cho khớp contract hiện có — sửa § Contract + § Flow
  3. Bác bỏ — nhập lý do ở ô tự nhập
  4. Type something.  — tự nhập cách xử lý khác
  5. Chat about this.  — trao đổi thêm trước khi chốt
```

Order (max 4): `(Đề xuất) <fix>` (what, which section) → 0–1 genuinely different fix → **Bác bỏ** ("nhập lý do ở ô tự nhập") → for `Cảnh báo`: **Để sau** (then only one fix). If you think the finding is wrong → put `(Đề xuất) Bác bỏ — <reason>` first; the human still chooses. Rejection without a reason → ask for it (`aw check` blocks empty rejections).

### Always

- After asking, **stop and wait**. Never ask the next item before this one is done.
- **"Chat về câu này" / "Chat about this":** answer, explain consequences, quote more source — **write no files**. Once clear, ask the same question again as choices (options updated by the discussion). A decision stated in chat → confirm it via choices before writing.

## 3. Record

### 3a. Open question

**Human answered:**
1. `open-questions.md`: `Answer:` = the human's **verbatim** words + who + date (e.g. `"Hoàn tiền tối đa 30 ngày" — PO, 2026-10-04`); `Status: answered`. Human **picked** an option → verbatim = its label (without `(Đề xuất)`) plus `(chọn từ phương án agent đề xuất)`. Several questions → record each answer.
2. `spec.md`: change the YC's source label to `[FILE]` open-questions.md § YC-NNN (or the source the human named). Remove that YC's `Assumption` line.
3. **Answer differs from the assumption:** edit the description / criteria of **that YC only**. First show the lines that will change (before → after) and ask "ghi như vậy được không?" (agreement in chat is enough). Append `(đã xác nhận sửa YC-NNN)` to `Answer:`. Same as the assumption → only change the label.
4. Spec was ticked and steps 2–3 changed it → **untick** (you may untick, never tick). Remind the human to re-tick in the summary.
5. `aw check spec <thư-mục-feature>`, paste the real result. Not `[x] ĐẠT` → make the files agree before the next item.

**Cannot answer yet:** draft a message to `Ask`, self-contained (readable without the repo): the question, what the documents say, the assumption in use, impact if wrong, which phase is waiting. Keep `open`, next item.

**Human changes the level:** write exactly the level they said into `Blocking:`. You may only **propose raising** it, never lower it.

### 3b. LLM checker finding

**Agree:**
1. Show the lines that will change in `tdd.md` (before → after), ask "ghi như vậy được không?". Edit only where the finding points.
2. Needs a decision (`quyết định ngầm`, or `lệch D-xx` where the human wants to change the D) → add/edit a D-xx with an **unticked** box (editing an approved D: follow "Reopening a D-xx" in `/aw-design`).
3. `yêu cầu mới` → **remove that behaviour from `tdd.md`**. Human wants to keep it → it is a new requirement: back to `/aw-spec`, never add a YC yourself.
4. Findings file: `Xử lý: đã sửa`.
5. `aw check design <thư-mục-feature>`, paste the real result.

**Reject:** `Xử lý: bác bỏ: <verbatim reason> — <who>, <date>`. Do not edit `tdd.md`.

**Để sau** (`Cảnh báo` only): keep `chưa`, next item.

## 4. Summary

Rerun `aw pending` (read, do not paste), then say briefly:
- what still blocks which phase; which questions wait on whom (drafted messages);
- findings closed but not arbitrated by the human this round (group `[ĐÃ XỬ LÝ]`, usually self-fixed in `/aw-design`): id + one line;
- new/edited D-xx awaiting approval; spec just unticked → human re-ticks;
- artifacts now stale because inputs changed (`tdd.md`, `plan.md`): answer **matches** the assumption → rerun that phase to refresh the input hash; **differs** → that phase redoes what "Nếu giả định sai" lists, and tasks on that assumption go back to `[ ]` when `/aw-plan` reruns. `tdd.md` just edited for a finding and `plan.md` exists → rerun `/aw-plan`.

## Forbidden

- **Deciding for the human:** answering, agreeing/rejecting, writing `answered`/`đã sửa`/`bác bỏ` before the human said so.
- Paraphrasing answers or rejection reasons instead of verbatim.
- Treating your recommendation as the decision before the human chose.
- Asking without analysis: only "keep assumption / cannot answer" when real options exist; filler options; bundling independent decisions in one question.
- `(Đề xuất)` anywhere but the start of a label, or on more than one option.
- Lowering/changing `Blocking` without the human; changing a finding's `Mức`.
- Ticking approval boxes, editing/deleting `<!-- approval-hash: … -->` (you may only **untick** the spec in 3a step 4).
- Editing a YC / `tdd.md` before the human confirmed the changed lines, or outside the current item.
- Presenting several items at once; pasting the `aw pending` list unasked.
- Dropping the free-text or "Chat về câu này" exit.
- Editing `plan.md` or code, or rerunning the LLM checker to "clean" findings — just say which phase to rerun.
