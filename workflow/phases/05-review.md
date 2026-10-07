---
id: review
name: Rà soát độc lập
summary: Bước 6/6 · Subagent ngữ cảnh sạch đối chiếu diff với spec, thiết kế, kế hoạch; ghi review.md
required: true
inputs:
  - intake.md
  - spec.md
  - open-questions.md
  - tdd.md
  - plan.md
  - ket-qua-task.md
  - ket-qua-kiem-thu.md
  - ket-qua-bao-mat.md
  - tai-hien.md (bugfix)
  - do-hieu-nang.md (perf)
  - diff
outputs:
  - review.md
exit_machine:
  - aw check review
exit_human:
  - Người xác nhận kết luận rà soát và quyết định xử lý các finding mức Blocker
  - Người xác nhận base có chủ ý nếu checker cảnh báo base lạ (xếp chồng)
  - Diff đụng code nhạy cảm (sensitive_code) — một người rà bảo mật đọc Lens 4 và diff, tự ghi tên vào "Security reviewer"
needs_clean_context: true
requires_fresh_agent: true
---

# Phase 05 — Rà soát

## Mục tiêu

Kiểm chứng **độc lập**: diff làm đúng `spec.md`, theo đúng `tdd.md` đã duyệt, không vượt `plan.md`. Không phải rà cú pháp (linter làm). Đây là **cổng chặn cuối**: mọi cảnh báo từ phase trước ở đây thành chặn.

## Ngữ cảnh sạch — bắt buộc

Không chạy bởi chính agent vừa hiện thực.

| Agent | Cách làm |
|---|---|
| Có subagent | Chạy trong subagent ngữ cảnh trắng |
| Không có | Mở phiên mới, chỉ nạp file đầu vào + diff |

Adapter không dịch được ràng buộc này thì phải ghi rõ người phải tự mở phiên mới.

## Bốn lăng kính — tách bạch, không trộn

### 1. Đúng đặc tả (`## Lens 1 — Spec conformance`)
Đi **từng** `YC-NNN`: code nào thoả nó, kết luận `pass` / `fail` / `partial`. Không bỏ mã nào. YC `[OPEN-QUESTION]` với giả định chưa xác nhận → `pending`, không `pass`.

### 2. Thiết kế và phạm vi (`## Lens 2 — Design and scope`)
- Code theo đúng D-xx đã duyệt, contract, mô hình dữ liệu của `tdd.md`?
- Thay đổi không thuộc task nào? Task `[x]` mà diff không có dấu vết?
- Mục "Unplanned" bị xử lý lặng lẽ thay vì nêu ra?
- Task kiểm chứng thủ công (`ket-qua-task.md`): bằng chứng có thật sự chứng minh task xong?

**Quy tắc repo** (`aw rules review` — gộp mọi phase): mỗi file một dòng trong `## Repo rules`: `pass` / `violation` (+ `file:dòng`, thêm finding Lens 3) / `not applicable` (+ lý do). Code theo D-xx đã duyệt mà trái quy tắc → `not applicable`, ghi D nào.

### 3. Chất lượng (`## Lens 3 — Quality`)
Lỗi đúng/sai, chỗ dùng lại được thứ đã có, phức tạp quá mức. Mỗi finding `### [Blocker|Should fix|Nit] <tiêu đề>`:
- `Blocker`, `Should fix`: `- Location: \`file:dòng\`` (dòng thật) và `- Category: <kebab-case>` (vd `missing-null-check`). Chạy `aw journal` để **dùng lại tên đã có**.
- `Blocker`: thêm `- Failure scenario:` — đầu vào cụ thể → kết quả sai.
- Không có finding → đúng một dòng `- None`.

### 4. Bảo mật (`## Lens 4 — Security`)
Máy quét bắt mẫu đã biết; lăng kính này đọc diff tìm **ý đồ**: endpoint thiếu kiểm quyền, log lộ dữ liệu, đường dẫn ghép từ input… Bảng **đủ bảy dòng**, không thêm bớt, không đổi tên:

| Hạng mục | Câu hỏi |
|---|---|
| `Input validation / injection` | Input ngoài (request, file, message, env) vào SQL/shell/template/query/regex có tham số hoá / escape / kiểm dạng? |
| `Authn / authz` | Endpoint/hành động mới kiểm đăng nhập và quyền **đúng YC Phân quyền**? Lấy id từ request mà không kiểm chủ sở hữu (IDOR)? |
| `Sensitive data / PII in logs` | Dữ liệu cá nhân, tài chính, token bị log, trả thừa, ghi file tạm, gửi ra ngoài? |
| `Secrets / config` | Secret cứng trong code/test/config? Mặc định an toàn (debug tắt, CORS hẹp, TLS)? |
| `Crypto` | Thuật toán, độ dài khoá, nguồn ngẫu nhiên đúng chuẩn? Tự chế crypto, so token không hằng thời gian? |
| `SSRF / path traversal / deserialization` | URL, đường dẫn, dữ liệu deserialize từ input không tin cậy mà không giới hạn? |
| `New dependencies` | Cần thiết, được bảo trì, có trong kết quả SCA, license hợp lệ? |

Verdict: `pass` / `finding` (+ `file:dòng`, **và** finding ở Lens 3) / `not applicable` (+ lý do, sau khi đã đọc diff).

**Code nhạy cảm** (`sensitive_code`): diff đụng vào → một **người** rà bảo mật đọc Lens 4 và diff, tự ghi `- Security reviewer: <tên>` đầu `review.md`. Agent để trống, nêu danh sách file nhạy cảm (`aw check review` in ra), dừng chờ người.

## Mức finding

| Mức | Nghĩa |
|---|---|
| `Blocker` | Sai đặc tả, lệch quyết định đã duyệt, lỗi gây hỏng, lỗ hổng khai thác được, mất/lộ dữ liệu, breaking change chưa khai (API/payload/schema/event đổi mà `tdd.md`/MR không nêu). Không được merge |
| `Should fix` | Đúng nhưng có vấn đề chất lượng thật |
| `Nit` | Người viết tự quyết |

## Theo loại việc — phần người phán

| Loại | Làm gì |
|---|---|
| `bugfix` | Đọc `tai-hien.md`: test đỏ **đúng vì bug** (không phải lỗi biên dịch/thiếu hàm). Ghi `Repro test fails because: <trích output>` (thiếu → chặn) |
| `refactor`/`perf` | Mỗi file ở "Modified existing tests": diff chỉ đổi import/cấu trúc, **không đổi assertion** |
| `perf` | Đọc `do-hieu-nang.md`, kết luận YC hiệu năng theo số đo, tính cả dao động |
| `chore` | Mức `patch \| minor` ở "Dependency upgrades" là đúng (major = refactor riêng) |

## Đầu ra

`review.md` theo `templates/review.md`. `- Reviewed tree:` = dòng `Tree` của `ket-qua-kiem-thu.md`; code đổi sau khi rà → máy chặn, rà lại.

## Cấm

- Rà kiểu "nhìn qua thấy ổn" — không đi hết từng `YC-NNN` = chưa chạy.
- **Tự sửa code.** Sửa = quay lại `04-implement` với task mới.
- Nâng góp ý phong cách lên `Blocker`.
- Kết luận `pass` cho YC đứng trên giả định chưa xác nhận.
- Tự điền `Security reviewer` — kể cả tên người đang chat.
- Ghi `not applicable` cả bảng Lens 4 mà không đọc diff; hạ lỗ hổng khai thác được xuống `Should fix` vì "khó xảy ra".

## Điều kiện ra

**Máy:** `aw check review` ra `[x] ĐẠT`:
- mọi `YC-NNN` có verdict hợp lệ, không `[OPEN-QUESTION]` nào `pass`; đầu vào qua `aw check plan`;
- `ket-qua-kiem-thu.md` và `ket-qua-bao-mat.md` ghi `Kết quả: XANH` và `Tree` khớp code hiện tại (đổi code → chạy lại `aw check implement` hoặc `aw check security`; commit lại đúng code đó không tính là đổi); chore đụng dependency có lệnh `sca` xanh;
- **không còn cảnh báo nào** của implement; mọi task `[x]` có bằng chứng khớp `Verify`; không dấu xung đột merge; luật theo loại việc;
- `## Repo rules` có kết luận hợp lệ cho **từng** file quy tắc (file khai có thật, đã commit);
- Lens 4 đủ bảy dòng hợp lệ; có `finding` thì Lens 3 có ít nhất một finding;
- Lens 3 có finding **hoặc** đúng `- None` (không cả hai), không còn chữ giữ chỗ; `Location`, `Category`, `Failure scenario` đúng dạng;
- `## Conclusion` có `- Blocker findings: <n>` bằng số mục `[Blocker]`; `- Reviewed tree:` khớp code;
- diff đụng `sensitive_code` → có `- Security reviewer: <tên người>` (không trống, không giữ chỗ, không tên agent).

Diff so với **base trong `intake.md`**. Base lạ (vd xếp chồng lên branch khác) → chỉ cảnh báo, nêu cho người. Đạt thì finding `[Blocker]`/`[Should fix]` vào `aw journal` theo `Category`; loại lặp ở việc khác → checker in `[GỢI Ý]` nâng thành luật máy.

**Người:** xác nhận kết luận, quyết định xử lý `Blocker`; quyết `[GỢI Ý]` nâng luật; xác nhận base lạ là có chủ ý.
