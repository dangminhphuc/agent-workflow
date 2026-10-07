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
  - Diff đụng code nhạy cảm (mau_code_nhay_cam) — một người rà bảo mật đọc Lens 4 và diff, tự ghi tên vào "Security reviewer"
needs_clean_context: true
requires_fresh_agent: true
---

# Phase 05 — Rà soát

## Mục tiêu

Kiểm chứng **độc lập** rằng diff làm đúng `spec.md`, theo đúng `tdd.md` đã
duyệt, và không vượt `plan.md`.

Đây không phải bước rà lỗi cú pháp — linter làm việc đó rẻ hơn. Việc của phase
này là trả lời: *thứ vừa viết ra có đúng là thứ được yêu cầu không?*

Đây cũng là **cổng chặn cuối**. Mọi cảnh báo dồn về từ phase trước — artifact
lỗi thời, YC chưa có test, diff ngoài phạm vi — ở đây thành **chặn**, vì phía sau
không còn chỗ nào bắt lại được.

## Ràng buộc: phải chạy bằng ngữ cảnh sạch

Phase này **không được chạy bởi chính agent vừa hiện thực**. Agent vừa viết
code sẽ rà soát chính lập luận của nó — nó đã tự thuyết phục mình rằng cách làm
đó đúng, và nó thiếu mất thứ người review có: chưa từng nhìn thấy code này.

| Khả năng của agent | Cách làm |
|---|---|
| Có subagent (Claude Code) | Chạy trong subagent với ngữ cảnh trắng |
| Không có subagent | Mở phiên mới, chỉ nạp các file đầu vào + diff |

Adapter chịu trách nhiệm dịch ràng buộc này sang cơ chế của agent đích. Không
dịch được thì phải ghi rõ trong hướng dẫn rằng người dùng phải tự mở phiên mới —
chứ không im lặng bỏ qua.

## Bốn lăng kính

Rà theo bốn lăng kính tách bạch, không trộn. Trộn lại thì lăng kính dễ nhất
(chất lượng code) sẽ nuốt mất các lăng kính khó hơn.

### 1. Đúng đặc tả (`## Lens 1 — Spec conformance`)
Duyệt **từng mã `YC-NNN`** trong `spec.md`, chỉ ra code nào thoả nó, kết luận
`pass` / `fail` / `partial`. Không có mã nào được bỏ trống.

Nếu một `YC` gắn `[OPEN-QUESTION]` và giả định tạm chưa được xác nhận, kết luận là
`pending` — không phải `pass`. Chỉ điểm mù `Blocking: non-blocking` còn mở được
tới đây; `blocking` / `review-blocking` còn mở thì máy chặn.

### 2. Đúng thiết kế và phạm vi (`## Lens 2 — Design and scope`)
- Code có theo đúng các D-xx đã duyệt và contract/mô hình dữ liệu trong `tdd.md`?
- Thay đổi nào **không** thuộc task nào? Task nào đánh dấu xong nhưng diff
  không có dấu vết?
- Có mục "Unplanned" nào bị xử lý lặng lẽ thay vì nêu ra?

Thêm: đối chiếu diff với **từng file** quy tắc riêng của repo (`aw rules review` —
hợp quy tắc của mọi phase). Mỗi file một dòng trong mục "Repo rules" của
`review.md`: `pass` / `violation` (kèm `file:dòng`) / `not applicable` (kèm lý do).
Vi phạm thì thêm finding ở Lens 3, mức do bạn phán. Quy tắc repo xếp dưới
`tdd.md`: code theo D-xx đã duyệt mà trái quy tắc là `not applicable`, ghi rõ D nào.

### 3. Chất lượng (`## Lens 3 — Quality`)
Lỗi đúng/sai, chỗ có thể dùng lại thứ đã có, chỗ phức tạp quá mức cần thiết.
Mỗi finding là một mục `### [Blocker|Should fix|Nit] <tiêu đề>`. `Blocker` và
`Should fix` có `- Location: \`file:dòng\`` (số dòng thật); `Blocker` thêm
`- Failure scenario:` — đầu vào cụ thể → kết quả sai, để người khác tái hiện được.
Không có finding nào thì ghi đúng một dòng `- None` — để "không thấy lỗi" khác
"chưa rà".

### 4. Bảo mật (`## Lens 4 — Security`)
Máy quét (`ket-qua-bao-mat.md`) bắt mẫu đã biết — secret lộ, CVE, pattern SAST.
Nó không biết **ý đồ**: endpoint mới thiếu kiểm quyền, log in cả số tài khoản,
đường dẫn ghép từ input người dùng nhưng đi qua hàm nội bộ mà rule không theo
được. Lăng kính này đọc diff để tìm đúng những thứ đó.

Bảng cố định, **đủ cả bảy dòng**, không thêm bớt, không đổi tên:

| Hạng mục | Câu hỏi khi đọc diff |
|---|---|
| `Input validation / injection` | Input từ ngoài (request, file, message, env) đi vào SQL/shell/template/query/regex có được tham số hoá / escape / kiểm dạng không? |
| `Authn / authz` | Endpoint/hành động mới hoặc đổi có kiểm đăng nhập và quyền **đúng như YC Phân quyền** trong `spec.md`? Có chỗ lấy id từ request mà không kiểm chủ sở hữu (IDOR)? |
| `Sensitive data / PII in logs` | Dữ liệu cá nhân, tài chính, token có bị log, trả về thừa trong response, ghi ra file tạm, gửi sang hệ thống ngoài không? |
| `Secrets / config` | Có secret/khoá/mật khẩu cứng trong code, test, config? Mặc định có an toàn (debug tắt, CORS hẹp, TLS bật)? |
| `Crypto` | Thuật toán/độ dài khoá/nguồn ngẫu nhiên có đúng chuẩn? Có tự chế crypto, so sánh token không hằng thời gian? |
| `SSRF / path traversal / deserialization` | URL, đường dẫn file, dữ liệu deserialize có đến từ input không tin cậy mà không giới hạn? |
| `New dependencies` | Dependency mới / nâng bản: có cần thiết, được bảo trì, có trong kết quả SCA, license hợp lệ? |

**Code nhạy cảm.** Repo khai `mau_code_nhay_cam` (vd `src/auth/* src/payment/*`)
mà diff đụng vào thì Lens 4 của agent chưa đủ: một **người** rà bảo mật đọc Lens 4
và diff, rồi tự ghi `- Security reviewer: <tên>` ở đầu `review.md`. Agent **không**
điền dòng này — để trống, nêu danh sách file nhạy cảm (`aw check review` in ra) và
dừng chờ người.

Verdict mỗi dòng: `pass` / `finding` (kèm `file:dòng`, **và** thêm finding ở Lens 3
với mức do bạn phán) / `not applicable` (kèm lý do — vd "diff không có input từ
ngoài"). `not applicable` là kết luận sau khi đã đọc diff, không phải cách bỏ qua
dòng khó.

## Mức độ finding

| Mức | Nghĩa |
|---|---|
| `Blocker` | Sai đặc tả, lệch quyết định đã duyệt, lỗi gây hỏng, **lỗ hổng bảo mật khai thác được**, **mất hoặc lộ dữ liệu**, hoặc **breaking change chưa khai** (API/payload/schema/event đổi mà `tdd.md`/MR không nêu). Không được merge. |
| `Should fix` | Đúng nhưng có vấn đề thật về chất lượng. |
| `Nit` | Tuỳ người viết quyết định. |

## Theo loại việc

Máy kiểm lại mọi luật chặn của `implement`. Phần người phải phán:

| Loại | Người rà soát làm gì |
|---|---|
| `bugfix` | Đọc `tai-hien.md`: test đỏ **đúng vì bug**, không phải vì lỗi biên dịch/thiếu hàm. Ghi `Repro test fails because: <trích output>` — thiếu dòng này thì máy chặn |
| `refactor`/`perf` | Với từng file ở "Modified existing tests": diff chỉ đổi import/cấu trúc, **không đổi assertion** |
| `perf` | Đọc `do-hieu-nang.md`, kết luận YC hiệu năng `pass`/`fail` theo số đo — tính cả độ dao động |
| `chore` | Mức `patch | minor` khai ở "Dependency upgrades" là đúng (major phải là refactor riêng) |

## Đầu ra

- `review.md` — theo `templates/review.md`. Đầu mục, tên trường và giá trị viết tiếng
  Anh, giữ đúng như mẫu (`## Lens 1/2/3/4`, verdict `pass | partial | fail | pending`,
  `## Repo rules` với `pass | violation | not applicable`, `## Lens 4 — Security` với
  `pass | finding | not applicable`, `Repro test fails because:`, `- None`,
  `- Reviewed tree:`, `- Blocker findings: <n>`,
  `[Blocker] / [Should fix] / [Nit]`) — checker đọc theo đúng chữ đó; nội dung điền
  vào viết tiếng Việt.

Dòng `- Reviewed tree:` ở đầu `review.md`: chép dòng `Tree` của
`ket-qua-kiem-thu.md` (máy đã kiểm nó khớp code). Code đổi sau khi rà thì kết luận
không còn nói về code đó — máy chặn, rà lại.

## Cấm

- Rà soát ở chế độ "nhìn qua thấy ổn". Không đi hết từng `YC-NNN` thì phase
  này coi như chưa chạy.
- **Tự sửa code.** Phase này chỉ ghi nhận. Sửa là quay lại `04-implement` với
  task mới — nếu không, findings sẽ biến mất vào một diff không ai kiểm lại.
- Nâng một góp ý phong cách lên mức `Chặn`.
- Kết luận `pass` cho yêu cầu đang đứng trên giả định chưa được xác nhận.
- Tự điền `Security reviewer` — kể cả tên người dùng đang chat với mình. Người
  rà bảo mật tự ghi tên sau khi đọc.
- Ghi `not applicable` cho cả bảng Lens 4 mà không đọc diff, hoặc hạ một lỗ hổng
  khai thác được xuống `Should fix` vì "khó xảy ra".

## Điều kiện ra

**Máy:**
- `aw check review` ra `[x] ĐẠT`:
  - mọi `YC-NNN` có kết luận hợp lệ, không `[OPEN-QUESTION]` nào bị kết luận `pass`;
  - đầu vào qua `aw check plan` (kéo theo design và spec);
  - `ket-qua-kiem-thu.md` có và ghi `Kết quả: XANH`; `ket-qua-bao-mat.md` có và
    ghi `Kết quả: XANH` (cùng lệnh quét với CI);
  - cả hai file ghi `Tree` **khớp nội dung code hiện tại** — code đổi sau lần chạy
    (kể cả chưa commit) thì bằng chứng hết giá trị: chạy lại `aw check implement`
    (hoặc `aw check security`). Commit lại đúng code đó thì không tính là đổi;
  - chore đụng file dependency: có lệnh nhóm `sca` chạy xanh;
  - **không còn cảnh báo nào**: YC chưa có test, diff ngoài phạm vi, artifact lỗi
    thời, loại việc lệch tiền tố branch, test cũ bị sửa chưa khai, điểm mù
    `blocking` / `review-blocking` còn mở;
  - luật theo loại việc (như `implement`), và bugfix có dòng `Repro test fails because:`;
  - repo có quy tắc riêng (`quy_tac_*`): file khai có thật, đã commit, và mục
    "Repo rules" của `review.md` có kết luận hợp lệ cho **từng** file;
  - `## Lens 4 — Security` có đủ bảy hạng mục, verdict `pass | finding | not applicable`,
    `finding` / `not applicable` có vị trí / lý do, và có `finding` thì Lens 3 phải
    có ít nhất một finding;
  - `## Lens 3 — Quality` có ít nhất một finding **hoặc** đúng dòng `- None` (không
    cả hai), không còn chữ giữ chỗ của mẫu; `[Blocker]` / `[Should fix]` có
    `Location` dạng `file:dòng`; `[Blocker]` có `Failure scenario`;
  - `## Conclusion` có `- Blocker findings: <n>` với `n` bằng số mục `[Blocker]`;
  - `- Reviewed tree:` khớp dấu vân tay code hiện tại;
  - diff đụng `mau_code_nhay_cam` thì có `- Security reviewer: <tên người>` (không
    trống, không giữ chỗ, không phải tên agent).
- Diff được so với **base ghi trong `intake.md`**, không phải `nhanh_goc`. Base
  không phải nhánh gốc hay nhánh phát hành (vd xếp chồng lên branch việc khác)
  thì checker **chỉ cảnh báo** — nêu ra cho người.

**Người:**
- Xác nhận kết luận; quyết định xử lý các finding mức `Blocker`.
- Có cảnh báo base: xác nhận việc dựa trên code của branch khác là có chủ ý.
