### Thêm
- **`aw journal export <file>` và `aw journal report <file>…`.** Nhật ký harness nằm ở bản clone từng máy; giờ
  xuất được ra một TSV (cột nguồn, máy, rồi cột gốc) và tổng hợp trên nhiều file export — gom số liệu khi chạy
  thử trên nhiều máy / nhiều người. Dòng sai dạng bị bỏ qua và báo số dòng.
- **Vòng review → sửa có đường đi rõ.** Finding `Blocker` / `Should fix` của `review.md` mang mã `RVW-NNN`;
  `/aw-plan` chạy lại sau review ở chế độ **bổ sung**: chỉ thêm task, task sửa ghi `Fixes: RVW-NNN` (hoặc
  `Fixes: <URL bình luận MR>`) thay `Covers:`. `aw check plan` kiểm `Fixes` trỏ mã có thật. `Blocker` vẫn
  luôn phải sửa.
- **Glob `**` trong `plan.md`.** `Expected files` / `Unplanned` dùng được `**` (khớp qua thư mục). Giai đoạn
  chuyển tiếp: `*` vẫn khớp qua `/` nhưng `aw check implement` / `aw check review` cảnh báo (không chặn) file
  chỉ khớp nhờ `*` vượt thư mục và gợi ý cách viết `**` — bản sau `*` của `plan.md` sẽ không qua `/`. Glob
  của `conventions.md` không đổi.
- **Kiểm phạm vi diff theo từng task.** `aw task start` ghi commit lúc bắt đầu; `aw task done` cảnh báo
  file task đổi mà không nằm trong `Expected files` của chính nó (hay hàng `Unplanned` có cột Task = task
  đó) và ghi `Scope warning` vào `task-results.md`. `/aw-review` chặn nếu dòng `Task scope warnings` ở
  Lens 2 không giải trình task đó. Việc bắt đầu ở bản cũ (không có `Started at`) không bị kiểm.
- **Cảnh báo glob rộng ở `aw check plan`.** Mẫu `Expected files` khớp nhiều file đã track trên commit
  `Base:` hơn khoá mới `scope_glob_max_files` (mặc định 30; `0` = tắt) thì cảnh báo. `conventions.md` cũ
  không có khoá vẫn chạy với mặc định; thêm khoá khi muốn đổi ngưỡng.

### Nội bộ
- **Roadmap cải thiện engine theo dự án con.** `docs/superpowers/2026-10-22-roadmap-cai-thien.md` chia
  kết quả lượt đánh giá 10/2026 (engine và interface SDLC) thành 12 dự án con có thứ tự, phụ thuộc và
  câu cần người quyết; mỗi dự án con đi spec → plan → PR theo luồng Superpowers. `docs/viec-can-lam.md`
  trỏ tới roadmap. Không đổi hành vi `aw`.
- **Interface SDLC: capability phạm vi.** Thêm `CAP-breakdown-02` (task nêu file được đổi và cách kiểm),
  `CAP-implement-04` (file đổi nằm trong kế hoạch hoặc khai ngoài kế hoạch), `CAP-implement-05` (phạm vi
  theo từng task, mẫu file hẹp), `CAP-implement-06` (task chỉ xong khi máy ghi bước kiểm đạt). Cả bốn đều có
  phase nhận; stage `implement` vẫn `implemented`. Người dùng `aw` không thấy gì khác.
- **Interface SDLC: capability khai `Artifact`.** Mỗi capability ghi loại artifact nó bảo đảm
  (`- Artifact:`); `tools/check-sdlc.sh` chặn khi thiếu, khi loại không thuộc `provides` của stage,
  khi khai nhiều dòng, và khi một loại `provides` của stage không capability nào trỏ tới.
- **Frontmatter: mục danh sách bỏ khoảng trắng cuối dòng.** `fm_list` (`tools/lib/md.sh`) cắt khoảng
  trắng thừa sau mỗi mục, nên `  - delivery  ` không còn lệch tên với `delivery` ở các checker so tên loại.

### Bỏ
- **Hai adapter `planned` (`codex`, `copilot`) khỏi `workflow.yaml`.** Chưa có thư mục hay mã nào; mục
  `planned` chỉ là lời hứa trong manifest. Thêm lại khi có người dùng thật cần, theo `adapters/README.md`
  (ghi chú về Codex vẫn giữ ở đó). Người dùng `aw` không thấy gì khác.

### Nội bộ
- **`check-sdlc.sh` chặn YAML ngoài tập con.** `yaml_kiem` (`tools/lib/md.sh`) báo từng dòng sai kèm
  file + số dòng (tab, `k:v`, thụt sâu, khối `|`/`>`, `{…}`, danh sách `[a, b]`) trên `workflow.yaml`,
  phase, utility command, file stage, profile — trước đây dòng lạ bị đọc thành rỗng, lỗi lộ ở chỗ khác.
- **Invariant chặt hơn.** Mọi invariant nêu ít nhất một ca test chặn (trước đây INV-001…006 chỉ trỏ
  file); `Rule:` của capability và invariant không còn cú pháp engine (máy chặn backtick, mã `REQ-`/
  `DEC-`…), cách engine hiện thực chuyển sang dòng `- Engine:`. Ba bảng của `check-sdlc.sh` chỉ còn một
  ảnh chụp (`docs/interface-sdlc.md` § 6), có test so với output.
- **Capability out-of-scope.** Khoá `out_of_scope:` của `workflow.yaml` khai capability engine quyết không
  làm kèm lý do (e2e, kiểm tải, triển khai, quan sát production); `check-sdlc.sh` in chúng ở khối "Không
  làm" thay vì roadmap. Trạng thái stage không đổi.

### Thay đổi
- **`aw check review` chặn finding `Blocker` / `Should fix` không có mã `RVW-NNN` hoặc trùng mã.** Review mới
  phải viết tiêu đề dạng `### [Blocker] RVW-001 — <tiêu đề>` (mẫu `review.md` đã đổi); `[Nit]` không cần mã.
- **INV-001 nới** (interface SDLC): "mọi task phủ một REQ" thành "mọi task phủ một REQ **hoặc sửa một finding
  của review hiện tại**". Lý do: finding lỗi (thiếu kiểm null, lỗ hổng) thường không gắn REQ nào; buộc
  `Covers:` khiến agent gán đại REQ, làm sai ánh xạ REQ → task mà review Lens 1 dựa vào.

### Nội bộ
- **Checker nhanh hơn: nhớ `git rev-parse` và quy ước hiệu lực.** `git_top` / `git_common` (`tools/lib/md.sh`)
  nhớ theo thư mục trong biến shell; `nho_san` hâm sẵn ở shell chính của mỗi checker và `aw task`, nên các
  `$(…)` sau dùng lại. Một lần `aw check review` trên fixture: 183 → 68 lần gọi git, 2,3 → 1,4 giây.
  `check-sdlc.sh` tra thứ tự stage trong shell thay vì một `awk` mỗi lần.
- **Test:** helper `ky_vong_ly_do` chạy checker một lần cho cặp "mã thoát + lý do" (24 cặp đã chuyển);
  tách `22-sdlc-stage-files` → thêm `23-sdlc-syntax`, `25-sdlc-capabilities`; tách `20-sdlc-conformance` → thêm
  `24-sdlc-stage-status`.

### Sửa
- **Phạm vi diff:** hàng `Unplanned` chỉ lấy cột "Extra files" làm mẫu được phép (backtick ở cột "What came up"
  không còn vô tình miễn file); dòng `Base:` thiếu sha thì cảnh báo glob rộng lùi về điểm rẽ nhánh thay vì bỏ qua.
- **`aw task start` giữ bộ đếm đỏ liên tiếp** — sửa tay Status về `[ ]` rồi start lại không còn né được điều
  kiện DỪNG (đúng như trước PR #79).
- **Mã `RVW`:** `aw check plan` đọc mã finding giống `aw check review` (tiêu đề Lens 3 có `[mức]` rồi mã, kể
  cả `### 1. [Blocker] RVW-001 — …`); dòng `Task scope warnings` phải nhắc đúng mã task (`TSK-0021` không
  tính là nhắc `TSK-002`).
- **Glob `[abc]`, `[!a]`** khớp như `case` của shell ở mọi hàm khớp mới (đếm glob rộng, cảnh báo chuyển tiếp).
- **`aw journal report`** không đếm hai lần một file truyền trùng; file / thư mục tạm không còn tên đoán trước
  được (cảnh báo chuyển tiếp không dùng file tạm; report dùng `mktemp -d`).

### Nội bộ
- **Luật checker mới phải gắn `# giữ: CAP-…/INV-…` (bước A, đợt 2).** `tools/unclassified-rules.txt` đếm số chỗ
  luật (`loi` / `loi_truoc` / `[CẢNH BÁO]`) chưa gắn id của từng `tools/check-*.sh` và `tools/task.sh` (153 chỗ
  lúc bắt đầu); `check-sdlc.sh` chặn khi vượt (luật mới không id) và khi thấp hơn mà chưa hạ — danh sách chỉ
  giảm. `sh tools/check-sdlc.sh --dem-luat` in số đúng.
