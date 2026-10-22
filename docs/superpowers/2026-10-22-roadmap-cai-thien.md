# Roadmap cải thiện engine (10/2026)

> Nguồn: lượt đánh giá engine và interface SDLC ngày 2026-10-22. File này là **danh sách dự án con**
> cho luồng Superpowers: mỗi dự án con đi đủ `brainstorming` → spec (`specs/`) → người duyệt →
> `writing-plans` → plan (`plans/`) → người duyệt + chọn cách thực thi → implement → PR.
> Không có dòng nào ở đây là luật đã duyệt: mỗi dự án con là một **đề xuất** theo `AGENTS.md`
> § Making a change.

## Nguyên tắc

1. **Lõi trước meta.** Đóng lỗ ở vòng chạy chính (phạm vi diff, review → sửa) trước khi mở rộng lớp
   interface (bước A).
2. **Interface trước implementation.** Dự án con đổi hành vi một stage thì sửa `sdlc/` trong cùng PR
   (`docs/interface-sdlc.md` § 4).
3. **Mỗi luật mới trả lời được:** chặn lỗi nào đã thấy hoặc rất dễ xảy ra?
4. **Một dự án con = một spec = một plan = một PR.** Dự án con lớn hơn một PR → tách khi brainstorm.
5. Spec của dự án con chỉ viết khi tới lượt — spec viết sớm cũ đi theo các PR trước nó.

## Thứ tự và phụ thuộc

| # | Dự án con | Đợt | Phụ thuộc | Cần người quyết trước spec | Spec | Plan | PR |
|---|---|---|---|---|---|---|---|
| SP1 | Capability phạm vi + capability theo `purpose`/`provides` | 1 | — | — | [spec](specs/2026-10-22-sp1-capability-artifact-design.md) | | |
| SP2 | Invariant chặt hơn | 2 | — | — | | | |
| SP3 | Kiểm phạm vi diff | 1 | SP1 | — | | | |
| SP4 | Vòng review → sửa | 1 | SP2 | Có cho "chấp nhận" Blocker? | | | |
| SP5 | `out-of-scope` cho capability | 2 | SP1 | Có đảo quyết định "không có out-of-scope"? | | | |
| SP6 | Tốc độ engine và test | 3 | — | — | | | |
| SP7 | Parser YAML báo lỗi | 3 | — | — | | | |
| SP8 | Glob `**` | 3 | SP3 | Có chấp nhận đổi nghĩa `*`? | | | |
| SP9 | Chạy thật + gom nhật ký | 4 | SP3, SP4 | Repo đích nào | | | |
| SP10 | Đường tắt cho việc nhỏ | 4 | số liệu SP9 | A / B / C | | | |
| SP11 | Adapter thứ ba hoặc gỡ `planned` | 4 | — | Làm hay gỡ | | | |
| SP12 | Bước A — gắn luật checker vào CAP/INV | sau | SP1, SP2 | — | | | |

Cột Spec / Plan / PR: điền đường dẫn hoặc link khi có. Dự án con xong (PR merge) thì giữ dòng, ghi
link PR — lịch sử nằm ở đây, nội dung nằm ở `CHANGELOG.md`.

Không làm lúc này: tách interface thành repo riêng (chờ implementation thứ hai); deploy/operate
(`CAP-deploy-02`, `CAP-operate-01` — đánh dấu out-of-scope qua SP5 nếu được duyệt).

## Đợt 1 — Vá lõi

### SP1 — Capability phạm vi và capability theo `purpose`/`provides`

**Vấn đề.** `04-implement.md` gọi scope creep là lỗi điển hình, nhưng `sdlc/` không có capability hay
invariant nào về phạm vi. Stage `breakdown` có 1 capability, `implement` có 2 — `implemented` nói
nhiều hơn engine đảm bảo; stage càng ít capability càng dễ `implemented`.

**Hướng.**
- `CAP-implement-04` — thay đổi nằm trong kế hoạch task đã duyệt; lệch thì được khai (machine).
  Engine chưa làm đủ → `implement` thành `partial`, `note` nói kiểm phạm vi còn thô.
- `CAP-implement-05` — task chỉ xong khi bước kiểm của nó đạt, máy ghi (machine). Engine làm sẵn
  (`aw task done`) → phase nhận ngay.
- Rà mọi stage: mỗi loại trong `provides` có ít nhất một capability nói về nó; thêm phần thiếu.
- Cân nhắc: `check-sdlc.sh` kiểm luật "mỗi `provides` có capability" (cần đánh dấu capability ↔
  loại artifact — quyết khi brainstorm).

**Interface.** Thêm capability (`interface-sdlc.md` § 4.3). **Test.** `22-sdlc-stage-files.sh`,
`20-sdlc-conformance.sh`.

### SP3 — Kiểm phạm vi diff

**Vấn đề.** `kc_pham_vi` (`tools/lib/cross-check.sh`) kiểm theo hợp `Expected files` của mọi task;
`khop_glob` (`tools/lib/md.sh`) để `*` khớp cả `/`; glob rộng lan sang phạm vi luật `BR-`
(`docs/viec-can-lam.md` mục 2, `kien-truc.md` điểm yếu 9, 21).

**Hướng.**
- `aw check plan` **cảnh báo** glob khớp > N file đã track trên `Base:` (khoá `scope_glob_max_files`,
  mặc định 30, `0` = tắt). Glob khớp 0 file → không cảnh báo.
- `aw task start` ghi tree lúc bắt đầu; `aw task done` so file đổi với `Expected files` của chính
  task + `Unplanned` ghi tên task → lệch thì **cảnh báo**.
- Review Lens 2 ghi một dòng cho mỗi cảnh báo phạm vi; review **chặn** khi thiếu dòng (không chặn vì lệch).
- Xong → phase nhận `CAP-implement-04`, xoá/sửa `note`.

**Test.** `02-spec-design-plan.sh` (ngưỡng, `0`, glob 0 file), `15-conventions-task.sh` (đụng file
task khác, file trong `Unplanned`, khoá mới hợp lệ), `05-review-quality.sh` (thiếu dòng Lens 2).

### SP4 — Vòng review → sửa

**Vấn đề.** `docs/viec-can-lam.md` mục 1: không ai được thêm task sau review; finding không có mã;
`aw check plan` buộc `Covers:` nên agent gán đại REQ; quyết định của người cho Blocker không có dấu.

**Hướng.**
- Finding `Blocker`/`Should fix` có mã `RVW-NNN`; `aw check review` **chặn** thiếu/trùng mã.
- `/aw-plan` chế độ bổ sung khi `review.md` còn finding cần sửa: chỉ thêm task, `Fixes: RVW-NNN`.
- `aw check plan` **chặn** task không `Covers:` lẫn `Fixes:`; `Fixes:` trỏ mã không có (task `[ ]`).
- INV-001 nới thành "covers a requirement or fixes a review finding" → `### Thay đổi` trong `changes/`.
- Phản hồi reviewer MR: `Fixes: <URL>`, kiểm dạng URL.

**Cần quyết trước spec.** Cho phép `Decision: accept: <lý do>` với Blocker (hiện trong
`merge-request.md`), hay Blocker luôn phải sửa?

**Test.** `05-review-quality.sh`, `02-spec-design-plan.sh`, `14-ship-ready.sh`; một ca trọn vòng
review → plan bổ sung → `aw task next` → review lại.

## Đợt 2 — Interface đáng tin

### SP2 — Invariant chặt hơn

- INV-001…INV-006 nêu tên ca test trong `Tested by:` (như INV-007…INV-011).
- `Rule:` trừu tượng, không cú pháp engine (`Based on: DEC-xxx`, `covers:`, `production_code`,
  `REQ`…); cú pháp chuyển sang dòng riêng (vd `- Engine:`) hoặc `Enforced by`. `check-sdlc.sh`
  **chặn** `Rule:` có backtick hoặc mã `REQ`/`DEC` — áp cho cả `Rule:` của capability.
- Bỏ ảnh chụp bảng trùng: chỉ giữ `interface-sdlc.md` § 6, `kien-truc.md` trỏ link; test so ảnh chụp
  với output `check-sdlc.sh`.

**Test.** `22-sdlc-stage-files.sh`; ca so ảnh chụp mới.

### SP5 — `out-of-scope` cho capability

- Engine khai `out_of_scope:` (id + lý do) trong khối `sdlc:` của `workflow.yaml` — phía
  implementation, interface không biết.
- Trạng thái stage giữ nguyên cách suy ra (không giấu chỗ thiếu); roadmap tách "sẽ làm" và
  "không làm, lý do".
- Đảo một quyết định ở `kien-truc.md` § Interface SDLC → ghi lý do mới ở đó.

**Test.** `20-sdlc-conformance.sh`: id out-of-scope không tồn tại → chặn; vừa out-of-scope vừa có
phase nhận → chặn; thiếu lý do → chặn.

## Đợt 3 — Tốc độ và độ bền

### SP6 — Tốc độ engine và test

- Cache `git rev-parse --show-toplevel / --git-common-dir` qua biến môi trường đặt một lần ở
  `bin/aw-engine`; `kc_top`, `adr.sh`, `artifact.sh`… đọc biến trước.
- Gộp ~50 cặp ca "…đúng lý do" chạy checker hai lần thành một lần.
- Mục tiêu: `sh tools/run-tests.sh` < 3 phút thực trên 4 luồng (hiện ~5 phút). Đo trước/sau.
- Không đổi hành vi: test hiện có là lưới an toàn.

### SP7 — Parser YAML báo lỗi

- `tools/lib/md.sh` **chặn** dòng ngoài tập con (`k: v`, `k:` + `  - item`, `k: []`) trong
  frontmatter phase, `workflow.yaml`, `sdlc/` — báo file + dòng, thay vì trả rỗng.
- **Test.** Mỗi dạng sai (tab, `k:v`, list lồng, chuỗi nhiều dòng) → chặn đúng dòng; file hiện tại → ĐẠT.

### SP8 — Glob `**`

- Hàm khớp mới: `*` không qua `/`, `**` qua. Thay đổi phá vỡ → một release cảnh báo plan dùng `*`
  sẽ đổi nghĩa, release sau mới đổi.
- **Cần quyết trước spec.** Chấp nhận đổi nghĩa và lộ trình hai release?
- **Test.** Bảng khớp/không khớp cho `*`, `**`, `dir/*`, `dir/**`; plan cũ nhận cảnh báo.

## Đợt 4 — Chứng minh giá trị

### SP9 — Chạy thật + gom nhật ký

- 1–2 repo đích, 2–4 tuần. Số liệu: việc theo loại, thời gian phase, số lần người can thiệp,
  checker chặn đúng / chặn nhầm.
- `aw journal export` ra file commit được (điểm yếu 14).
- Kết quả: báo cáo ở `docs/` làm đầu vào SP10 và thứ tự các dự án con còn lại.

### SP10 — Đường tắt cho việc nhỏ

- Chỉ brainstorm khi có số liệu SP9. Lựa chọn ở `docs/viec-can-lam.md` mục 4 (A giữ nguyên,
  B chore gộp spec + plan, C loại việc mới có giới hạn cứng).

### SP11 — Adapter thứ ba hoặc gỡ `planned`

- Làm adapter `codex` hoặc `copilot` theo `adapters/README.md` (test so sánh `AW_COMPARE=1`), **hoặc**
  gỡ hai mục `planned` khỏi `workflow.yaml` để manifest không hứa suông.

## Sau các đợt

### SP12 — Bước A: gắn luật checker vào CAP/INV

- Như `docs/viec-can-lam.md` § Interface SDLC: ~200 chỗ chặn/cảnh báo mang id `CAP-…`/`INV-…`;
  `check-sdlc.sh` chặn luật mồ côi; capability `machine` có phase nhận mà không luật nào gắn → chặn;
  suy "diff chạm CAP/INV nào" từ file đổi.
- Brainstorm sau SP1 + SP2 (tập capability lúc đó khác hiện tại). Gần chắc phải tách nhiều PR.
