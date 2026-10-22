### Thêm
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
  theo từng task, mẫu file hẹp — chưa làm), `CAP-implement-06` (task chỉ xong khi máy ghi bước kiểm đạt).
  Stage `implement` thành `partial`. Người dùng `aw` không thấy gì khác.
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
