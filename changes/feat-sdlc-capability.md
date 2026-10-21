### Thêm
- **Capability cho mọi stage của interface SDLC (`CAP-<stage>-NN`).** Mỗi file `sdlc/stages/*.md` có
  mục `## Capabilities`: các điều stage phải làm được khi làm **đủ**, kèm `Rule` và `Judged by`
  (`machine`, `agent` hay `human` phán đạt) — 23 capability, gồm cả phần engine chưa làm (ưu tiên,
  ước lượng, e2e, kiểm tải, UAT, release, rollback, quan sát production, sự cố → việc mới). Vì sao:
  trước đây phần thiếu chỉ là một câu `note` tự do, không ai biết "làm đủ một stage" là gì; giờ
  interface là trạng thái đích, chỉ ra việc tiếp theo.
- **Bảng roadmap trong `sh tools/check-sdlc.sh`**: "Capability còn thiếu" theo stage, kèm note. Mỗi lỗi
  của checker nói luôn cách sửa.
- **`docs/interface-sdlc.md`** — hướng dẫn cho người sửa engine: interface gồm gì, đọc file stage,
  trạng thái được suy ra thế nào, công thức cho 7 loại thay đổi (thêm luật, làm capability thiếu, thêm
  capability, thêm phase, thêm job type, hạ chuẩn interface, thay đổi không chạm interface), đọc lỗi
  `check-sdlc.sh`, và roadmap hiện tại giải thích bằng tiếng Việt. Thuật ngữ mới: `capability`.

### Thay đổi
- **Trạng thái stage do máy suy ra, khối `sdlc:` của `workflow.yaml` bỏ khoá `status`.** Phase khai
  `capabilities:`; capability có phase nhận hết = `implemented`, một phần = `partial`, không = `gap`.
  Khối `sdlc:` chỉ còn `note` (bắt buộc với `partial`/`gap`, cấm với `implemented`). Phase `implements`
  một stage mà không nhận capability nào → chặn. **Ai bị ảnh hưởng:** người sửa engine hay giữ bản fork
  có khối `sdlc:` riêng — xoá các dòng `status:` (còn sót thì `check-sdlc.sh` chặn và chỉ dòng cần xoá).
  Người dùng `aw` trên repo dự án không thấy gì khác: lệnh adapter sinh ra giữ nguyên (đã so byte với
  `main`); `workflow/rules/terms.md` (danh sách thuật ngữ agent đọc) có thêm `capability` và dòng
  `stage status` nói trạng thái được suy ra.

### Nội bộ
- **Interface đi trước implementation (`AGENTS.md`).** Mọi thay đổi engine nêu `CAP-…` / `INV-…` nó
  phục vụ; không id nào khớp thì sửa interface trong cùng PR. Mô tả PR có dòng "Interface: …" (quy ước,
  máy chưa kiểm). Hạ chuẩn interface (bỏ / nới capability hay invariant) ghi id + lý do dưới `### Bỏ` /
  `### Thay đổi` của mảnh changelog. Lý do từng quyết định: `docs/kien-truc.md` § Interface SDLC.
- `tools/check-sdlc.sh` kiểm thêm: dạng capability (heading, id trùng, `Rule`, `Judged by`), phase nhận
  id có thật của đúng stage, utility command không khai `capabilities`, note khớp trạng thái suy ra.
  Test: `tools/tests/20-sdlc-conformance.sh`.
