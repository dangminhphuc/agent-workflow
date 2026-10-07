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
  - ket-qua-task.md
  - ket-qua-kiem-thu.md
  - ket-qua-bao-mat.md
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

0. **Chạy `aw ready <thư-mục-feature>` trước task đầu tiên.** Nó chạy lệnh test
   trên code chưa sửa. Đỏ ngay từ đầu nghĩa là môi trường chưa chuẩn bị
   (`LENH_CHUAN_BI_WT`) hoặc base đang hỏng: **dừng, báo người** — đừng sửa hay
   tắt test có sẵn. Bắt đầu trên base đỏ thì không còn phân biệt được lỗi mình
   gây ra với lỗi có sẵn.

1. **Làm từng task một — trạng thái do máy giữ.** Không gộp nhiều task vào một
   lượt, kể cả khi chúng trông giống nhau. Không tự sửa ô `Status`:
   - `aw task next <thư-mục-feature>` — task phải làm tiếp (đang `[~]` thì làm
     cho xong nó trước; không thì task `[ ]` đầu tiên có phụ thuộc đã xong);
   - `aw task start <thư-mục-feature> T-NN` — `[ ]` → `[~]`. Máy từ chối khi đã
     có task khác `[~]` (một việc một lúc) hoặc phụ thuộc chưa `[x]`;
   - `aw task done <thư-mục-feature> T-NN` — máy chạy lệnh trong backtick của
     dòng `Verify`, ghi output thật vào `ket-qua-task.md`; **xanh** mới lên `[x]`.
     Verify chỉ kiểm được bằng tay (không có lệnh): `--manual "<đã làm gì, thấy gì>"`.

   `[x]` tự đánh không có bằng chứng xanh khớp lệnh `Verify` hiện tại thì
   `aw check implement` chặn. Sửa lệnh `Verify` sau khi task xong cũng vậy.

2. **Viết test gắn tag** theo cú pháp trong `conventions.md`, ví dụ
   `// covers: YC-001`. YC không test tự động được thì ghi vào mục
   "Manual verification" của `plan.md` kèm lý do.

3. **Kiểm chứng ngay sau mỗi task** bằng `aw task done` — không dồn tới cuối.
   Đỏ thì sửa trong task đó rồi chạy lại. Đỏ liên tiếp tới `SO_LAN_DO_TOI_DA`
   (config.sh, mặc định 3) thì máy báo **DỪNG**: ghi vào "Unplanned" đã thử gì,
   lỗi gì, rồi báo người. Thử tiếp sau đó là đoán mò.

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

7. **Chạy `aw check implement`.** Script tự chạy lệnh test và các lệnh quét bảo
   mật (`LENH_KIEM_TRA_BAO_MAT` — cùng lệnh, cùng ngưỡng với CI), tự ghi
   `ket-qua-kiem-thu.md` và `ket-qua-bao-mat.md` — không tự viết hai file đó. Chỉ
   cần chạy lại phần quét: `aw check security <thư-mục-feature>`.

## Chạy thành vòng lặp (tuỳ chọn)

Phase này không có gate người — mọi quyết định đã chốt ở `spec`, `design`, `plan`.
Vì vậy nó chạy được thành vòng lặp không cần người canh từng task. Vòng lặp nằm
ở **lệnh và file**, không ở tính năng riêng của agent nào:

```
lặp:
  T = aw task next <dir>
      HẾT TASK  → aw check implement → ĐẠT: dừng, báo kết quả
                                       KHÔNG ĐẠT: sửa đúng vi phạm, chạy lại (tính vào lượt)
      KẸT, DỪNG → dừng, báo người
  aw task start <dir> T
  làm T (chỉ trong "Expected files" của T)
  aw task done <dir> T
      ĐỎ   → sửa trong T, chạy lại done
      DỪNG → ghi "Unplanned", dừng, báo người
```

Điều kiện dừng ngoài các nhãn trên — gặp một trong số này thì dừng ngay, không
lượt nào được bỏ qua:

- Gặp điều kế hoạch chưa lường (bước 4) — đã ghi "Unplanned".
- Cần đụng file ngoài "Expected files" của task.
- Cần sửa `tdd.md`, `spec.md`, hoặc mở lại một D-xx.
- `aw check implement` không đạt cùng một vi phạm hai lần liên tiếp.

Người giao vòng lặp vẫn là người đọc kết quả: vòng lặp làm việc sinh code gần
như miễn phí, phần còn khan hiếm là phán đoán — `review` vẫn chạy bằng ngữ cảnh
sạch như mọi khi.

## Theo loại việc — chặn

Loại việc lấy từ `intake.md`. Các luật dưới là **chặn** ngay ở phase này:

| Loại | Thứ tự bắt buộc / luật | Máy ghi / kiểm |
|---|---|---|
| `bugfix` | Viết test tái hiện → chạy `aw check repro <thư-mục-feature>` **trước khi sửa code** → mới sửa | `tai-hien.md`: test đỏ khi diff mới chỉ đụng file test. Thiếu, hoặc ghi xanh → chặn |
| `refactor` | Không xoá test cũ. Sửa test cũ thì khai ở "Modified existing tests" | Xoá test cũ → chặn; sửa chưa khai → cảnh báo |
| `perf` | Như refactor; `aw check perf <thư-mục-feature> --before` **trước khi sửa**, `--after` sau khi sửa | `do-hieu-nang.md` thiếu một trong hai số đo → chặn |
| `chore` | Không đụng code production. Dependency upgrades thì khai ở "Dependency upgrades" | Đụng `mau_code_production` → chặn; đụng `mau_file_dependency` mà không khai, hoặc khai major → chặn; đụng `mau_file_dependency` mà `ket-qua-bao-mat.md` không có lệnh nhóm `sca` chạy xanh → chặn (mức patch/minor không nói gì về CVE/license) |

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
| Dòng **thêm mới** trong file test có `.only(`, `.skip(`, `xit(`, `@Disabled`… (`mau_bo_qua_test`) | Bỏ đánh dấu; thật sự cần tắt thì ghi file vào "Unplanned" kèm lý do |

Cảnh báo không chặn ở đây để flow không tắc vì checker hay báo nhầm. Nhưng
`05-review` là cổng chặn cuối: cảnh báo nào còn thì review **không đạt**. Xử lý
luôn ở đây là rẻ nhất.

## Đầu ra

- Thay đổi code trong repo đích
- `plan.md` đã cập nhật trạng thái (và "Unplanned", "Manual verification" nếu có)
- `ket-qua-task.md` — do `aw task done` ghi, bằng chứng kiểm chứng của từng task
- `ket-qua-kiem-thu.md` — do script ghi, output thật của lệnh kiểm thử
- `ket-qua-bao-mat.md` — do script ghi, output thật của từng lệnh quét bảo mật

Cả hai ghi `HEAD`, `Tree` (dấu vân tay nội dung code lúc chạy) và thời điểm. Sửa
code sau đó — kể cả chưa commit — thì `review` chặn tới khi chạy lại.

## Cấm

- Làm việc không có trong `plan.md`.
- Tự sửa ô `Status` trong `plan.md` thay vì `aw task start` / `aw task done`,
  hay tự viết `ket-qua-task.md`.
- Mở task mới khi task trước còn `[~]`.
- Sửa `tdd.md` hay `spec.md`. Thấy sai thì dừng và nêu ra.
- **Tuyên bố xong khi chưa chạy kiểm thử.** Đây là thất bại phổ biến nhất của
  agent trong toàn quy trình.
- Sửa hoặc vô hiệu hoá test để test xanh. Test đỏ là thông tin, không phải
  chướng ngại. Nếu test cũ thực sự sai, đó là một mục "Unplanned" cần nêu ra,
  không phải việc sửa lặng lẽ.
- Gắn tag `covers:` cho test không thực sự kiểm YC đó để tắt cảnh báo.
- Bỏ qua lỗi lint/type với lý do "không liên quan tới task".
- Làm cho quét bảo mật xanh bằng cách nới công cụ thay vì sửa code: thêm
  `nosemgrep`, `.gitleaksignore`, `.trivyignore`, hạ ngưỡng, bỏ dòng khỏi
  `LENH_KIEM_TRA_BAO_MAT`. Báo nhầm thật thì ghi vào "Unplanned" kèm bằng chứng —
  người quyết, và diff đó sẽ qua review như mọi thay đổi khác.

## Điều kiện ra — `test` nằm ở đây

Quy trình này **không có phase test riêng**. Một phase test riêng không có đầu
vào riêng — nó ăn đúng cái diff mà `05-review` ăn — và đặt nó ở phía sau sẽ biến
"code xong" thành một trạng thái hợp lệ dù chưa ai chạy gì.

Đặt ở đây thì ràng buộc mạnh hơn: **chưa xanh nghĩa là chưa xong.**

**Máy:**
- `aw check implement` ra `[x] ĐẠT`: đầu vào qua `aw check plan`;
  lệnh kiểm thử của repo đích chạy **XANH** và output thật nằm trong
  `ket-qua-kiem-thu.md`; mọi lệnh trong `LENH_KIEM_TRA_BAO_MAT` chạy **XANH** và
  output thật nằm trong `ket-qua-bao-mat.md`; **mọi** task `[x]` (không còn
  `[~]` hay `[ ]`), mỗi task có bằng chứng xanh trong `ket-qua-task.md` khớp lệnh
  `Verify` hiện tại; không file nào còn dấu xung đột merge.

Nếu repo đích chưa có lệnh kiểm thử hay lệnh quét bảo mật, phải khai báo lúc cài đặt. Không khai thì
điều kiện ra này coi như **fail**, không phải "bỏ qua" — im lặng bỏ qua sẽ làm
cả ràng buộc trên mất tác dụng ở đúng những repo cần nó nhất.

## Khi agent làm hỏng

Agent làm sai mà checker không bắt (hoặc bắt quá muộn) là dấu hiệu harness
thiếu một chỗ. Người hoặc agent ghi lại, gắn lớp gây ra:

```
aw journal add <task|context|env|verify|state|model> "<làm sai gì, ở đâu, harness thiếu gì>"
```

`aw journal` tổng hợp lại để biết nên đầu tư vào đâu — xem `docs/kien-truc.md`.
