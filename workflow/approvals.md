---
id: approvals
choice_ui: true
feature_dir: none
name: Duyệt tập trung
summary: Liệt kê mọi ô "Approved by human" đang chờ bạn (kèm link tới artifact), dẫn bạn duyệt từng mục; bạn chọn Duyệt thì máy tick hộ
arguments: mixed
argument_hint: [--global]
---

# Review pending approvals (approvals)

**Not a phase** — runs any time, in a job's worktree or on the main checkout. Collects every "Approved by human" box still waiting (spec, each D-xx) and walks the human through them one by one. The **human decides**; you show, ask, and run the tick command only for what they approved.

## 1. List

Arguments contain `--global` → `aw approvals --global` (every worktree of this clone); otherwise `aw approvals` (this worktree only). Ignore any other argument.

| Result `[x]` | Do |
|---|---|
| `KHÔNG CÒN Ô CHỜ DUYỆT` | One line. Not `--global` → add that `/aw-approvals --global` checks every worktree. Stop |
| `CÓ Ô CHỜ DUYỆT` | Print stdout **verbatim** in a ```` ```text ```` block (it holds the links), then step 2 |
| `SAI THAM SỐ` | Report the error, stop |

Items under "Ô duyệt sai dạng/chỗ" cannot be approved here: list them at the end, the job's own phase fixes them.

## 2. One item per turn, in the listed order

Before asking, show what is being approved — built from files, never your own paraphrase:
- `spec`: stdout of `aw approval design <dir>` (no design phase — chore or `Design: skip`, no `tdd.md` expected — `aw approval plan <dir>`).
- `D-NN`: the whole `### D-NN` section of `<dir>/tdd.md`, verbatim.
- State "ĐÃ ĐỔI sau khi duyệt": say the human approved an earlier version and must re-read the whole item.

`<dir>` = the path in the item's `duyệt:` line. Always repeat the item's `path:line` link right above the question.

Ask one choice question (header: item key and position, e.g. `D-02 2/4`), options in this order:
1. `Duyệt` — "Tôi đã đọc <file>:<line> và đồng ý"
2. `Chưa duyệt — cần sửa` — ask what must change
3. `Bỏ qua` — next item, box stays empty
4. `Dừng` — stop the walk

No `(Đề xuất)` label here: never recommend approving.

| Human picks | Do |
|---|---|
| `Duyệt` | Run that item's `duyệt:` line **exactly** (`aw approvals tick <dir> <key> <hash>`). `ĐÃ DUYỆT` → next item. `KHÔNG TICK` → rerun step 1's list, show the item again, ask again. Tool permission denied → not approved, next item |
| `Chưa duyệt — cần sửa` | Note their reason verbatim; do not edit any artifact here. Next item |
| `Bỏ qua` | Next item |
| `Dừng` / anything else | Go to step 3 |

Hard limits:
- Run `aw approvals tick` **only** for the item the human just picked `Duyệt` for, in this turn, with the hash printed by the list. One answer approves one item — never "approve all".
- Never tick by editing the file, never write or edit `approval-hash`, never reuse a hash from memory.

## 3. Summary

Max 6 lines: approved (keys), not approved with the human's reason and the worktree to open (`<branch>` → run the phase there, e.g. `/aw-spec`, `/aw-design`), skipped, malformed boxes. Then the next command for each job whose gate is now open (`/aw-design` after spec, `/aw-plan` after every D-xx).
