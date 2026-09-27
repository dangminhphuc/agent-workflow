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

## Việc phải làm

1. **Gợi ý loại việc** từ tiền tố branch (`loai_theo_tien_to` trong
   `conventions.md`), đối chiếu với input, rồi hỏi người xác nhận.

   Loại người chốt lệch tiền tố branch thì **không có ngoại lệ**: sửa loại, hoặc
   đổi tên branch bằng `tools/doi-ten-feature.sh` (dời luôn thư mục artifact).

2. **Ghi input.** Mỗi input một dòng trong mục `## Input`:
   - tài liệu: `[CONFLUENCE]` / `[JIRA]` / `[FILE]` + định danh (URL, mã issue, đường dẫn);
   - không có tài liệu: hỏi người dùng rồi ghi `[NGƯỜI-DÙNG]` và **chép nguyên văn**
     câu trả lời ở dòng `>` bên dưới.

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
- Ghi `[SUY-RA]` vào input, hay ghi lời người dùng mà không phải nguyên văn.
  Suy đoán của agent vào input thì mọi phase sau truy về nó như thể có nguồn.
- Tự chốt loại việc thay người.
- Chốt phạm vi hoặc giải pháp kỹ thuật.

## Điều kiện ra

**Máy:**
- `sh tools/kiem-tra-tiep-nhan.sh` trả về 0 — loại việc hợp lệ, có mục tiêu, có ít
  nhất một input với nhãn hợp lệ, không `[SUY-RA]`, `[NGƯỜI-DÙNG]` có nguyên văn.
  Loại lệch tiền tố branch thì cảnh báo; `review` chặn.

**Người:**
- Xác nhận loại việc và input.
