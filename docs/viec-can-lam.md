# Việc cần làm

> Ghi chú tạm cho người phát triển engine, không phải tài liệu dùng. Việc đã làm xem `CHANGELOG.md`.
> Xoá file này khi các mục dưới đã xong hoặc đã quyết định bỏ.
>
> Các mục ở § Đánh giá các phase đến từ một lượt đánh giá (10/2026). Mỗi mục là **đề xuất**: đổi
> luật nên theo `AGENTS.md` § Making a change, người duyệt cách làm (file đụng tới, chặn hay
> cảnh báo, test chứng minh gì) trước khi code. Thứ tự mục = thứ tự nên làm.
>
> Thứ tự làm và cách chia thành dự án con (spec → plan → PR theo luồng Superpowers):
> [`superpowers/2026-10-22-roadmap-cai-thien.md`](superpowers/2026-10-22-roadmap-cai-thien.md).
> Chi tiết vấn đề vẫn nằm ở các mục dưới; roadmap chỉ trỏ tới.

## Đánh giá các phase (10/2026)

### 3. Checker LLM cho spec: REQ có đọc đúng câu trích không

**Vấn đề.** Chỗ dễ sai nhất của cả quy trình là REQ diễn giải sai nguồn — và chưa máy nào chạm tới.
`aw check spec` chỉ kiểm hình thức: câu trích `[FILE]` có thật trong nguồn (`tools/lib/quote.sh`), REQ
có nhãn nguồn, có tiêu chí. Nó không biết `Description` và các `- [ ]` có nói **đúng, đủ, không thừa**
so với `Quote` không (`docs/kien-truc.md` § Những chỗ thiết kế này yếu, mục 3). Phase design có checker
LLM (`workflow/checkers/design.md`), phase spec thì không — trong khi sai ở spec thì design, plan,
implement, review đều làm đúng một yêu cầu sai.

**Hạ tầng đã có.**
- Frontmatter `llm_checker:` → adapter sinh subagent `<tên>-checker` và chèn lời dặn gọi nó
  (`adapters/lib/common.sh`: `ten_agent_checker` quanh dòng 355, lời dặn quanh dòng 423, sinh subagent
  quanh dòng 519). Thêm checker = thêm file + một dòng frontmatter.
- Đọc finding dùng chung: `tools/lib/findings.sh` (`Severity`, `Category`, `Location`, `Problem`,
  `Resolution`).
- `tools/pending.sh` đã khoá finding theo `file:FND-NNN` (hai checker trùng số không lẫn) — mục
  "`FND` trùng giữa nhiều checker LLM" bên dưới đã xong phần này.

**Chỗ còn gắn cứng `design-findings.md`** (phải tổng quát hoá hoặc thêm nhánh): `tools/check-design.sh`
(quanh dòng 45), `tools/approval.sh` (quanh dòng 131, chỉ hiện finding cho DEC), `tools/pending.sh`
(bảng `ph_chan`, quanh dòng 138 — tĩnh, mà phase bị chặn bởi finding của spec là `design` **hoặc**
`plan` khi `Design: skip`/`chore`), `tools/lib/toc.sh:19` (`TOC_ART`), `adapters/cursor/README.md`.

**Đề xuất (cần duyệt).**

1. `workflow/checkers/spec.md`, đọc `intake.md`, `spec.md`, `open-questions.md`, ghi `spec-findings.md`.
   Cùng luật với checker design: **chỉ được chặn, không được duyệt**; ngữ cảnh trắng; chạy lại thì ghi
   đè; không có gì vẫn ghi file với một dòng `No blocking findings.`.
2. Bảng `Category` đề xuất:

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
   | `risk-understated` | Đụng tiền/kế toán, schema lõi, tích hợp mới mà `Risk: normal` | `warn` (bổ sung cho cảnh báo `high_risk_keywords`) |

3. **Có đọc lại nguồn không?** Đọc lại `[FILE]` thì rẻ; `[JIRA]`/`[CONFLUENCE]` cần MCP và tốn ngữ
   cảnh. Đề xuất bản đầu chỉ so `spec.md` với `Quote` và lời `[HUMAN]` trong `intake.md` (đủ cho 6 loại
   `block`); loại `missed-requirement` (câu nguồn có "phải/must" mà không REQ nào trích) để bản sau.
   Cần quyết.
4. **Chỗ chặn.** `aw check spec` chặn khi chưa có `spec-findings.md` hoặc còn `block` chưa
   `fixed`/`rejected: <lý do>` — giống `check-design`. Người phân xử qua `/aw-clarify` **trước** khi tick
   "Approved by human". `aw approvals` hiện finding của spec cạnh ô duyệt spec.
5. **Tương thích.** Việc đã ghim engine cũ trong `intake.md` không bị ảnh hưởng. Việc mới chạy engine
   mới phải có `spec-findings.md` — ghi rõ trong `CHANGELOG.md` mục `Thay đổi`.
6. **Chi phí.** Thêm một subagent mỗi lần `/aw-spec`. Chấp nhận được vì spec chạy ít lần và sai ở đây
   đắt nhất.

**Test.**
- `tools/tests/02-spec-design-plan.sh`: thiếu `spec-findings.md` → chặn; còn `block` `open` → chặn;
  `rejected:` không lý do → chặn; `rejected: <lý do>` và `fixed` → ĐẠT; chỉ còn `warn` → ĐẠT.
- `tools/tests/11-design-skip-refactor.sh`: `Design: skip` → finding `block` của spec chặn `plan`
  (kiểm `pending.sh` xếp đúng phase).
- `tools/tests/08-adapters.sh`: subagent `spec-checker` được sinh cho Claude Code và Cursor;
  `AW_COMPARE=1` vẫn byte-identical.
- `tools/tests/01-fixture-engine-toc.sh`: `aw toc` nhận `spec-findings.md`.

**Tài liệu.** `01-spec.md` (bước chạy checker, không nhắc lại nội dung checker), `docs/kien-truc.md`
§ LLM checker + mục 3 của § Những chỗ yếu, `docs/huong-dan.md` § Phase 01 + § 4 Bản đồ artifact,
`adapters/cursor/README.md`, `CHANGELOG.md` (`Thêm`).

### 4. Đường tắt cho việc rất nhỏ — cần quyết định, chưa đề xuất code

**Vấn đề.** Việc nhỏ nhất vẫn tốn: một phiên intake ở main checkout, rồi phiên mới cho spec, plan,
implement, một subagent review, (tuỳ chọn) ship; người can thiệp ít nhất ba lần (xác nhận intake, tick
spec, xác nhận review). `chore` chỉ bỏ được design (`kc_bo_design`, `tools/lib/cross-check.sh`);
bugfix/refactor bỏ design khi `Design: skip`. Sửa typo trong tài liệu, bump một dependency `patch` đều
đi đủ chuỗi. Rủi ro: người dùng bỏ quy trình với việc vặt, rồi bỏ luôn với việc lớn.

**Lựa chọn.**
- **A. Giữ nguyên**, ghi rõ trong `docs/huong-dan.md` khi nào **không** dùng `aw` (giống `spike`), và đo
  trước: bao nhiêu việc là `chore`/diff nhỏ (`aw journal` hoặc đếm worktree đã dọn).
- **B. `chore` gộp spec + plan một phiên**: `/aw-spec` của `chore` viết luôn `plan.md`; giữ cả hai
  artifact và hai checker, chỉ bớt một phiên. Đi ngược "mỗi phase chạy được từ fresh session" ít nhất
  vì artifact vẫn đủ.
- **C. Loại mới có giới hạn cứng** (vd diff ≤ N dòng, không đụng `production_code`, không đụng
  `sensitive_code`): bỏ spec, chỉ còn intake → implement → review. Máy kiểm được giới hạn, nhưng thêm
  một job type làm phân loại ở intake khó hơn.

**Nghiêng về:** A trước (lấy số liệu), rồi B nếu số liệu cho thấy `chore` chiếm phần lớn. C đổi triết lý
quy trình — chỉ làm khi người chủ engine muốn.

## Mã định danh (sau khi đổi sang `REQ`/`DEC`/`FND`/`TSK`/`RFR`)

- **`FND` trùng giữa nhiều checker LLM** — chưa xảy ra (mới có checker design). `pending.sh` đã ghép
  tên file (`design-findings.md:FND-001`) để phân biệt; các chỗ còn gắn cứng `design-findings.md` liệt
  kê ở § Đánh giá các phase, mục 3.

## Tốc độ test (sau SP6)

- **Còn ~44 cặp "…đúng lý do" chạy checker hai lần** — mẫu grep có `\"`, `$`, `\\` nên không chuyển tự động
  được; chuyển tay sang `ky_vong_ly_do` (`tools/tests/lib.sh`) khi đụng tới phần đó.
- **`check-sdlc.sh` ~1,8 giây mỗi lần, ~650 lần gọi `awk`** (phần lớn ở ma trận profile: `luon_co`, `la_gap`,
  `kieu` mỗi lần một awk). Bốn phần test SDLC chạy nó mỗi ca. Gom dữ liệu profile vào biến shell một lần
  như `SO_STAGE` sẽ bớt nhiều nhất.
- Bộ test sau SP6: ~4 phút 30 giây thực trên 4 luồng (1725 ca; trước: 5 phút /
  13 phút CPU cho 1641 ca). Mục tiêu dưới 3 phút chưa đạt — phần dài nhất ~75 giây (`22-sdlc-stage-files`).

## Interface SDLC (sau khi thêm `sdlc/`)

- **Tách version / repo của interface** khi có implementation thứ hai (engine khác, hay quy trình làm
  tay khai tuân thủ). Lúc đó `sdlc/` có version riêng và engine khai version interface nó tuân thủ;
  hiện chung repo, chung version vì chỉ có một implementation (`docs/kien-truc.md` § Interface SDLC).
- **Lấp các capability còn thiếu.** Danh sách không giữ ở đây nữa: `sh tools/check-sdlc.sh` in bảng
  "Capability còn thiếu" (giải thích từng dòng: `docs/interface-sdlc.md` § 6). Mỗi capability là một đề
  xuất riêng, theo công thức `docs/interface-sdlc.md` § 4.2. Với `CAP-deploy-02`/`CAP-deploy-03` xem cả
  § Những chỗ thiết kế này yếu mục 1 của `kien-truc.md`. `CAP-operate-02` (sự cố → việc mới) là chỗ
  engine làm được: intake nhận incident / postmortem làm `input` của job mới, có `source label` riêng —
  cần đề xuất cách ghi nguồn trước khi code.
- **Bước A, đợt 2 — chiều xuôi.** Đợt 1 (SP12) đã có: chú thích `# giữ: CAP-…/INV-…` trên luật, `check-sdlc.sh`
  chặn id không có và capability `machine` được nhận mà không luật nào khai (36 chỗ đã gắn). Còn: gắn id cho
  ~200 chỗ chặn/cảnh báo còn lại và mọi `Category` của `workflow/checkers/*.md`; chặn luật mồ côi (cho phép
  danh sách "chưa phân loại" rồi rút dần); suy "diff chạm CAP/INV nào" từ file thay đổi, thay dòng
  "Interface: …" khai tay trong PR. Cần spec riêng.
- **Ba luật theo job type còn do người phán — cho máy giữ rồi mới thành invariant.** Việc của engine
  (checker), không phải interface: interface chỉ thêm invariant khi máy đã giữ luật (`interface-sdlc.md`
  § 4.1). Mỗi mục là đổi luật — đề xuất, chờ người OK:
  - bugfix "test tái hiện đỏ **vì đúng bug**": máy chỉ biết test đỏ (`aw check repro`, INV-007). Hướng
    khả thi: đòi đúng test đã đỏ trong `repro.md` phải xanh sau khi sửa (lỗi biên dịch không tự xanh nhờ
    bản sửa). Kiểm trước xem engine đã có luật "đỏ → xanh" chưa.
  - refactor/perf "không đổi assertion test cũ": máy chỉ chặn xoá test cũ và sửa không khai (INV-009).
    Hướng khả thi: so diff file test cũ với mẫu dòng assertion khai trong `conventions.md` (như mẫu bỏ
    qua test). Mẫu theo ngôn ngữ dễ báo nhầm → cảnh báo ở implement, chặn ở review.
  - refactor "không thêm hành vi" ở mức code: chỉ giữ ở mức spec (REQ `preserve`/`structural`, INV-008).
    Chưa thấy cách máy kiểm đáng tin; có thể để người phán và ghi rõ là không làm.
- **Đổi tên để bớt nhầm phase ↔ stage**: phase `03-plan` (thuộc stage `breakdown`) trùng chữ với stage
  `plan` (`00-intake`). Đổi tên stage hay phase đều chạm test, docs, lệnh sinh ra — đề xuất riêng.

## Glob của `plan.md` (sau giai đoạn chuyển tiếp)

- **Bước 2: `*` của `plan.md` không qua `/`.** Bản hiện tại đã có `**` và cảnh báo file chỉ khớp nhờ `*`
  vượt thư mục (`kc_glob_chuyen_tiep`). Bản sau: `kc_pham_vi`, `tk_pham_vi`, `kc_glob_rong` khớp bằng
  `khop_duong` (nghĩa mới), bỏ cảnh báo chuyển tiếp. Cân nhắc cùng lúc phạm vi luật `BR-` (suy từ
  `Expected files` lúc `aw rule promote`, khớp ở `tools/lib/knowledge.sh`): luật đã nâng mang mẫu nghĩa cũ —
  cần cảnh báo hay chuyển đổi khi đọc. Glob của `conventions.md` giữ nghĩa cũ (spec SP8).
