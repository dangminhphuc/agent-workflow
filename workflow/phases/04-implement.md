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

Làm từng task trong `plan.md` theo `tdd.md`, **không vượt phạm vi**. Lỗi hay gặp nhất của agent ở đây không phải code sai mà là mở rộng phạm vi ("tiện tay" sửa thêm, đổi chữ ký, dọn file).

## Đầu vào

- `plan.md` — nguồn duy nhất của việc phải làm; qua `aw check plan`.
- `tdd.md` — làm thế nào (contract, dữ liệu, flow, D-xx). `spec.md` — tra *vì sao* khi cần.
- `../conventions.md` — mẫu file test, cú pháp tag `covers:`, nhánh gốc.
- `aw rules implement` — coding style, skill, pattern. Đọc hết **trước task đầu**.

## Việc phải làm

0. **`aw ready <thư-mục-feature>` trước task đầu.** Test đỏ trên code chưa sửa = môi trường chưa chuẩn bị (`LENH_CHUAN_BI_WT`) hoặc base hỏng → **dừng, báo người**. Không sửa/tắt test có sẵn.
1. **Từng task một, trạng thái do máy giữ** — không tự sửa ô `Status`, không gộp task:
   - `aw task next <thư-mục-feature>` — task kế (đang `[~]` thì làm nó trước);
   - `aw task start <thư-mục-feature> T-NN` — `[ ]` → `[~]` (từ chối nếu đã có task `[~]` khác hoặc phụ thuộc chưa `[x]`);
   - `aw task done <thư-mục-feature> T-NN` — chạy lệnh trong backtick của `Verify`, ghi output vào `ket-qua-task.md`; **xanh** mới lên `[x]`. Verify chỉ làm tay được: `--manual "<đã làm gì, thấy gì>"`.
   - `[x]` không có bằng chứng xanh khớp `Verify` hiện tại → `aw check implement` chặn (kể cả sửa `Verify` sau khi xong).
2. **Test gắn tag** theo `conventions.md` (vd `// covers: YC-001`). YC không test tự động được → "Manual verification" của `plan.md` + lý do.
3. **Kiểm chứng ngay sau mỗi task** (`aw task done`). Đỏ → sửa trong task đó, chạy lại. Đỏ liên tiếp tới `SO_LAN_DO_TOI_DA` (mặc định 3) → máy báo **DỪNG**: ghi vào "Unplanned" đã thử gì, lỗi gì, báo người.
4. **Gặp điều kế hoạch chưa lường → dừng và báo.** Ghi vào "Unplanned" của `plan.md`. Đụng D-xx → mở lại D ở `02-design`, không xử lý ở đây.
5. **Theo quy tắc repo** trong code mình viết. Quy tắc đòi việc ngoài task hay trái `tdd.md` → không làm, ghi "Unplanned".
6. **Giữ diff trong phạm vi.** File ngoài "Expected files" chỉ đụng khi bắt buộc — ghi file (trong backtick) + lý do vào "Unplanned".
7. **`aw check implement`** — tự chạy lệnh test và lệnh quét bảo mật (`LENH_KIEM_TRA_BAO_MAT`, giống CI), tự ghi `ket-qua-kiem-thu.md`, `ket-qua-bao-mat.md` (không tự viết hai file này). Chỉ chạy lại phần quét: `aw check security <thư-mục-feature>`.

## Chạy thành vòng lặp (tuỳ chọn)

Không có gate người nên chạy được không cần canh từng task:

```
lặp:
  T = aw task next <dir>
      HẾT TASK  → aw check implement → ĐẠT: dừng, báo kết quả
                                       KHÔNG ĐẠT: sửa đúng vi phạm, chạy lại
      KẸT, DỪNG → dừng, báo người
  aw task start <dir> T
  làm T (chỉ trong "Expected files" của T)
  aw task done <dir> T
      ĐỎ   → sửa trong T, chạy lại done
      DỪNG → ghi "Unplanned", dừng, báo người
```

Dừng ngay khi: gặp điều chưa lường (đã ghi "Unplanned"); cần đụng file ngoài "Expected files"; cần sửa `tdd.md`/`spec.md` hay mở lại D-xx; `aw check implement` không đạt cùng một vi phạm hai lần liên tiếp.

## Theo loại việc — chặn

| Loại | Thứ tự / luật | Máy kiểm |
|---|---|---|
| `bugfix` | Viết test tái hiện → `aw check repro <thư-mục-feature>` **trước khi sửa code** → mới sửa | `tai-hien.md`: test đỏ khi diff chỉ đụng file test. Thiếu hoặc xanh → chặn |
| `refactor` | Không xoá test cũ; sửa test cũ phải khai ở "Modified existing tests" | Xoá → chặn; sửa chưa khai → cảnh báo |
| `perf` | Như refactor; `aw check perf <thư-mục-feature> --before` **trước khi sửa**, `--after` sau | `do-hieu-nang.md` thiếu một số đo → chặn |
| `chore` | Không đụng code production; khai "Dependency upgrades" | Đụng `production_code` → chặn; đụng `dependency_files` mà không khai, khai major, hoặc `ket-qua-bao-mat.md` không có lệnh nhóm `sca` xanh → chặn |

Quên `repro`/`--before` mà đã sửa code → script **từ chối**: `git stash`, chạy lại, `git stash pop`.

## Kiểm chéo — cảnh báo ở đây, `review` chặn

| Cảnh báo | Xử lý |
|---|---|
| YC chưa có test `covers:` | Thêm test, hoặc "Manual verification" + lý do |
| File đổi nằm ngoài "Expected files"/"Unplanned" | Hoàn tác, hoặc ghi "Unplanned" + lý do |
| Artifact lỗi thời (`based_on` lệch hash) | Chạy lại phase sinh ra nó |
| Loại việc lệch tiền tố branch | Sửa `intake.md`, hoặc `aw rename` |
| refactor/perf: test cũ bị sửa chưa khai | Khai "Modified existing tests", hoặc hoàn tác |
| Điểm mù `review-blocking` còn mở | Nhờ người chạy `clarify` — không tự trả lời |
| Dòng **mới** trong file test có `.only(`, `.skip(`, `xit(`, `@Disabled`… (`skipped_test_regex`) | Bỏ đánh dấu; thật cần thì ghi file vào "Unplanned" + lý do |

## Đầu ra

- Code thay đổi; `plan.md` cập nhật (trạng thái, "Unplanned", "Manual verification").
- Do máy ghi: `ket-qua-task.md` (bằng chứng từng task), `ket-qua-kiem-thu.md`, `ket-qua-bao-mat.md` (output thật, kèm `HEAD`, `Tree`, thời điểm). Sửa code sau đó, kể cả chưa commit → review chặn tới khi chạy lại.

## Cấm

- Làm việc không có trong `plan.md`; mở task mới khi còn task `[~]`.
- Tự sửa ô `Status` hay tự viết `ket-qua-task.md`.
- Sửa `tdd.md`/`spec.md` — thấy sai thì dừng, nêu ra.
- **Tuyên bố xong khi chưa chạy kiểm thử.**
- Sửa/tắt test để test xanh. Test cũ thực sự sai → mục "Unplanned".
- Gắn `covers:` cho test không thật sự kiểm YC đó.
- Bỏ qua lỗi lint/type vì "không liên quan".
- Làm quét bảo mật xanh bằng cách nới công cụ (`nosemgrep`, `.gitleaksignore`, `.trivyignore`, hạ ngưỡng, bỏ dòng khỏi `LENH_KIEM_TRA_BAO_MAT`). Báo nhầm thật → "Unplanned" + bằng chứng, người quyết.

## Điều kiện ra — không có phase test riêng: chưa xanh = chưa xong

**Máy:** `aw check implement` ra `[x] ĐẠT` — đầu vào qua `aw check plan`; lệnh test và mọi lệnh quét bảo mật chạy **XANH**, output thật trong `ket-qua-kiem-thu.md` / `ket-qua-bao-mat.md`; **mọi** task `[x]` với bằng chứng xanh khớp `Verify` hiện tại; không còn dấu xung đột merge. Repo chưa khai lệnh test hay lệnh quét → **KHÔNG ĐẠT**, không phải "bỏ qua".

## Khi agent làm hỏng mà checker không bắt

```
aw journal add <task|context|env|verify|state|model> "<làm sai gì, ở đâu, harness thiếu gì>"
```
