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
| SP9 | Chạy thật + gom nhật ký | 4 | một phần | SP3, SP4 | Chạy thật: người làm | [spec](specs/2026-10-22-sp9-11-12-design.md) (chỉ công cụ) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) (công cụ) |
| SP10 | Đường tắt cho việc nhỏ | 4 | một phần | số liệu SP9 | A xong (#81); B / C chờ số liệu SP9 | [spec](specs/2026-10-22-dot-2-design.md) § B | [plan](plans/2026-10-22-dot-2.md) | [#81](https://github.com/dangminhphuc/agent-workflow/pull/81) |
| SP11 | Gỡ adapter `planned` | 4 | xong | — | Chốt: gỡ planned | [spec](specs/2026-10-22-sp9-11-12-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP12 | Bước A đợt 1 — gắn luật checker vào CAP/INV | sau | xong | SP1, SP2 | — | [spec](specs/2026-10-22-sp9-11-12-design.md) | [plan](plans/2026-10-22-sp2-sp12.md) | [#79](https://github.com/dangminhphuc/agent-workflow/pull/79) |
| SP13 | Checker LLM cho spec | 5 | chờ | — | Đọc lại nguồn hay chỉ `Quote`; chặn ở đâu | | | |
| SP14 | Bugfix: test tái hiện xanh sau khi sửa | 5 | chờ | — | Chặn hay cảnh báo | | | |
| SP15 | `out_of_scope` cho capability `plan`/`verify`/`deploy` engine không định làm | 5 | chờ | — | Chốt danh sách id | | | |
| SP16 | `CAP-operate-02`: sự cố → việc mới | 5 | chờ | — | Cách ghi nguồn | | | |
| SP17 | Refactor/perf: không đổi assertion test cũ | sau | chặn | số liệu SP9 | Có đáng làm không | | | |
| SP18 | Glob bước 2: `*` của `plan.md` không qua `/` | sau | chặn | SP8 đã phát hành | Luật `BR-` cũ: cảnh báo hay chuyển đổi | | | |
| SP19 | Bước A đợt 2 — luật mồ côi, suy CAP/INV từ diff | sau | một phần | SP13 | Chặn luật mới không id xong (#81); còn: gắn luật cũ, `Category`, `tools/lib/`, suy từ diff — chia mấy PR | [spec](specs/2026-10-22-dot-2-design.md) § A | [plan](plans/2026-10-22-dot-2.md) | [#81](https://github.com/dangminhphuc/agent-workflow/pull/81) (một phần) |

Đợt 5 (kiểm nội dung) đi trước SP19 theo nguyên tắc 1. SP13 không chờ số liệu SP9: REQ diễn giải sai
nguồn là rủi ro đã biết (`docs/kien-truc.md` § Những chỗ thiết kế này yếu, mục 3), sai ở đây mọi phase
sau đều làm đúng một yêu cầu sai.

## Chi tiết các dự án con chưa xong

### SP9 — Chạy thật + gom nhật ký

- Công cụ đã có: `aw journal export <file>`, `aw journal report <file>…`.
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

### SP13 — Checker LLM cho spec: REQ có đọc đúng câu trích không

**Vấn đề.** `aw check spec` chỉ kiểm hình thức: câu trích `[FILE]` có thật trong nguồn
(`tools/lib/quote.sh`), REQ có nhãn nguồn, có tiêu chí. Nó không biết `Description` và các `- [ ]` có nói
**đúng, đủ, không thừa** so với `Quote` không. Phase design có checker LLM (`workflow/checkers/design.md`),
phase spec thì không.

**Hạ tầng đã có.**
- Frontmatter `llm_checker:` → adapter sinh subagent `<tên>-checker` và chèn lời dặn gọi nó
  (`adapters/lib/common.sh`: `ten_agent_checker`). Thêm checker = thêm file + một dòng frontmatter.
- Đọc finding dùng chung: `tools/lib/findings.sh` (`Severity`, `Category`, `Location`, `Problem`,
  `Resolution`).
- `tools/pending.sh` khoá finding theo `file:FND-NNN` — hai checker trùng số `FND` không lẫn.

**Chỗ còn gắn cứng `design-findings.md`** (tổng quát hoá hoặc thêm nhánh): `tools/check-design.sh`,
`tools/approval.sh` (chỉ hiện finding cho DEC), `tools/pending.sh` (bảng `ph_chan` tĩnh, mà phase bị chặn
bởi finding của spec là `design` **hoặc** `plan` khi `Design: skip`/`chore`), `tools/lib/toc.sh`
(`TOC_ART`), `adapters/cursor/README.md`.

**Hướng (đề xuất).**
1. `workflow/checkers/spec.md`, đọc `intake.md`, `spec.md`, `open-questions.md`, ghi `spec-findings.md`.
   Cùng luật với checker design: chỉ được chặn, không được duyệt; ngữ cảnh trắng; chạy lại thì ghi đè;
   không có gì vẫn ghi file với một dòng `No blocking findings.`.
2. Bảng `Category`:

   | `Category` | Nghĩa | `Severity` |
   |---|---|---|
   | `quote-misread` | `Description`/tiêu chí nói điều `Quote` không nói, hoặc ngược với `Quote` | `block` |
   | `added-scope` | Tiêu chí, giới hạn, số liệu không có trong `Quote` hay nguồn nào | `block` |
   | `dropped-condition` | `Quote` có điều kiện / ngoại lệ / giới hạn mà tiêu chí bỏ mất | `block` |
   | `unflagged-ambiguity` | `Quote` đọc được nhiều cách, REQ chọn một mà không có `[OPEN-QUESTION]` | `block` |
   | `unsourced-priority` | `should` mà câu nguồn không nói "nice to have", "phase 2"… | `block` |
   | `inferred-business-decision` | `[INFERRED]` trên quyết định nghiệp vụ | `block` |
   | `merged-requirements` | Một REQ gộp hai yêu cầu kiểm chứng độc lập | `warn` |
   | `unobservable-criterion` | Tiêu chí không quan sát được từ ngoài ("phải nhanh") | `warn` |
   | `nfr-unasked` | Việc đụng nhóm NFR (`01-spec.md` bước 5) mà không có REQ hay open question | `warn` |
   | `risk-understated` | Đụng tiền/kế toán, schema lõi, tích hợp mới mà `Risk: normal` | `warn` |

3. `aw check spec` chặn khi chưa có `spec-findings.md` hoặc còn `block` chưa `fixed`/`rejected: <lý do>`
   — giống `check-design`. Người phân xử qua `/aw-clarify` trước khi tick "Approved by human";
   `aw approvals` hiện finding của spec cạnh ô duyệt spec.
4. Tương thích: việc đã ghim engine cũ không bị ảnh hưởng; việc mới phải có `spec-findings.md`
   (`changes/` mục `Thay đổi`).
5. Chi phí: thêm một subagent mỗi lần `/aw-spec` — chấp nhận được vì spec chạy ít lần và sai ở đây đắt nhất.

**Cần quyết.** Đọc lại nguồn? Đọc lại `[FILE]` thì rẻ; `[JIRA]`/`[CONFLUENCE]` cần MCP và tốn ngữ cảnh.
Đề xuất bản đầu chỉ so `spec.md` với `Quote` và lời `[HUMAN]` trong `intake.md` (đủ cho 6 loại `block`);
`missed-requirement` (câu nguồn có "phải/must" mà không REQ nào trích) để bản sau.

**Test.** `02-spec-design-plan.sh` (thiếu file, `block` `open`, `rejected:` không lý do → chặn; `fixed`,
`rejected: <lý do>`, chỉ `warn` → ĐẠT); `11-design-skip-refactor.sh` (`Design: skip` → finding spec chặn
`plan`); `08-adapters.sh` (subagent `spec-checker`, `AW_COMPARE=1`); `01-fixture-engine-toc.sh`
(`aw toc` nhận `spec-findings.md`).

**Tài liệu.** `01-spec.md`, `docs/kien-truc.md` § LLM checker + điểm yếu 3, `docs/huong-dan.md` § Phase 01
+ § 4 Bản đồ artifact, `adapters/cursor/README.md`.

### SP14 — Bugfix: test tái hiện xanh sau khi sửa

**Vấn đề.** INV-007 chỉ giữ "test tái hiện đỏ trên code chưa sửa" (`aw check repro`). Máy không biết test
đỏ **vì đúng bug**: lỗi biên dịch, test khác đang hỏng sẵn cũng đỏ. Hiện chỉ review phán (`Repro test fails
because:` trong `review.md`).

**Hướng.** Đòi đúng test đã đỏ trong `repro.md` phải xanh sau khi sửa — lỗi biên dịch hay test hỏng sẵn
không tự xanh nhờ bản sửa. Kiểm trước: `repro.md` hiện ghi output của cả `TEST_CMD`, có tách được tên
test đỏ không; `test-results.md` xanh toàn bộ đã ngầm đòi điều này tới đâu.

**Cần quyết.** Chặn hay cảnh báo (nhận diện tên test theo ngôn ngữ dễ báo nhầm → cảnh báo ở implement,
chặn ở review). Máy giữ được thì thêm invariant hoặc nới INV-007 (`interface-sdlc.md` § 4.1).

### SP15 — `out_of_scope` cho capability engine không định làm

**Vấn đề.** `check-sdlc.sh` còn in là "còn thiếu" những capability nằm ngoài hướng engine: engine chỉ nhận
việc đã có, không ưu tiên hay ước lượng giữa các việc (`CAP-plan-03`, `CAP-plan-04`); UAT
(`CAP-verify-05`) và đường rollback (`CAP-deploy-03`) thuộc quy trình của repo đích. Bảng "còn thiếu"
lẫn việc sẽ làm với việc không làm.

**Hướng.** Khai từng id trong `out_of_scope:` của `workflow.yaml` kèm lý do (cơ chế SP5). Làm yếu
interface → id + lý do dưới `### Bỏ` của `changes/<branch>.md`.

**Cần quyết.** Danh sách id. `CAP-deploy-03` có thể giữ: engine ghi được đường rollback trong
`merge-request.md` như một mục người điền.

### SP16 — `CAP-operate-02`: sự cố → việc mới

**Vấn đề.** Stage `operate` là `gap`. Phần engine làm được: intake nhận incident / postmortem làm `input`
của job mới.

**Hướng.** `source label` riêng cho incident; job type `bugfix` dẫn được về sự cố gốc.

**Cần quyết.** Cách ghi nguồn (nhãn mới hay `[FILE]`/`[JIRA]` sẵn có cộng một trường), trước khi code.

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
`machine` được nhận mà không luật nào khai. Còn ~200 chỗ chặn/cảnh báo chưa có id, `Category` của
`workflow/checkers/*.md` chưa gắn, luật mồ côi chưa bị chặn, dòng "Interface: …" trong PR vẫn khai tay.

**Đã làm (#81):** luật mới phải gắn `# giữ:` — `tools/unclassified-rules.txt` đếm chỗ luật chưa gắn
của từng file (223 chỗ), chỉ được giảm; mỗi `# giữ:` phủ đúng một chỗ luật ngay dưới.

**Hướng (phần còn lại).** Gắn id cho chỗ còn lại (hạ dần danh sách) và mọi `Category`; đếm cả luật trong
`tools/lib/`; suy "diff chạm CAP/INV nào" từ file thay đổi.

**Cần quyết.** Chia mấy PR. Làm sau SP13 để `Category` của checker spec mang id ngay.

## Việc nhỏ (không thành dự án con)

Đụng phần nào thì làm phần đó, không cần spec:

- **2 cặp "…đúng lý do" còn kiểm hai thông báo** — `ky_vong_ly_do` chỉ nhận một mẫu. Mục lục vừa thiếu mục
  mới vừa thừa link cũ (`01-fixture-engine-toc.sh`, chạy checker hai lần) và cả hai file kết quả lỗi thời
  (`06-review-freshness.sh`, chạy một lần). Các cặp một thông báo đã chuyển.
- **`check-sdlc.sh` ~1,6 giây mỗi lần** (trước ~2 giây). `cap_co`, `cap_stage`, id invariant, phase theo
  stage, `skippable: false` và requires của stage tra chuỗi tính một lần. Phần còn lại là đọc frontmatter
  từng file và quét `# giữ:`.
- Bộ test trên máy này: 1775 ca, mọi ca đạt, khoảng 5 phút trên 6 luồng. Mục tiêu dưới 3 phút chưa đạt.
  Phần dài nhất `21-sdlc-profiles` (103 giây), rồi `05-review-quality`, `08-adapters`, `23-sdlc-syntax` —
  chưa tới ngưỡng cảnh báo nên tách. Số 3 phút 45 giây sau #81 đo trên 4 luồng, máy khác, không so trực tiếp.

## Không làm

| Việc | Lý do | Xét lại khi |
|---|---|---|
| Tách version / repo của interface SDLC | Chỉ có một implementation; tách chỉ thêm việc đồng bộ (`kien-truc.md` § Interface SDLC) | Có implementation thứ hai |
| Release, triển khai, quan sát production (`CAP-deploy-02`, `CAP-operate-01`) | Pipeline và observability của repo đích; đã khai `out_of_scope` (SP5) | — |
| Refactor "không thêm hành vi" ở mức code | Chưa có cách máy kiểm đáng tin; giữ ở mức spec (REQ `preserve`/`structural`, INV-008) và để review/người phán | Có cách kiểm không báo nhầm |
| Đổi tên phase `03-plan` (stage `breakdown`) ↔ stage `plan` | Chạm test, docs, lệnh sinh ra; `docs/thuat-ngu.md` (mục `stage`) đã giải thích | Người dùng nhầm thật |
| Adapter thứ ba (`codex`, `copilot`) | SP11 đã gỡ `planned`; thêm khi có người dùng thật cần (`adapters/README.md`) | Có người dùng |
