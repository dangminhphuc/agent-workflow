### Nội bộ
- **Profile theo job type trong interface SDLC (`sdlc/profiles/<job-type>.md`).** Một file cho mỗi
  job type (`feature`, `bugfix`, `refactor`, `perf`, `chore`) khai stage nào có thể không chạy
  (`skippable`: design với bugfix/refactor nhỏ, deploy với mọi loại), stage nào luôn bỏ (`skipped`:
  design với chore), loại artifact thêm (`reproduction-evidence` của bugfix, `performance-evidence`
  của perf) và invariant riêng của loại. Vì sao: interface trước đây chỉ mô tả luồng `feature` đầy
  đủ — stage implement `requires: design` vô điều kiện dù chore không có design, `repro.md`/`perf.md`
  không thuộc loại artifact nào, luật riêng của từng loại không có chỗ khai.
- **Năm invariant mới `INV-007`…`INV-011`** (`sdlc/invariants.md`): bugfix — test tái hiện đỏ trên
  code chưa sửa; refactor/perf — REQ không thêm hành vi, test cũ không bị xoá và mọi chỗ sửa được
  khai; perf — số đo trước/sau do máy ghi; chore — không đụng `production_code`, dependency phải khai,
  không nâng major. Mỗi cái trỏ tới checker có thật và **tên ca test cụ thể**: `Tested by:` nay nhận
  tên ca trong ngoặc kép sau file, checker kiểm ca đó có trong file.
- **`tools/check-sdlc.sh` kiểm profile:** tập profile phải trùng tập job type engine nhận
  (`LOAI_HOP_LE`, nguồn `check-intake.sh` dùng); stage bỏ được phải khớp hành vi thật của engine
  (deploy ⇔ `06-ship` có `required: false`; design ⇔ `kc_bo_design`, checker gọi thẳng hàm đó); stage
  khai `skippable: false` (plan, require, implement, verify) không được bỏ; artifact thêm phải được một
  phase map ra file và do stage luôn chạy cung cấp; invariant phải có. Checker in ma trận job type ×
  stage và loại artifact có thể vắng theo từng profile. Test: `tools/tests/21-sdlc-profiles.sh` (part
  mới, tách khỏi `20-sdlc-conformance.sh` vì chậm).
- **`04-implement` khai thêm output `repro.md` (bugfix) và `perf.md` (perf)** — hai file `aw check
  repro` / `aw check perf` vốn đã ghi trong phase này nhưng frontmatter chưa liệt kê. **Ai bị ảnh
  hưởng:** dòng "Writes" của lệnh `/aw-implement` adapter sinh ra có thêm hai file đó; luật và hành vi
  của `aw` không đổi. Người sửa engine: thêm job type mới thì thêm profile (`AGENTS.md` § Change
  together).
- **Hai loại artifact mới của stage `implement`: `task-evidence` và `security-evidence`.** Phase
  `04-implement` map chúng ra `task-results.md` (`aw task done`) và `security-results.md` (`aw check
  implement`); stage `verify` khai `requires` cả hai. Vì sao: review vốn chặn khi thiếu hai file này với
  mọi job type, nhưng interface không biết verify cần bằng chứng từng task và bằng chứng quét bảo mật.
  **Ai bị ảnh hưởng:** không ai — chỉ đổi mô tả interface, lệnh adapter sinh ra giữ nguyên.
- **Stage mới `breakdown` (lập task) tách khỏi `implement` (viết code).** Interface có 8 stage; phase
  `03-plan` nay `implements: breakdown`, mỗi stage tối đa một phase. `breakdown` provides `task-plan`,
  giữ INV-001, INV-002 và capability `CAP-breakdown-01` (trước là `CAP-implement-01`, cùng nội dung);
  `implement` thêm `requires: task-plan`, giữ INV-003, `CAP-implement-02`, `-03`. File stage đánh số lại
  (`03-breakdown` … `07-operate`). Vì sao: phụ thuộc "code theo kế hoạch đã duyệt" trước đây bị giấu
  trong một stage, và `check-sdlc.sh` không bắt được việc đổi chỗ phase `plan` ↔ `implement` trong
  `workflow.yaml` — giờ chặn. **Ai bị ảnh hưởng:** người sửa engine (gắn capability của phase `03-plan`
  vào `CAP-breakdown-*`); người dùng `aw` không thấy gì khác.
- **Test `20-sdlc-conformance.sh` tách đôi** vì chậm: nhóm điều kiện ra, file stage, capability, invariant
  sang part mới `tools/tests/22-sdlc-stage-files.sh`.
