### Nội bộ
- **Interface SDLC trong repo engine (`sdlc/`).** Bảy stage có đặc tả (`plan`, `require`, `design`,
  `implement`, `verify`, `deploy`, `operate` — `sdlc/stages/`) và các `invariant` xuyên stage
  (`sdlc/invariants.md`, mỗi luật trỏ tới checker + test có thật). Engine là một implementation: mỗi
  phase khai `implements:` stage nó làm và `provides:` loại artifact → file; khối `sdlc:` của
  `workflow.yaml` khai stage engine chỉ làm một phần (`plan`, `verify`, `deploy`: `partial`) hay không
  làm (`operate`: `gap`), kèm lý do. Vì sao: chỗ engine không làm (deploy, vận hành) trước đây không
  được ghi ở đâu; giờ không khai thì máy chặn.
- **`tools/check-sdlc.sh`** kiểm cấu trúc lời khai đó (stage có phase hay khai `gap`, `provides` phủ
  stage, `exit` khớp `exit_machine`/`exit_human`, thứ tự, `requires`, invariant, utility command không
  khai `implements`). Chỉ kiểm cấu trúc, không kiểm chất lượng. Không phải lệnh `aw check`: chạy trong
  `sh tools/run-tests.sh` (`tools/tests/20-sdlc-conformance.sh`). **Ai bị ảnh hưởng:** người sửa engine —
  thêm hay đổi phase thì khai `implements`/`provides` (`AGENTS.md` § Change together). Người dùng `aw`
  không thấy gì khác: lệnh adapter sinh ra giữ nguyên; `terms.md` (agent đọc) có thêm ba thuật ngữ
  `stage`, `stage status`, `invariant`.
