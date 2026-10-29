# Roadmap engine

> Ghi chú cho người phát triển engine, không phải tài liệu dùng. Đây là **nơi duy nhất** ghi việc còn
> làm của engine (thay `docs/viec-can-lam.md` cũ). Việc đã làm xem `CHANGELOG.md`.
>
> Nguồn ban đầu: lượt đánh giá engine và interface SDLC ngày 2026-10-22 (SP1–SP12), cộng các mục còn
> lại của `docs/viec-can-lam.md` (SP13–SP19, khối Không làm). Không có dòng nào ở đây là luật đã duyệt:
> mỗi dự án con là một **đề xuất** theo `AGENTS.md` § Making a change.

## Cách dùng

- **Một dự án con đi đủ luồng Superpowers:** `brainstorming` → spec (`specs/YYYY-MM-DD-spNN-<chủ-đề>-design.md`)
  → người duyệt → `writing-plans` → plan (`plans/`) → người duyệt + chọn cách thực thi → implement → PR.
- **Ý tưởng mới** (kể cả ý liên quan nảy ra khi làm việc khác, `AGENTS.md` § Making a change): người
  đồng ý thì thêm một dòng vào bảng (số `SP` kế tiếp, trạng thái `chờ`) và một mục ở § Chi tiết với
  **Vấn đề**, **Hướng**, **Cần quyết** — chưa viết spec.
- **Xong:** điền link PR, trạng thái `xong`; xoá mục ở § Chi tiết (nội dung đã nằm trong spec và
  `CHANGELOG.md`). **Bỏ:** chuyển sang § Không làm kèm lý do.
- Trạng thái: `chờ` (chưa tới lượt) · `chặn` (đợi phụ thuộc hoặc người quyết) · `đang làm` (có spec) ·
  `xong` (PR đã merge) · `một phần` (xong một đợt, phần còn lại thành dự án con khác).

## Nguyên tắc

1. **Lõi trước meta.** Đóng lỗ ở vòng chạy chính (spec, phạm vi diff, review → sửa) trước khi mở rộng
   lớp interface (bước A).
2. **Interface trước implementation.** Dự án con đổi hành vi một stage thì sửa `sdlc/` trong cùng PR
   (`docs/interface-sdlc.md` § 4).
3. **Mỗi luật mới trả lời được:** chặn lỗi nào đã thấy hoặc rất dễ xảy ra?
4. **Một dự án con = một spec = một plan = một PR.** Dự án con lớn hơn một PR → tách khi brainstorm.
5. Spec của dự án con chỉ viết khi tới lượt — spec viết sớm cũ đi theo các PR trước nó.

## Thứ tự và phụ thuộc

| # | Dự án con | Đợt | Trạng thái | Phụ thuộc | Cần người quyết trước spec | Spec | Plan | PR |
|---|---|---|---|---|---|---|---|---|
| SP1 | Capability phạm vi + capability theo `purpose`/`provides` | 1 | xong | — | — | [spec](specs/2026-10-22-sp1-capability-artifact-design.md) | [plan](plans/2026-10-22-sp1-capability-artifact.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP2 | Invariant chặt hơn | 2 | xong | — | — | [spec](specs/2026-10-22-sp2-invariant-chat-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP3 | Kiểm phạm vi diff | 1 | xong | SP1 | — | [spec](specs/2026-10-22-sp3-pham-vi-diff-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP4 | Vòng review → sửa | 1 | xong | SP2 | Chốt: Blocker luôn phải sửa | [spec](specs/2026-10-22-sp4-review-sua-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP5 | `out-of-scope` cho capability | 2 | xong | SP1 | Chốt: thêm out-of-scope | [spec](specs/2026-10-22-sp5-out-of-scope-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP6 | Tốc độ engine và test | 3 | xong | — | — | [spec](specs/2026-10-22-sp6-7-toc-do-yaml-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP7 | Parser YAML báo lỗi | 3 | xong | — | — | [spec](specs/2026-10-22-sp6-7-toc-do-yaml-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP8 | Glob `**` (bước 1: chuyển tiếp) | 3 | xong | SP3 | Chốt: đổi có chuyển tiếp, chỉ glob của plan.md | [spec](specs/2026-10-22-sp8-glob-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP9 | Chạy thật + gom nhật ký | 4 | một phần | SP3, SP4 | Chạy thật: người làm | [spec](specs/2026-10-22-sp9-11-12-design.md) (chỉ công cụ) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) (công cụ), [#100](https://github.com/dangminhphuc/agent-workflow/pull/100) (đo lường journal) |
| SP10 | Đường tắt cho việc nhỏ | 4 | một phần | số liệu SP9 | A xong (#81); B / C chờ số liệu SP9 | [spec](specs/2026-10-22-dot-2-design.md) § B | [plan](plans/2026-10-22-dot-2.md) | [#81](https://github.com/dangminhphuc/agent-workflow/pull/81) |
| SP11 | Gỡ adapter `planned` | 4 | xong | — | Chốt: gỡ planned | [spec](specs/2026-10-22-sp9-11-12-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP12 | Bước A đợt 1 — gắn luật checker vào CAP/INV | sau | xong | SP1, SP2 | — | [spec](specs/2026-10-22-sp9-11-12-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP13 | Checker LLM cho spec | 5 | xong | — | Bản đầu chỉ so `Quote` và lời `[HUMAN]` | | | [#83](https://github.com/dangminhphuc/agent-workflow/pull/83) |
| SP14 | Bugfix: lệnh tái hiện xanh sau khi sửa | 5 | xong | — | So cả lệnh, không tách tên test; cảnh báo ở implement, chặn ở review | | | [#84](https://github.com/dangminhphuc/agent-workflow/pull/84) |
| SP15 | `out_of_scope` cho capability `plan`/`verify` engine không định làm | 5 | xong | — | — | | | [#85](https://github.com/dangminhphuc/agent-workflow/pull/85) |
| SP16 | `CAP-operate-02`: sự cố → việc mới | 5 | một phần | — | Nhãn `[INCIDENT]` xong; capability vẫn human vì stage operate | | | [#86](https://github.com/dangminhphuc/agent-workflow/pull/86) |
| SP17 | Refactor/perf: không đổi assertion test cũ | sau | chặn | số liệu SP9 | Có đáng làm không | | | |
| SP18 | Glob bước 2: `*` của `plan.md` không qua `/` | sau | chặn | SP8 đã phát hành | Luật `BR-` cũ: cảnh báo hay chuyển đổi | | | |
| SP19 | Bước A đợt 2 — luật mồ côi, suy CAP/INV từ diff | sau | một phần | — | `--suy` xong; không gắn hàng loạt (id có sẵn vẫn qua máy dù gắn nhầm) | [spec](specs/2026-10-22-dot-2-design.md) § A | [plan](plans/2026-10-22-dot-2.md) | [#81](https://github.com/dangminhphuc/agent-workflow/pull/81), [#87](https://github.com/dangminhphuc/agent-workflow/pull/87), [#97](https://github.com/dangminhphuc/agent-workflow/pull/97) (đợt 19b), [#122](https://github.com/dangminhphuc/agent-workflow/pull/122) (đợt 19d); phần còn lại: [spec](specs/2026-10-23-sp19-gan-id-con-lai-design.md) |
| SP20 | Kiểm frontmatter `based_on` của artifact (INV-006) | 6 | xong | — | Sai dạng chặn mọi nơi; thiếu: cảnh báo trước review, chặn ở review | [spec](specs/2026-10-23-sp20-frontmatter-artifact-design.md) | | | [#94](https://github.com/dangminhphuc/agent-workflow/pull/94) |
| SP21 | CI chạy test trên macOS (BSD awk/sed) | 6 | xong | — | Còn: người bật job macOS thành check bắt buộc (cài đặt GitHub, máy không kiểm được) | [spec](specs/2026-10-23-sp21-ci-macos-design.md) | | | [#96](https://github.com/dangminhphuc/agent-workflow/pull/96), [#99](https://github.com/dangminhphuc/agent-workflow/pull/99) |
| SP22 | Số ADR không trùng khi hai việc song song | 6 | xong | — | `aw ship create` chặn khi trùng số | [spec](specs/2026-10-23-sp22-so-adr-song-song-design.md) | | | [#95](https://github.com/dangminhphuc/agent-workflow/pull/95) |
| SP23 | Dọn nhánh remote, số liệu roadmap | 6 | một phần | — | Số liệu test xong; còn xoá nhánh remote (~70 nhánh ngoài main, 2026-10-24), người duyệt danh sách trước khi xoá | [spec](specs/2026-10-23-sp23-don-dep-design.md) | | | [#90](https://github.com/dangminhphuc/agent-workflow/pull/90) (số liệu) |
| SP24 | Hai nhánh tính năng chưa merge: làn light + `mr_include_artifacts`, điểm mù nêu story/AC | sau | chặn | — | Lấy lại hay bỏ | | | |
| SP25 | Open question có mã riêng `Q-NNN` (bỏ lặp với spec.md) | sau | xong | — | Chốt 4 điểm ở spec § 7 (theo đề xuất) | [spec](specs/2026-10-23-sp25-open-question-ma-rieng-design.md) | — (người chọn bỏ plan) | [#92](https://github.com/dangminhphuc/agent-workflow/pull/92) |
| SP26 | Durable knowledge: truy xuất theo phạm vi ở implement, review | 7 | xong | — | Chốt: không thêm luật chặn mới ở implement; review chấm verdict đúng tập diff chạm | [spec](specs/2026-10-23-sp26-30-rag-markdown-design.md) § A | [plan](plans/2026-10-24-sp26-knowledge-implement-review.md) | [#93](https://github.com/dangminhphuc/agent-workflow/pull/93) |
| SP27 | Durable knowledge: chunk theo mục và khối ID | 7 | xong | SP26 | Chốt: neo heading nguyên văn, chỉ `##`; thêm 5 điểm (spec § B, 2026-10-25) | [spec](specs/2026-10-23-sp26-30-rag-markdown-design.md) § B | [plan](plans/2026-10-25-sp27-knowledge-theo-muc.md) | [#107](https://github.com/dangminhphuc/agent-workflow/pull/107) |
| SP28 | Durable knowledge: chỉ mục chung | 7 | xong | SP27 | Chốt: mặc định bật, kiểm khi file có; thêm: INV-013 (spec INV-012 bị SP35 chiếm id), Status `module` = `active`, `Summary` chứa `|` → `;` | [spec](specs/2026-10-23-sp26-30-rag-markdown-design.md) § C | [plan](plans/2026-10-27-sp28-knowledge-chi-muc.md) | [#116](https://github.com/dangminhphuc/agent-workflow/pull/116) |
| SP29 | Durable knowledge: tìm theo từ khoá | sau | chặn | SP28, số liệu SP9 | Có đáng làm không | [spec](specs/2026-10-23-sp26-30-rag-markdown-design.md) § D | | |
| SP30 | Durable knowledge: liên kết một bước, trích nguồn | sau | chặn | SP28, số liệu SP9 | Chốt: chỉ cảnh báo; chặn chờ số liệu SP9 | [spec](specs/2026-10-23-sp26-30-rag-markdown-design.md) § E | | |
| SP31 | Tên lệnh theo stage SDLC (`/aw-<stage>`, đánh số khớp stage) | sau | chặn | — | §5 của spec: phạm vi đổi tên, lệnh con duyệt, chuyển tiếp `plan`, dạng số | [spec](specs/2026-10-23-sp31-ten-lenh-theo-stage-design.md) | | |
| SP32 | `adapters/claude-code/exclude` hẹp lại (không loại cả `/.claude/`) | sau | xong | — | Chốt: exclude đúng tên file sinh ra; aw doctor cảnh báo dòng cũ | | | [#103](https://github.com/dangminhphuc/agent-workflow/pull/103) |
| SP33 | Nhãn nguồn cho URL issue GitHub / GitLab trong `aw input` | sau | xong | — | Chốt: nhãn mới `[ISSUE]`, không thêm khoá conventions | | | [#104](https://github.com/dangminhphuc/agent-workflow/pull/104) |
| SP34 | Phát hành các mảnh `changes/` đang tồn trước khi chạy SP9 | sau | xong | — | — | | | bản 2026.10.32 |
| SP35 | Viết artifact đúng dạng ngay lần đầu (bớt vòng sửa–`aw toc`) | sau | một phần | số liệu SP9 (đo token, REQ-006) | Chốt: INV-012 thay cho capability mới; đo sau | [spec](specs/2026-10-26-spec-dung-dang-lan-dau-design.md) | | [#109](https://github.com/dangminhphuc/agent-workflow/pull/109) |

Đợt 5 (kiểm nội dung) đi trước SP19 theo nguyên tắc 1. SP13 không chờ số liệu SP9: REQ diễn giải sai
nguồn là rủi ro đã biết (`docs/kien-truc.md` § Những chỗ thiết kế này yếu, mục 3), sai ở đây mọi phase
sau đều làm đúng một yêu cầu sai.

Đợt 7 (SP26–SP30, một spec chung vì cùng một bộ lọc `Scope`): durable knowledge của repo đích truy xuất
như RAG, vẫn tất định (không vector). SP26 đóng lỗ ở vòng chạy chính — việc bỏ design không bao giờ đọc
ADR — nên đi trước; SP29, SP30 thêm luật nên chờ số liệu SP9 (nguyên tắc 3).

## Chi tiết các dự án con chưa xong

### SP9 — Chạy thật + gom nhật ký

- Công cụ đã có: `aw journal export <file>`, `aw journal report <file>…`.
- Công cụ xong ở [SP9b](specs/2026-10-24-sp9b-journal-do-luong-design.md): cột version, `phases.tsv`, `aw journal retro` (`jobs.tsv`), report mới (độ chính xác checker, thời gian phase, việc theo loại, lỗi lọt, `--version`).
  Đã merge ở [#100](https://github.com/dangminhphuc/agent-workflow/pull/100).
  Còn lại: chạy thật trên 1–2 repo, người làm; SP10 chờ số liệu này.
- Còn lại (người làm): 1–2 repo đích, 2–4 tuần. Số liệu: việc theo loại, thời gian phase, số lần người
  can thiệp, checker chặn đúng / chặn nhầm.
- Kết quả: báo cáo ở `docs/` làm đầu vào SP10, SP17 và thứ tự các dự án con còn lại.

### SP10 — Đường tắt cho việc nhỏ

**Vấn đề.** Việc nhỏ nhất vẫn tốn: một phiên intake ở main checkout, rồi phiên mới cho spec, plan,
implement, một subagent review, (tuỳ chọn) ship; người can thiệp ít nhất ba lần (xác nhận intake, tick
spec, xác nhận review). `chore` chỉ bỏ được design (`kc_bo_design`, `tools/lib/cross-check.sh`);
bugfix/refactor bỏ design khi `Design: skip`. Sửa typo trong tài liệu, bump một dependency `patch` đều
đi đủ chuỗi. Rủi ro: người dùng bỏ quy trình với việc vặt, rồi bỏ luôn với việc lớn.

**Lựa chọn.**
- **A. Giữ nguyên**, ghi rõ trong `docs/huong-dan.md` khi nào **không** dùng `aw` (giống `spike`), và đo
  trước: bao nhiêu việc là `chore`/diff nhỏ.
- **B. `chore` gộp spec + plan một phiên**: `/aw-spec` của `chore` viết luôn `plan.md`; giữ cả hai
  artifact và hai checker, chỉ bớt một phiên.
- **C. Loại mới có giới hạn cứng** (vd diff ≤ N dòng, không đụng `production_code`, không đụng
  `sensitive_code`): bỏ spec, chỉ còn intake → implement → review. Máy kiểm được giới hạn, nhưng thêm
  một job type làm phân loại ở intake khó hơn.

**Đã làm (#81):** A — `docs/huong-dan.md` § 1.10 "Khi nào không dùng `aw`". B / C chờ số liệu SP9.

**Nghiêng về:** A trước (lấy số liệu SP9), rồi B nếu `chore` chiếm phần lớn. C đổi triết lý quy trình —
chỉ làm khi người chủ engine muốn.

### SP16 — `CAP-operate-02`: sự cố → việc mới

**Đã làm.** Intake nhận `[INCIDENT] <định danh>` (cùng dạng `[FILE]`). Bugfix được trỏ về sự cố gốc;
không bắt buộc — báo cáo của người không có mã sự cố vẫn là `[HUMAN]`.

**Chưa nhận capability.** `CAP-operate-02` thuộc stage `operate`. Phase `intake` implement stage `plan`;
một phase chỉ nhận capability của stage nó implement, và phase operate phải đứng sau ship. Sự cố là
đầu vào của việc mới, không phải bước sau ship. Capability giữ `human`, stage `operate` giữ `gap`.

### SP17 — Refactor/perf: không đổi assertion test cũ

**Vấn đề.** Máy chỉ chặn xoá test cũ và sửa không khai (INV-009); sửa assertion để test cũ qua vẫn lọt
tới review.

**Hướng.** So diff file test cũ với mẫu dòng assertion khai trong `conventions.md` (như mẫu bỏ qua test).
Mẫu theo ngôn ngữ dễ báo nhầm → cảnh báo ở implement, chặn ở review.

**Cần quyết.** Chỉ làm khi số liệu SP9 cho thấy lỗi này xảy ra thật (nguyên tắc 3).

### SP18 — Glob bước 2: `*` của `plan.md` không qua `/`

**Vấn đề.** SP8 thêm `**` và cảnh báo file chỉ khớp nhờ `*` vượt thư mục (`kc_glob_chuyen_tiep`); `*`
vẫn khớp qua `/` (`kien-truc.md` điểm yếu 9).

**Hướng.** `kc_pham_vi`, `tk_pham_vi`, `kc_glob_rong` khớp bằng `khop_duong` (`tools/lib/md.sh`), bỏ cảnh
báo chuyển tiếp. Glob của `conventions.md` giữ nghĩa cũ (spec SP8).

**Cần quyết.** Luật `BR-` đã nâng mang mẫu nghĩa cũ (suy từ `Expected files` lúc `aw rule promote`, khớp ở
`tools/lib/knowledge.sh`): cảnh báo hay chuyển đổi khi đọc. Chỉ làm sau khi bản có cảnh báo chuyển tiếp
đã phát hành và người dùng có thời gian sửa plan.

### SP19 — Bước A đợt 2

**Vấn đề.** SP12 gắn `# giữ: CAP-…/INV-…` cho 41 chỗ; `check-sdlc.sh` chặn id không có và capability
`machine` được nhận mà không luật nào khai. Còn nhiều chỗ chặn/cảnh báo chưa có id (`tools/unclassified-rules.txt`, nay 126), `Category` của
`workflow/checkers/*.md` chưa gắn, luật mồ côi chưa bị chặn, dòng "Interface: …" trong PR vẫn khai tay.

**Đã làm (#81):** luật mới phải gắn `# giữ:` — `tools/unclassified-rules.txt` đếm chỗ luật chưa gắn
của từng file (223 chỗ), chỉ được giảm; mỗi `# giữ:` phủ đúng một chỗ luật ngay dưới.

**Hướng (phần còn lại).** Gắn id cho chỗ còn lại (hạ dần danh sách) và mọi `Category`; đếm cả luật trong
`tools/lib/`. Không gắn hàng loạt: id có thật vẫn qua máy dù gắn nhầm capability.

**Đã làm thêm.** `sh tools/check-sdlc.sh --suy <file>…` in các id `# giữ:` trong những file đó (đưa
danh sách file của diff). Id không có thì chặn. Không tự viết `# giữ:`.

**Spec phần còn lại:** [2026-10-23-sp19-gan-id-con-lai-design.md](specs/2026-10-23-sp19-gan-id-con-lai-design.md)
(chia đợt 19b–19g, mỗi đợt một PR).

**Đợt 19b:** gắn 37 chỗ (`check-intake`, `check-security`, `check-ship`, `check-conventions`, `task.sh`;
223 → 186, [#97](https://github.com/dangminhphuc/agent-workflow/pull/97); đếm lại 2026-10-24: 185). 23 chỗ còn lại của các file đó không khớp id nào — chờ người duyệt capability mới (mô tả PR
đợt 19b): khoá engine ghim (`Engine:`), `Goal:` của intake, mục lục (`toc_loi`), hình thức
`conventions.md` (khoá bắt buộc, thư mục tri thức, `worktree_dir`, regex), WIP=1 và dừng sau N lần đỏ
của `aw task`, tiêu đề MR (độ dài, mã Jira).

**Đợt 19c:** gắn 59/60 chỗ của `check-spec.sh` (185 → 126, [#118](https://github.com/dangminhphuc/agent-workflow/pull/118); một chỗ `kc_quy_tac_loi` chờ người duyệt capability mới — file `rules_*`/`uses_*` khai ở conventions phải có, mẫu chung của mọi checker). `toc_loi` gắn được INV-012 (mục lục trong danh sách "chờ capability mới" của 19b nay hết cần — INV-012 có từ SP35/#109). INV-005 `Enforced by` thêm `check-spec.sh` (entry check).

**Đợt 19d:** gắn 45/50 chỗ của `check-plan.sh` + `check-design.sh` (126 → 81; `check-plan` còn 2, `check-design` còn 3, [#122](https://github.com/dangminhphuc/agent-workflow/pull/122)). Năm chỗ chờ người duyệt capability mới: `kc_quy_tac_loi` (đã nêu ở 19c, nay gặp ở hai file nữa), `luat_loi_ke_hoach` (REQ `Promote:` phải có task nâng), `adr_loi_truong` (trường Promote/Scope/Supersedes của DEC), và luật Mode 2 (`Risk: high` đòi DEC `Author: human`) — không id nào trong `sdlc/` mô tả những việc này. `adr_loi_ke_hoach` (DEC `Promote: adr` phải có task nâng ở plan) không phải chờ: nó gắn được CAP-breakdown-02, bản sửa 2026-10-29.

**Đợt 19e:** gắn 31/52 chỗ của `check-implement.sh` + `check-review.sh` (81 → 58; `check-implement` còn 5, `check-review` còn 16). Ba chỗ mang list id: chỗ in gộp output của nhiều helper (`cb` ở cả hai checker) và chỗ gọi helper phân theo loại việc (`kc_chan_theo_loai`). `kt_canh_bao` phải tách khỏi khối gộp của `check-implement.sh`: `check-sdlc.sh`
đếm id theo chuỗi nên để nó trong list gộp thì CAP-verify-06 vẫn được khai dù chú thích riêng đã bị
test gỡ bỏ. Chín luật chưa gắn chờ capability mới: `kc_dau_xung_dot` (dấu xung đột merge còn trong file thay đổi), `adr_loi_viec` + `luat_loi_viec` (ADR và file luật phải khớp nội dung DEC/REQ đã duyệt), `kc_tu_dich`, `kc_quy_tac_loi` (gặp ở hai file nữa), bảng "## Repo rules", bảng Lens 4 — Security, cấu trúc finding Lens 3, `kc_base_la`.

### SP24 — Hai nhánh tính năng chưa merge

**Vấn đề.** Hai nhánh không có PR, tính năng chưa có trên `main`, rẽ từ `main` cũ (12–13/10):
`claude/light-lane-mr-artifacts` — bugfix `Lane: light` bỏ design, `light_lane_max_files`, và
`mr_include_artifacts` đính `spec.md`/`tdd.md` vào mô tả MR (chữa `kien-truc.md` điểm yếu 10);
`claude/tender-mccarthy-3fxmrt` — mỗi điểm mù trong `open-questions.md` bắt buộc `User story:` và
`Acceptance criteria:`.

**Hướng.** Lấy lại thì làm lại trên `main` hiện tại (không merge thẳng), mỗi phần một dự án con. Làn light
trùng phương án C của SP10 — xét cùng SP10 khi có số liệu SP9. `mr_include_artifacts` và điểm mù story/AC
độc lập, làm được ngay.

**Cần quyết.** Lấy phần nào, bỏ phần nào; bỏ thì xoá nhánh (SP23).

### SP26–SP30 — Durable knowledge như RAG

**Vấn đề.** `aw knowledge` chỉ chạy ở spec và design, lấy cả file; `chore` và việc `Design: skip` không
đọc ADR nào; kiến thức không gắn đường dẫn chỉ tìm được bằng cách đọc hết.

**Hướng.** Spec [`2026-10-23-sp26-30-rag-markdown-design.md`](specs/2026-10-23-sp26-30-rag-markdown-design.md):
A truy xuất theo `Expected files` / diff ở implement, review; B ref `<file>#<neo>` và `Scope` theo mục;
C chỉ mục `docs/knowledge-index.md` máy dựng, lệch thì chặn; D `aw knowledge find`; E theo liên kết một
bước và bảng `## Knowledge used`.

**Đã chốt (2026-10-24).** Spec đã duyệt, mọi phương án "Nghiêng về" được chọn (spec ghi ở từng mục **Đã chốt**).

**Tiến độ.** SP26 xong ở [#93](https://github.com/dangminhphuc/agent-workflow/pull/93) (`aw knowledge implement` / `review`), SP27 ở [#107](https://github.com/dangminhphuc/agent-workflow/pull/107) (ref `<file>#<neo>`, `aw knowledge show`), SP28 ở [#116](https://github.com/dangminhphuc/agent-workflow/pull/116) (chỉ mục chung `docs/knowledge-index.md`, `aw knowledge index`/`check`). SP29–SP30 còn lại.

### SP31 — Tên lệnh theo stage SDLC

**Vấn đề.** 4/7 lệnh phase khác tên stage nó làm; `/aw-plan` làm stage `breakdown` còn stage `plan`
do `/aw-intake` làm. Summary đếm "Bước x/6" lệch số stage `00`–`07`.

**Hướng (người đã chốt).** Lệnh `/aw-<stage>`; deploy vẫn tuỳ chọn; lệnh con (nếu có) dùng `-`, không
dùng `:`; số phase lấy từ stage, `check-sdlc.sh` chặn khi lệch. Chi tiết: spec SP31.

**Cần quyết.** Spec § 5: đổi tên tới `aw check`/`aw ship` không; lệnh con duyệt hay tham số
`/aw-approvals <stage>`; chuyển tiếp chữ `plan` đổi nghĩa; dạng số trong summary.

### SP35 — Viết artifact đúng dạng ngay lần đầu

**Vấn đề.** Phase spec viết artifact trước khi đọc kỹ template, rồi dò dạng bằng `aw toc`
3–4 lượt, có khi sửa link bằng `sed` — gấp 2–3 lần token cần thiết.

**Hướng (đã làm, đợt 1).** `INV-012`: một lượt `aw toc` là xong — máy mở rộng lại anchor theo mã
khi heading đổi chữ, lỗi dạng in kèm file, số dòng và dạng đúng, mọi lỗi in cùng một lượt; phase
body và lệnh sinh ra bắt agent chép khung template trước khi viết, `aw toc` chạy một lần ở cuối
(xem `docs/kien-truc.md` § Mục lục và link tới mục).

**Còn lại (REQ-006, chờ số liệu SP9).** Đếm số lần gọi `aw toc` trong một phiên spec vào journal và
so token trước/sau trên cùng bộ feature mẫu — mục tiêu ≤ 1/3, ít nhất ≤ 1/2. Cùng mẫu này có thể áp
cho phase design, plan (dự án con riêng khi có số liệu).

## Việc nhỏ (không thành dự án con)

Đụng phần nào thì làm phần đó, không cần spec:

- **`check-sdlc.sh` còn ~0,55 giây** (trước ~1,1 giây). `cap_co`, id invariant, phase theo stage,
  `skippable: false` và requires của stage tra chuỗi tính một lần; #119 gộp kiểm invariant, đếm luật
  chưa gắn và frontmatter phase (~0,9 s); PR này gộp tiếp bảng stage ↔ phase và vòng profile
  (`kc_bo_design` source một lần cho mọi job type, `fm_all` trong `tools/lib/md.sh` đọc mọi khoá
  frontmatter một lượt, tra bảng bằng chuỗi thay `$(grep …)`). Đo cặp trên cùng máy, 2026-10-28.
  Phần còn lại dàn trải: kiểm tập con YAML từng file, đọc frontmatter + capability từng file stage,
  quét `# giữ:` và khối `out_of_scope`.
- Bộ test (đo trên CI ở [#122](https://github.com/dangminhphuc/agent-workflow/pull/122), 2026-10-28):
  2136 ca, ALL PASS trên cả hai hệ — Ubuntu 3 phút 42 giây (4 luồng), macOS 11 phút 35 giây (3 luồng).
  Phần dài nhất trên macOS: `05-review-quality` 102 s, `06-review-freshness` 101 s,
  `15-conventions-task` 100 s. Trên máy phát triển (WSL2, 6 luồng): 3 phút 44 giây. Mục tiêu dưới 3 phút
  chỉ đạt trên Ubuntu; tách phần khi `run-tests.sh` in `WARN … nên tách` (cảnh báo này cũng bật khi máy
  bị chiếm CPU, nên đo lúc máy nhàn — một lần đo `28-knowledge-sections` 108 s rồi 46 s trên cùng code).
  (Lần đo cũ 2026-10-24: 1963 ca, 5 phút 23 giây trên 4 luồng, `main` dac429d.)

- ~~`aw input` chưa nhận `[ISSUE]` cho work item GitLab (`…/-/work_items/N`), discussion GitHub, Bitbucket, Gitea~~ —
  work item GitLab xong trước đó; discussion GitHub, Gitea/Forgejo, Bitbucket Cloud và Data Center xong
  2026-10-27 (PR hiện hành), kèm checker intake/spec và test.

## Không làm

| Việc | Lý do | Xét lại khi |
|---|---|---|
| Tách version / repo của interface SDLC | Chỉ có một implementation; tách chỉ thêm việc đồng bộ (`kien-truc.md` § Interface SDLC) | Có implementation thứ hai |
| Release, triển khai, quan sát production (`CAP-deploy-02`, `CAP-operate-01`) | Pipeline và observability của repo đích; đã khai `out_of_scope` (SP5) | — |
| Xếp ưu tiên, ước lượng, nghiệm thu (`CAP-plan-03`, `CAP-plan-04`, `CAP-verify-05`) | Việc của người hoặc của repo đích; đã khai `out_of_scope` (SP15). `CAP-deploy-03` giữ trên roadmap: engine ghi được đường rollback | — |
| Refactor "không thêm hành vi" ở mức code | Chưa có cách máy kiểm đáng tin; giữ ở mức spec (REQ `preserve`/`structural`, INV-008) và để review/người phán | Có cách kiểm không báo nhầm |
| Đổi tên phase `03-plan` (stage `breakdown`) ↔ stage `plan` | Chạm test, docs, lệnh sinh ra; `docs/thuat-ngu.md` (mục `stage`) đã giải thích | Người dùng nhầm thật |
| Embedding / vector DB cho durable knowledge | Kết quả theo độ tương đồng không lặp lại được: checker không kiểm được "đọc đúng tài liệu", cross-check stale và verdict review mất chỗ bám (spec SP20–SP24 § 0) | Có cách truy xuất tất định không đủ, đo được bằng số liệu SP9 |
| Adapter thứ ba (`codex`, `copilot`) | SP11 đã gỡ `planned`; thêm khi có người dùng thật cần (`adapters/README.md`) | Có người dùng |
