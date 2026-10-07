---
id: intake
name: Tiếp nhận việc
summary: Bước 1/6 · Bắt đầu việc mới từ ticket, URL hoặc file: chốt loại việc, tạo worktree, ghi intake.md
required: true
inputs:
  - confluence
  - jira
  - file
outputs:
  - intake.md
exit_machine:
  - aw check intake
exit_human:
  - Người CHỌN BASE cho worktree (agent chỉ đưa đề xuất của aw worktree new)
  - Người xác nhận LOẠI VIỆC (chọn sai loại là sai luật cả chuỗi phía sau)
  - Người xác nhận danh sách input, và lời mình được chép đúng nguyên văn
needs_clean_context: true
arguments: input
---

# Phase 00 — Tiếp nhận

## Mục tiêu

Trả lời đúng ba câu, ghi vào `intake.md`:
1. **Loại việc** — `feature`, `bugfix`, `refactor`, `perf` hay `chore`. Loại việc đổi luật của các phase sau.
2. **Input** — tài liệu có định danh, hoặc lời người dùng. Mọi `YC-xxx` về sau truy về đây.
3. **Mục tiêu** một câu.

## Loại việc

Xếp theo **thay đổi gì về hành vi**:

```
Có sửa code chạy trên production không?
├─ Không → chore
└─ Có → Hành vi quan sát từ ngoài có đổi không?
        ├─ Không → nhanh hơn / ít tài nguyên hơn? → có: perf / không: refactor
        └─ Có → Hành vi hiện tại đang SAI so với tài liệu / ý định?
                ├─ Có  → bugfix
                └─ Không → feature
```

| Loại | Luật khác biệt |
|---|---|
| `feature` | Quy trình chuẩn |
| `bugfix` | Spec có "Reproduction"; test tái hiện phải **đỏ trên code chưa sửa** (`aw check repro`) |
| `refactor` | YC chỉ `preserve`/`structural`; YC preserve có test bảo vệ sẵn trên nhánh gốc; không xoá test cũ, sửa test cũ phải khai |
| `perf` | Như refactor + YC `performance` có số liệu, số đo trước/sau do máy ghi (`aw check perf`) |
| `chore` | Không có design; không đụng code production; nâng dependency phải khai (major = refactor) |

- Không phải loại riêng: `utils` (thêm hàm dùng chung = feature, gom code trùng = refactor), `hotfix` (= bugfix gấp), `security` (= bugfix/feature + rủi ro cao).
- `spike` nằm ngoài quy trình (output là kết luận, không phải code để merge).
- Việc vừa loại này vừa loại kia → **tách hai việc** (hai worktree).

## Tham số của lệnh = input

`/aw-intake JIRA-123 https://confluence/…` — tham số là danh sách input, không phải tên feature (tên feature lấy từ branch).

**Nhãn do máy gán** (`aw input`, xem Bước 0b): chép **đúng stdout** vào `## Input`, không tự gán, không sửa. Chỉ cần một token không nhận ra là **cả chuỗi** thành một mục `[HUMAN]` nguyên văn; nguồn nằm trong câu (vd `ABC-123` trong "sửa phí hoàn tiền ABC-123") chỉ là **đề xuất tách thêm** — hỏi người, đồng ý mới ghi dòng riêng.

## Tạo worktree (đang ở checkout chính)

Worktree bắt buộc. Checkout chính luôn đứng ở `base_branch`, chỉ dùng chạy `/aw-intake`. `ĐANG Ở CHECKOUT CHÍNH` với `/aw-intake` = tạo worktree; với lệnh khác = dừng.

Agent **không quyết** vị trí worktree hay base. Theo thứ tự:

1. Đọc input, **chốt loại việc với người** (cây phân loại ở trên).
2. Chọn mô tả ngắn: chữ thường ASCII, số, `-` (vd `phi-hoan-tien`).
3. `aw worktree new <loại-việc> <mô-tả>` — **chỉ in đề xuất**: tên theo `type_by_prefix` (branch, thư mục worktree, thư mục artifact cùng một tên), đường dẫn theo `worktree_dir`, danh sách **base** kèm dữ kiện. Dấu ★ là gợi ý của máy, không phải của agent.
4. Đưa **nguyên văn** đề xuất cho người; người **chọn base** và xác nhận tên (muốn tên khác → đổi `<mô-tả>`, chạy lại bước 3).
5. `aw worktree new <loại-việc> <mô-tả> --create --base <ref>` với **đúng ref người chọn**. Chép nguyên hai dòng `Base:` và `Engine:` nó in vào `intake.md`.
6. Ghi `intake.md` vào `<worktree>/.agent-workflow/<tên>/`, chạy `aw check intake` trên thư mục đó, rồi **dừng**: người chạy lệnh chuẩn bị (`LENH_CHUAN_BI_WT` script in ra) và mở phiên agent **mới** trong worktree để chạy `/aw-spec`. Phiên mới: `aw ready <thư-mục-feature>` cho biết môi trường đủ chưa và bước tiếp.

`ĐÃ CÓ WORKTREE`: không tạo gì — bảo người mở phiên ở đường dẫn script in, chạy lại `/aw-intake` ở đó nếu cần gộp input.

- **Base:** checker so diff với điểm rẽ khỏi base này. Base là branch việc khác (xếp chồng) được, review sẽ cảnh báo.
- **Engine:** mọi checker của việc chạy đúng version này (khớp chính xác `YYYY.M.N`). Không tải được version đó → checker báo KHÔNG HỢP LỆ. Nâng engine giữa chừng không đổi luật việc đang làm.

## Đang trong worktree

- Gợi ý loại từ tiền tố branch (`type_by_prefix`), đối chiếu input, hỏi người xác nhận.
- Loại người chốt lệch tiền tố branch → **không ngoại lệ**: sửa loại, hoặc `aw rename` (đổi branch, thư mục artifact, worktree; người mở phiên mới ở đường dẫn mới).

**Chạy lại khi đã có `intake.md` = gộp thêm input:**
1. Không tạo lại từ mẫu. Giữ nguyên `Type` và `Goal`.
2. `aw input --skip <thư-mục-feature>/intake.md -` — bỏ input đã có (so theo định danh: `ABC-1` và `…/browse/ABC-1` là một). **Thêm** stdout vào cuối `## Input`.
3. Input mới làm loại việc có vẻ khác → **nêu cho người**, không tự sửa `Type`. Người đổi loại → xác nhận lại như lần đầu (`aw rename` nếu lệch tiền tố).
4. Chạy checker, dừng cho người xác nhận **input mới**.

Không xoá input qua lệnh — người sửa tay. `intake.md` đổi → `spec.md` lỗi thời: chạy lại `/aw-spec` (phase sau cảnh báo, review chặn).

## Đầu ra

`intake.md` theo `templates/intake.md`:
- `Type`, `Goal` (một câu), `Base`, `Engine` (đúng như `aw worktree new` in).
- `## Input`: tài liệu `[CONFLUENCE]`/`[JIRA]`/`[FILE]` + định danh; lời người `[HUMAN]` **nguyên văn** ở dòng `>` bên dưới.

`01-spec` trích lời người bằng nhãn `[FILE] intake.md § Input`.

## Cấm

- **Tóm tắt, diễn giải, trích yêu cầu** từ tài liệu nguồn — chỉ trỏ tới nó.
- Tự gán nhãn input, sửa dòng `aw input` in, ghi `[INFERRED]` vào input, ghi lời người không nguyên văn.
- Chạy lại mà viết lại `intake.md` từ đầu, hay tự đổi `Type`.
- Tự chốt loại việc; tự chọn base / điền `--base`; tạo worktree trước khi người chọn.
- Tự sửa dòng `Engine:`.
- Tự chuyển phiên sang worktree mới.
- Chốt phạm vi hoặc giải pháp kỹ thuật.

## Điều kiện ra

**Máy:** `aw check intake` ra `[x] ĐẠT` — `Type` hợp lệ, có `Goal`, ít nhất một input nhãn hợp lệ, không `[INFERRED]`, `[HUMAN]` có nguyên văn, `[JIRA]` có mã khớp `jira_key_regex`, `Base:` có sha là tổ tiên của HEAD, `Engine:` dạng `YYYY.M.N` khớp engine đang chạy. Loại lệch tiền tố branch: cảnh báo (review chặn).

**Người:** chọn base, xác nhận loại việc và input.
