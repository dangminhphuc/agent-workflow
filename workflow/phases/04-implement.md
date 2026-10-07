---
id: implement
name: Hiện thực
summary: Bước 5/6 · Làm từng task trong plan.md; task chỉ xong khi test xanh
required: true
inputs:
  - intake.md
  - plan.md
  - tdd.md
  - spec.md
outputs:
  - diff
  - plan.md (cập nhật trạng thái task)
  - ket-qua-kiem-thu.md
exit_machine:
  - aw check implement
exit_human: []
needs_clean_context: false
---

# Phase 04 — Hiện thực

## Mục tiêu

Thực thi từng task trong `plan.md` theo `tdd.md`, không vượt ra ngoài phạm vi
của chúng.

Đây là phase agent cần **ít hướng dẫn nhất về cách viết code** và **nhiều ràng
buộc nhất về phạm vi**. Agent viết code khá tốt; thứ nó làm hỏng là tự ý mở
rộng phạm vi — sửa thêm chỗ "tiện tay thấy chưa đẹp", đổi thêm vài chữ ký hàm,
dọn thêm vài file. Kết quả là một diff không ai review nổi.

## Đầu vào

- `plan.md` — nguồn duy nhất của việc phải làm; phải qua `aw check plan`
- `tdd.md` — *làm thế nào*: contract, mô hình dữ liệu, flow, quyết định D-xx
- `spec.md` — tra khi cần hiểu *vì sao* một task tồn tại
- `../conventions.md` — mẫu file test, cú pháp tag `covers:`, nhánh gốc
- Quy tắc riêng của repo — `aw rules implement`: coding style, skill, pattern của
  repo. Đọc hết **trước task đầu tiên** (xem `rules/nguyen-tac-chung.md` § 7)

## Việc phải làm

1. **Làm từng task một.** Không gộp nhiều task vào một lượt, kể cả khi chúng
   trông giống nhau. Gộp lại thì mất điểm dừng để kiểm tra giữa chừng.
   Đánh `[~]` khi bắt đầu, `[x]` khi xong kèm danh sách file đã đụng tới.

2. **Viết test gắn tag** theo cú pháp trong `conventions.md`, ví dụ
   `// covers: YC-001`. YC không test tự động được thì ghi vào mục
   "Manual verification" của `plan.md` kèm lý do.

3. **Chạy kiểm chứng đã khai trong task** ngay sau khi làm xong task đó — không
   dồn tới cuối.

4. **Dừng và báo khi gặp điều kế hoạch chưa lường.** Không tự quyết rồi đi
   tiếp. Ghi vào `plan.md` mục "Unplanned" và nêu ra. Nếu nó đụng một quyết định
   D-xx thì đó là việc mở lại D ở `02-design`, không phải việc của phase này.

   Task gặp bất ngờ là tín hiệu thiết kế hoặc kế hoạch thiếu sót, và thông tin
   đó phải chảy ngược về chứ không bị agent âm thầm xử lý.

5. **Theo quy tắc riêng của repo** trong phần code mình viết. Quy tắc nào bảo làm
   việc ngoài task (dọn file cũ, đổi tên hàng loạt…) hay mâu thuẫn với `tdd.md`
   thì không làm — ghi vào "Unplanned". Quy tắc máy kiểm được (lint, type,
   kiến trúc) nên nằm trong `LENH_KIEM_THU` để máy chặn, không chỉ nằm trên giấy.

6. **Giữ diff trong phạm vi.** File ngoài "Expected files" chỉ được đụng khi task
   không thể hoàn thành nếu không đụng — và phải ghi file đó (trong backtick)
   kèm lý do vào mục "Unplanned".

7. **Chạy `aw check implement`.** Script tự chạy lệnh test và tự ghi
   `ket-qua-kiem-thu.md` — không tự viết file đó.

## Theo loại việc — chặn

Loại việc lấy từ `intake.md`. Các luật dưới là **chặn** ngay ở phase này:

| Loại | Thứ tự bắt buộc / luật | Máy ghi / kiểm |
|---|---|---|
| `bugfix` | Viết test tái hiện → chạy `aw check repro <thư-mục-feature>` **trước khi sửa code** → mới sửa | `tai-hien.md`: test đỏ khi diff mới chỉ đụng file test. Thiếu, hoặc ghi xanh → chặn |
| `refactor` | Không xoá test cũ. Sửa test cũ thì khai ở "Modified existing tests" | Xoá test cũ → chặn; sửa chưa khai → cảnh báo |
| `perf` | Như refactor; `aw check perf <thư-mục-feature> --before` **trước khi sửa**, `--after` sau khi sửa | `do-hieu-nang.md` thiếu một trong hai số đo → chặn |
| `chore` | Không đụng code production. Dependency upgrades thì khai ở "Dependency upgrades" | Đụng `mau_code_production` → chặn; đụng `mau_file_dependency` mà không khai, hoặc khai major → chặn |

Quên chạy `tai-hien` / `--before` mà đã sửa code: script **từ chối**. Hoàn tác phần
sửa (`git stash`), chạy lại, rồi `git stash pop`. Đây là chủ ý: bằng chứng "trước
khi sửa" chỉ có giá trị khi nó thật sự được lấy trước khi sửa.

## Kiểm chéo — cảnh báo, `review` chặn

`aw check implement` in **cảnh báo** (không chặn phase này) cho:

| Kiểm chéo | Xử lý |
|---|---|
| YC chưa có test gắn tag `covers:` | Thêm test, hoặc ghi "Manual verification" + lý do |
| File thay đổi so với nhánh gốc nằm ngoài "Expected files"/"Unplanned" | Hoàn tác, hoặc ghi vào "Unplanned" + lý do |
| Artifact lỗi thời (`based_on` lệch hash) | Chạy lại phase sinh ra artifact đó |
| Loại việc lệch tiền tố branch | Sửa loại trong `intake.md`, hoặc `aw rename` |
| refactor/perf: test cũ bị sửa mà chưa khai | Khai ở "Modified existing tests" + lý do, hoặc hoàn tác |
| Điểm mù `Blocking: review-blocking` còn mở | Nhờ người chạy lệnh `clarify` để chốt — agent không tự trả lời |

Cảnh báo không chặn ở đây để flow không tắc vì checker hay báo nhầm. Nhưng
`05-review` là cổng chặn cuối: cảnh báo nào còn thì review **không đạt**. Xử lý
luôn ở đây là rẻ nhất.

## Đầu ra

- Thay đổi code trong repo đích
- `plan.md` đã cập nhật trạng thái (và "Unplanned", "Manual verification" nếu có)
- `ket-qua-kiem-thu.md` — do script ghi, output thật của lệnh kiểm thử

## Cấm

- Làm việc không có trong `plan.md`.
- Sửa `tdd.md` hay `spec.md`. Thấy sai thì dừng và nêu ra.
- **Tuyên bố xong khi chưa chạy kiểm thử.** Đây là thất bại phổ biến nhất của
  agent trong toàn quy trình.
- Sửa hoặc vô hiệu hoá test để test xanh. Test đỏ là thông tin, không phải
  chướng ngại. Nếu test cũ thực sự sai, đó là một mục "Unplanned" cần nêu ra,
  không phải việc sửa lặng lẽ.
- Gắn tag `covers:` cho test không thực sự kiểm YC đó để tắt cảnh báo.
- Bỏ qua lỗi lint/type với lý do "không liên quan tới task".

## Điều kiện ra — `test` nằm ở đây

Quy trình này **không có phase test riêng**. Một phase test riêng không có đầu
vào riêng — nó ăn đúng cái diff mà `05-review` ăn — và đặt nó ở phía sau sẽ biến
"code xong" thành một trạng thái hợp lệ dù chưa ai chạy gì.

Đặt ở đây thì ràng buộc mạnh hơn: **chưa xanh nghĩa là chưa xong.**

**Máy:**
- `aw check implement` ra `[x] ĐẠT`: đầu vào qua `aw check plan`;
  lệnh kiểm thử của repo đích chạy **XANH** và output thật nằm trong
  `ket-qua-kiem-thu.md`; không còn task `[~]`.

Nếu repo đích chưa có lệnh kiểm thử, phải khai báo lúc cài đặt. Không khai thì
điều kiện ra này coi như **fail**, không phải "bỏ qua" — im lặng bỏ qua sẽ làm
cả ràng buộc trên mất tác dụng ở đúng những repo cần nó nhất.
