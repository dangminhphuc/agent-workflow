---
id: intake
name: Tiếp nhận
summary: Điểm xuất phát bắt buộc — ghi loại việc và input làm gốc cho mọi phase sau
required: true
inputs:
  - confluence
  - jira
  - file
outputs:
  - intake.md
exit_machine:
  - sh tools/kiem-tra-tiep-nhan.sh
exit_human:
  - Người xác nhận LOẠI VIỆC (chọn sai loại là sai luật cả chuỗi phía sau)
  - Người xác nhận danh sách input, và lời mình được chép đúng nguyên văn
needs_clean_context: true
arguments: input
---

# Phase 00 — Tiếp nhận

## Mục tiêu

Mọi việc bắt đầu ở đây. Phase này trả lời ba câu, và **chỉ ba câu**:

1. **Làm loại việc gì** — `feature`, `bugfix`, `refactor`, `perf` hay `chore`.
2. **Xuất phát từ input nào** — tài liệu có định danh, hoặc lời người dùng.
3. **Mục tiêu một câu.**

Loại việc không phải nhãn cho đẹp: nó **đổi luật** của các phase sau (xem bảng
dưới). Input là gốc mà mọi yêu cầu `YC-xxx` về sau phải truy về.

## Loại việc

Xếp loại theo **thay đổi gì về hành vi**, không theo "xây cái gì":

```
Có sửa code chạy trên production không?
├─ Không → chore
└─ Có → Hành vi quan sát từ bên ngoài có đổi không?
        ├─ Không → mục tiêu là nhanh hơn / ít tài nguyên hơn? → có: perf / không: refactor
        └─ Có → Hành vi hiện tại có đang SAI so với tài liệu / ý định không?
                ├─ Có  → bugfix
                └─ Không → feature
```

| Loại | Luật khác biệt |
|---|---|
| `feature` | Quy trình chuẩn |
| `bugfix` | Spec có mục "Tái hiện lỗi"; test tái hiện phải **đỏ trên code chưa sửa** (`kiem-tra-tai-hien.sh`) |
| `refactor` | YC chỉ là `giữ nguyên` / `cấu trúc`, YC giữ nguyên phải có test bảo vệ sẵn trên nhánh gốc; không được xoá test cũ, sửa test cũ phải khai |
| `perf` | Như refactor, cộng YC `hiệu năng` có số liệu và số đo trước/sau do máy ghi (`kiem-tra-hieu-nang.sh`) |
| `chore` | Không có phase design; không được đụng code production; nâng dependency phải khai (major thì là refactor) |

Không phải loại riêng: `utils` (thêm hàm dùng chung = feature, gom code trùng =
refactor), `hotfix` (= bugfix gấp), `security` (= bugfix/feature + rủi ro cao).
`spike` nằm ngoài quy trình — output của nó là kết luận, không phải code để merge.
Việc vừa là loại này vừa là loại kia (vd refactor kèm sửa bug) thì **tách branch**:
luật của hai loại xung đột nhau.

## Tham số của lệnh là input

`/intake JIRA-123 https://confluence/…` — tham số là **danh sách input**, không
phải tên feature. Tên feature luôn lấy từ branch (xem mục dưới).

**Nhãn do máy gán.** Luôn chạy `tools/phan-loai-input.sh`, truyền nguyên văn tham
số qua stdin (`-`), rồi chép **đúng stdout** vào `## Input`. Không tự gán nhãn,
không sửa dòng nó in ra. Luật (mẫu khai trong `conventions.md`):

| Token | Nhãn |
|---|---|
| Khớp `mau_jira`, hoặc URL `…/browse/<mã>` | `[JIRA]` |
| URL khớp `mien_confluence` (chưa khai: mọi URL còn lại, có cảnh báo) | `[CONFLUENCE]` |
| File có thật trong repo | `[FILE]` |
| Trông như đường dẫn nhưng không có file | lỗi — mã 1 |
| Còn lại | không nhận ra |

**Lời người dùng.** Chỉ cần **một** token không nhận ra, **cả chuỗi** là lời
người dùng: một mục `[NGƯỜI-DÙNG]` chép nguyên văn (mã 4). Tách từng từ sẽ biến
một câu thành vài "input" rác và làm mất câu gốc. Nguồn nhận ra được nằm trong
câu (vd `ABC-123` trong "sửa phí hoàn tiền ABC-123") chỉ là **đề xuất tách thêm**:
hỏi người, người đồng ý mới ghi thành dòng riêng.

| Mã thoát | Làm gì |
|---|---|
| 0 | Chép stdout (rỗng = không có input mới) |
| 4 | Chép mục `[NGƯỜI-DÙNG]`; hỏi người về "đề xuất tách thêm" nếu có |
| 3 | Không có tham số: hỏi người dùng, chạy lại script với **nguyên văn** câu trả lời |
| 1 | Đường dẫn không tồn tại: hỏi lại, không tự đoán |

## Chạy lại `/intake`

Đã có `intake.md` thì chạy lại là **gộp thêm input**, không viết lại:

1. Không tạo lại từ mẫu. **Giữ nguyên** `Loại việc` và `Mục tiêu`.
2. Chạy `phan-loai-input.sh --tru <thư-mục-feature>/intake.md -` — nó bỏ các
   input đã có (so theo định danh: `ABC-1` và `…/browse/ABC-1` là một nguồn).
   **Thêm** stdout vào cuối `## Input`.
3. Input mới làm loại việc có vẻ khác đi (vd thêm incident note vào việc
   `feature`): **nêu ra cho người**, không tự sửa `Loại việc`. Người đổi loại
   thì xác nhận lại như lần đầu (và đổi tên branch nếu lệch tiền tố).
4. Chạy checker, dừng cho người xác nhận **các input mới**.

Không có đường xoá input qua lệnh — muốn bỏ thì người sửa tay `intake.md`. Chỉ
gộp thêm để agent không lặng lẽ làm mất một nguồn.

`intake.md` đổi thì `spec.md` (ghi `based_on: intake.md`) thành **lỗi thời**:
chạy lại `/spec` để đọc input mới. Các phase sau cảnh báo, `review` chặn nếu còn.

## Branch chưa đúng quy ước

Khi `xac-dinh-feature.sh` trả mã 3 (vd đang ở `main`), **không** hỏi tên feature
tự do. Làm theo thứ tự:

1. Đọc input, **chốt loại việc với người** (cây phân loại ở trên).
2. Chọn một mô tả ngắn: chữ thường ASCII, số, dấu `-` (vd `phi-hoan-tien`).
3. Chạy `tools/tao-branch.sh <loại-việc> <mô-tả>` — nó in **tên đề xuất** theo
   `loai_theo_tien_to` (vd `fix_phi-hoan-tien`). Không tự ghép tiền tố.
4. Hỏi người xác nhận tên đó. Người muốn tên khác thì đổi `<mô-tả>` và chạy lại.
5. Người đồng ý rồi mới chạy lại với `--tao` để tạo và chuyển sang branch, rồi
   chạy lại Bước 0.

Tạo branch trước khi ghi `intake.md` để thư mục artifact mang đúng tên branch
ngay từ đầu, và loại việc khớp tiền tố branch.

## Việc phải làm

1. **Gợi ý loại việc** từ tiền tố branch (`loai_theo_tien_to` trong
   `conventions.md`), đối chiếu với input, rồi hỏi người xác nhận.

   Loại người chốt lệch tiền tố branch thì **không có ngoại lệ**: sửa loại, hoặc
   đổi tên branch bằng `tools/doi-ten-feature.sh` (dời luôn thư mục artifact).

2. **Ghi input** bằng `phan-loai-input.sh` (mục "Tham số của lệnh là input"):
   - tài liệu: `[CONFLUENCE]` / `[JIRA]` / `[FILE]` + định danh (URL, mã issue, đường dẫn);
   - lời người dùng: `[NGƯỜI-DÙNG]`, **chép nguyên văn** ở dòng `>` bên dưới.

3. **Ghi mục tiêu** một câu.

4. Chạy `kiem-tra-tiep-nhan.sh` rồi dừng lại cho người xác nhận.

## Đầu ra

- `intake.md` — theo `templates/intake.md`.

`01-spec` đọc các tài liệu được liệt kê, và trích lời người dùng bằng nhãn
`[FILE] intake.md § Input`.

## Cấm

- **Tóm tắt, diễn giải hay trích yêu cầu từ tài liệu nguồn.** Chỉ trỏ tới nó.
  Viết lại BRD ở đây là tạo một lớp diễn giải chen giữa tài liệu thật và spec —
  và sai lệch của lớp đó sẽ được spec gắn nhãn như có nguồn đàng hoàng.
- Tự gán nhãn input, hay sửa dòng `phan-loai-input.sh` in ra.
- Ghi `[SUY-RA]` vào input, hay ghi lời người dùng mà không phải nguyên văn.
- Chạy lại mà viết lại `intake.md` từ đầu, hay tự đổi `Loại việc`.
  Suy đoán của agent vào input thì mọi phase sau truy về nó như thể có nguồn.
- Tự chốt loại việc thay người.
- Chốt phạm vi hoặc giải pháp kỹ thuật.

## Điều kiện ra

**Máy:**
- `sh tools/kiem-tra-tiep-nhan.sh` trả về 0 — loại việc hợp lệ, có mục tiêu, có ít
  nhất một input với nhãn hợp lệ, không `[SUY-RA]`, `[NGƯỜI-DÙNG]` có nguyên văn,
  `[JIRA]` có mã khớp `mau_jira`.
  Loại lệch tiền tố branch thì cảnh báo; `review` chặn.

**Người:**
- Xác nhận loại việc và input.
