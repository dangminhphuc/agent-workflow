# Spec: Lệnh duyệt riêng cho từng phase (`/aw-<phase>-approve`)

- Ngày: 2026-10-27 · Branch: `claude/serene-dijkstra-gh7r5n`
- Trạng thái: **nháp — chờ người duyệt spec** trước khi viết plan/code.
- Interface: không đổi capability/invariant (`CAP-require-03`, `CAP-design-03`, `INV-005` vẫn do máy tick,
  người quyết). Đây là lệnh tiện ích + cơ chế khai báo; ngoài mọi stage → "no interface change: lệnh tiện ích".

## 0. Yêu cầu và quyết định đã chốt

Người dùng muốn tách `/aw-approvals` thành lệnh riêng cho từng phase, dạng `/aw-<phase>-approve`
(hoặc `aw-<phase>:approve`). Đã chốt:

| Quyết định | Chốt |
|---|---|
| Dấu | `-`, không `:` — `:` hỏng tên file trên Windows, Claude Code đọc `/a:b` là lệnh plugin, adapter sẽ sinh khác nhau và phá test `AW_COMPARE=1` (SP31 §3.1) |
| Phạm vi | Chỉ phase **có ô "Approved by human"**: `spec`, `design`. Phase không có ô (`intake`, `plan`, `implement`, `review`, `ship`) không có lệnh `-approve` |
| `/aw-approvals` | **Giữ** làm lệnh duyệt tổng (cả hai phase, `--global`) |
| Tên phase | Theo tên hiện tại (`spec`, `design`). SP31 đổi tên phase sau khi merge thì lệnh đổi theo (id sinh từ phase) |
| Hướng B của SP31 §3.2 (`/aw-approvals <stage>`) | Thay bằng quyết định này; ghi vào `docs/kien-truc.md` |

Mục tiêu: gõ `/aw-spec-approve` chỉ thấy và duyệt ô của spec; `/aw-design-approve` chỉ thấy các `DEC-NNN`.
**Không** nới quyền: agent vẫn chỉ tick ngay sau khi người chọn `Duyệt` cho đúng một mục.

## 1. Cơ chế (để mở rộng được, không hard-code từng phase)

Hiện `tools/approvals.sh` hard-code hai loại artifact (`spec`, `tdd`) và `workflow/approvals.md` hard-code
cách hiển thị từng loại. Thêm phase thứ ba có ô duyệt sẽ phải sửa cả hai chỗ. Đề xuất đặt cơ chế vào **khai báo
trong phase**, lệnh `-approve` sinh từ khai báo đó.

### 1.1 Khai báo trong frontmatter phase

Phase có ô duyệt khai một khoá mới:

```yaml
approves: spec        # phase 01-spec.md  — loại artifact: spec.md, khoá mục: spec
approves: tdd         # phase 02-design.md — loại artifact: tdd.md, khoá mục: DEC-NNN
```

- Giá trị = `LOAI` mà `tools/lib/approval-tick.sh` (`dy_trang_thai`, `dy_quet`, `dy_hash`) đã hiểu. Giá trị ngoài
  tập đó → `aw adapter build` báo lỗi (như các khoá frontmatter khác).
- Phase không có khoá này → không sinh `-approve`.
- Một phase khai tối đa một loại (hai phase hiện tại đều một loại).

### 1.2 Lệnh sinh ra

Adapter (`adapters/lib/common.sh`, `ad_sinh`) với mỗi phase có `approves:` sinh thêm một lệnh
`<tiền tố><id>-approve` (`aw-spec-approve`, `aw-design-approve`):

- Thân lệnh = **một file dùng chung** `workflow/approve.md` (thân của `/aw-approvals` hiện tại, đã tách phần riêng
  theo phase ra tham số) + dòng đầu nêu phase và loại artifact. Không nhân bản nội dung: "một luật một chỗ".
- Frontmatter lệnh sinh: `name`, `summary` (tiếng Việt, "Duyệt ô Approved by human của phase <id>"),
  `feature_dir: none`, `choice_ui: true`, `argument_hint: [--global]` — giống `/aw-approvals`.
- Là lệnh tiện ích: không `implements:`, không vào bảng phase/stage; `disable-model-invocation` như các lệnh
  tiện ích khác.
- `/aw-approvals` giữ nguyên, tức `approves:` = cả hai loại.

### 1.3 Lọc ở máy: `aw approvals --phase <id>`

`tools/approvals.sh` nhận thêm `--phase <id>` (kết hợp được với `--global`):

- `id` phải là phase có `approves:`; ngoài ra → `SAI THAM SỐ` (nhãn có sẵn), in danh sách id hợp lệ.
- Chỉ duyệt/lọc loại artifact của phase đó (`spec` → `spec.md`; `design` → `tdd.md`).
- `aw approvals tick` **không đổi** (đối số `<dir> <key> <hash>`, kiểm hash, nhật ký) — tick đã tự suy ra loại từ
  khoá; thêm lọc phase vào `tick` chỉ tăng bề mặt lỗi.
- Nhãn kết quả: không thêm nhãn mới. `KHÔNG CÒN Ô CHỜ DUYỆT` khi phase đó hết ô (dù phase kia còn).

## 2. Nội dung cho AI (đưa vào `workflow/approve.md`, tiếng Anh, rút gọn từ `approvals.md`)

Đây là phần agent đọc khi chạy `/aw-<phase>-approve`. Dạng mệnh lệnh, không nhắc lại hợp đồng I/O hay việc checker làm:

1. **Scope.** Phase = `<id>` (injected by the adapter). Run `aw approvals --phase <id>` (add `--global` when the
   arguments contain it). Ignore other arguments.
2. **List result `[x]`.** `KHÔNG CÒN Ô CHỜ DUYỆT` → one line; say `/aw-approvals` covers the other phase; stop.
   `CÓ Ô CHỜ DUYỆT` → print stdout verbatim in a `text` block, then walk. `SAI THAM SỐ` → report, stop.
3. **Show before asking** — built from files, never paraphrased: `spec` → `aw approval design <dir>` (or
   `aw approval plan <dir>` when no design phase); `DEC-NNN` → the whole `### DEC-NNN` section of `tdd.md`.
   "ĐÃ ĐỔI sau khi duyệt" → say so and require re-reading the whole item.
4. **One item per turn**, in the listed order; one choice question: `Duyệt` / `Chưa duyệt — cần sửa` / `Bỏ qua` /
   `Dừng`. No recommended option — never recommend approving.
5. **Tick rules (unchanged, non-negotiable).** Run the item's `duyệt:` line exactly, only for the item the human
   just picked `Duyệt` for in this turn, with the hash from this turn's list. Never tick by editing a file, never
   write `approval-hash`, never "approve all".
6. **Summary** (≤ 6 lines) and the next command for jobs whose gate opened (`/aw-design` after spec,
   `/aw-plan` after every DEC).

Phần riêng theo phase (bước 3) lấy từ bảng loại → cách hiển thị đặt ở **một chỗ** trong `approve.md`; thêm phase mới
chỉ thêm một dòng ở bảng đó + `approves:` ở phase.

## 3. Thay đổi file

| File | Việc |
|---|---|
| `workflow/phases/01-spec.md`, `02-design.md` | Thêm `approves: spec` / `approves: tdd` vào frontmatter |
| `workflow/approve.md` (mới) | Thân dùng chung (§2); `workflow/approvals.md` rút về dùng cùng nguồn hoặc trỏ tới, tránh hai bản |
| `adapters/lib/common.sh` | Đọc `approves:`, sinh `<id>-approve`; kiểm giá trị; xoá lệnh cũ khi build lại (dấu "SINH TỰ ĐỘNG") |
| `tools/approvals.sh` | `--phase <id>`; lọc theo loại; `kq_khai` giữ nguyên nhãn |
| `workflow.yaml`, `bin/aw`, `bin/aw-engine` | Chú thích/usage `--phase` (không thêm lệnh engine mới) |
| `workflow/rules/general.md` | Câu "Only `/aw-approvals` runs `aw approvals tick`" → "only `/aw-approvals` and `/aw-<phase>-approve`" (cả `adapters/lib/common.sh:306`) |
| Tài liệu | `README.md`, `docs/huong-dan.md` (bảng lệnh), `docs/kien-truc.md` (lý do `-`, thay hướng B, cơ chế `approves:`, § Định dạng file phase thêm khoá), `docs/thuat-ngu.md` nếu có thuật ngữ mới, roadmap, `changes/claude-serene-dijkstra-gh7r5n.md` (`Thêm`: hai lệnh; `Thay đổi`: `aw approvals --phase`; người dùng `aw adapter build` lại) |

## 4. Kiểm thử (viết trước code)

Thêm vào các part cùng chủ đề (`tools/tests/lib.sh` helpers); mỗi checker thử cả hai chiều:

- `approvals.sh`: `--phase spec` chỉ liệt kê ô spec, bỏ DEC; `--phase design` ngược lại; `--phase spec --global`;
  phase còn ô ở loại kia nhưng loại được hỏi hết → `KHÔNG CÒN Ô CHỜ DUYỆT`; `--phase intake` /
  `--phase` thiếu giá trị → `SAI THAM SỐ`; `tick` không đổi hành vi.
- `08-adapters.sh`: build sinh đúng `aw-spec-approve` và `aw-design-approve`, không sinh `aw-plan-approve`;
  `approves: foo` → build lỗi; bỏ `approves:` khỏi phase rồi build lại → xoá lệnh sinh cũ.
- Compare (`AW_COMPARE=1`): output giống hệt giữa các adapter (không `:`).
- Test chuỗi: luật "Never approve" trong rules/adapter nhắc đúng hai nơi được tick.
- Kết thúc `sh tools/run-tests.sh` = `MỌI CA ĐẠT`; `sh tools/check-sdlc.sh` đạt.

## 5. Ngoài phạm vi

- Không thêm ô duyệt cho phase khác; không đổi `tick`, hash, nhật ký.
- Không đổi tên phase (SP31 làm).
- Không hỗ trợ `:`; muốn dùng sau này là dự án riêng (adapter sinh khác nhau).

## 6. Câu hỏi còn mở (cần người chốt khi duyệt spec)

1. `approves:` có đủ, hay muốn khai thẳng khoá mục (`spec`, `DEC-NNN`) trong frontmatter? Đề xuất: chỉ khai `LOAI`
   (máy đã suy khoá).
2. `workflow/approvals.md` có nên thành lệnh sinh từ cùng `approve.md` (không `--phase`) để chỉ còn một thân?
   Đề xuất: có — hai lệnh khác nhau chỉ ở dòng đầu.
