# SP1 — Định nghĩa interface SDLC: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Viết xong 7 trang stage còn lại, `job-types.md`, hoàn thiện `overview.md`, để cả bộ `interface/` được người duyệt.

**Architecture:** Mỗi trang đi qua cùng một chu trình (soạn → tự kiểm → đọc lạnh → rà → người duyệt → ghi quyết định). Trang thử `require` đã đi hết chu trình này và là mẫu. Không có code: "test" là các lệnh kiểm ở § Lệnh kiểm và lượt đọc lạnh.

**Tech Stack:** Markdown, `grep`, `awk`, `git`. Agent đọc lạnh là một subagent phiên trắng.

**Spec:** `docs/specs/SP1-interface.md` (khuôn §4, luật kiểm §5, quy trình §6, thứ tự §7). Lịch sử và lý do: `docs/decisions.md`.

## Global Constraints

Mọi task đều chịu các ràng buộc này (chép từ spec §4.1, §4.2).

- Heading, tên trường, mã, tên artifact, giá trị enum bằng tiếng Anh; mọi chữ người viết, kể cả `Rule`, bằng tiếng Việt.
- Interface không nhắc tên file của engine, định dạng file, nơi lưu, dạng dấu duyệt, công cụ.
- Backtick chỉ bọc tên stage, tên artifact, mã `CAP-…` / `INV-…`, hoặc giá trị có trong bảng Giá trị của `overview.md`. Không bọc tên thư mục, tên trường, mẫu mã, giá trị đứng sau tên trường (`Judged by: machine`), ô bảng chứa tên artifact hay stage.
- Ô bảng: một tên, danh sách cách dấu phẩy, `—`, hoặc văn xuôi (chỉ ở cột Used for, Description, Definition).
- Giá trị mới phải thêm vào bảng Giá trị của `overview.md` **trước** khi dùng.
- Trang stage đúng 6 mục theo thứ tự: `# Stage: <id>`, `## Definition` (≤ 2 câu), `## Input` (Artifact · Required · Used for), `## Output` (Artifact · Approval · Description), `## Capabilities`, `## Not in this stage` (≤ 5 gạch), `## Rationale` (≤ 5 gạch, mỗi gạch mở bằng "Đã loại:").
- Capability: `### CAP-<stage>-NN — <tên>` + `- Rule:` + `- Judged by:` (`machine` | `agent` | `human`) + `- Artifact:` + `- Fail example:` (1 dòng, bắt buộc) + `- Pass example:` (tuỳ chọn).
- Tách capability theo ai phán được: phần máy kiểm chính xác được là capability `machine` riêng. Điều phải đúng xuyên nhiều stage là invariant, không phải capability.
- Mã chưa duyệt được đánh lại số; mã đã duyệt không đổi số.
- Commit: `docs(interface): …`, kết thúc bằng các dòng ghi công (attribution) của phiên.
- v1 chỉ đọc (`/home/dangminhphuc/github/agent-workflow`), không sửa. Việc làm ở `/home/dangminhphuc/github/agent-workflow-v2`, nhánh `v2`.

## Review Focus

Năm lỗi spec ngụ ý mà không bước nào của chu trình tự bắt; mỗi dòng ghi task có bước chặn nó.

1. **Chép nguyên văn v1 kèm định danh của engine** (`REQ-`, `DEC-`, tên file, lệnh `aw`) — Lệnh kiểm B chạy trong mọi task 1–7.
2. **Capability thật ra là luật xuyên stage** (như `CAP-require-03` cũ về dấu duyệt) — bước "Soạn" của mỗi task liệt kê capability nào đã chuyển sang `invariants.md`; Task 3, 4, 5 nhiều khả năng nhất.
3. **Input không có trang nào tạo ra**, kể cả vòng operate → plan và artifact thêm của job type — Lệnh kiểm C1 mỗi task; Task 1 và 7 phải khớp nhau; Task 10 kiểm lại toàn bộ.
4. **Artifact Approval `yes` không có capability `human` nhận** (không ai duyệt nó) — Lệnh kiểm C3 mỗi task.
5. **Khuôn đổi giữa chừng làm trang đã duyệt lệch** — Task nào sửa khuôn phải sửa mọi trang đã viết trong cùng commit và liệt kê trang đổi theo ở lần duyệt kế tiếp (spec §8).

## Lệnh kiểm

Chạy từ `/home/dangminhphuc/github/agent-workflow-v2`. `$P` là trang đang viết. Đã chạy trên `01-require.md`: mọi kết quả "Expected" bên dưới đúng.

- **A1 — thứ tự mục.** `grep -n '^# \|^## ' $P`
  Expected: đúng 7 dòng theo thứ tự `# Stage: <id>`, Definition, Input, Output, Capabilities, Not in this stage, Rationale.
- **A2 — chữ trong backtick** (cả bộ).
  `cat interface/overview.md interface/invariants.md interface/stages/*.md | grep -v '^```' | grep -o '`[^`]*`' | tr -d '`' | sort -u`
  Expected: mỗi chữ là tên stage, tên artifact, mã có thật, hoặc giá trị trong bảng Giá trị. Chữ lạ thì sửa trang hoặc thêm giá trị vào bảng.
- **A3 — mã trùng.** `grep -h '^### \(CAP\|INV\)-' interface/stages/*.md interface/invariants.md | cut -d' ' -f2 | sort | uniq -d`
  Expected: không in gì.
- **A4 — capability đủ trường.**
  `for f in interface/stages/*.md; do n=$(grep -c '^### CAP-' $f); for k in Rule 'Judged by' Artifact 'Fail example'; do c=$(grep -c "^- $k:" $f); [ "$c" = "$n" ] || echo "$f: $k $c/$n"; done; done`
  Expected: không in gì.
- **A5 — giá trị `Judged by`.** `grep -h '^- Judged by:' interface/stages/*.md | sort | uniq -c`
  Expected: chỉ `machine`, `agent`, `human`.
- **A6 — giới hạn độ dài.**
  `awk '/^## /{s=$0} /^- /&&(s=="## Not in this stage"||s=="## Rationale"){c[FILENAME" "s]++} END{for(k in c) if(c[k]>5) print k, c[k]}' interface/stages/*.md`
  và `awk '/^## /{s=$0} s=="## Rationale"&&/^- /&&!/^- Đã loại:/{print FILENAME": "$0}' interface/stages/*.md`
  Expected: không in gì. Definition ≤ 2 câu: đếm bằng mắt.
- **B — không có định danh của engine.** `grep -nE 'REQ-|DEC-|RVW-|TSK-|\.md|\.sh|\baw |tools/' $P`
  Expected: không in gì.
- **C1 — Input có nơi tạo ra.** Mỗi artifact ở `## Input` của $P có trong cột "Tạo bởi" của Bản đồ artifact bên dưới, ở stage đứng trước, hoặc trong `Added artifacts` của một job type.
- **C2/C3 — Output có capability bảo đảm, Approval `yes` có capability `human`.**
  `awk -F'|' '/^## Output/{o=1;next} /^## /{o=0} o&&NF>3&&$2!~/Artifact|---/{gsub(/ /,"",$2); gsub(/ /,"",$3); print $2, $3}' $P` rồi `grep '^- Artifact:' $P`
  Expected: mỗi artifact in ra ở lệnh trên xuất hiện trong ít nhất một dòng `- Artifact:`; mỗi artifact có `yes` xuất hiện trong một capability `Judged by: human`.

- **D — thứ tự `Warned from` / `Checked at`** (spec §5 luật 7). `grep -n 'Warned from\|Checked at' interface/invariants.md`
  Expected: với mỗi invariant có `Warned from`, stage đó đứng trước mọi stage ở `Checked at` theo luồng `plan → require → design → breakdown → implement → verify → deploy → operate`. Chạy ở Task 4 (lần đầu có `Warned from`), Task 8 và Task 10.

## Prompt đọc lạnh

Dùng nguyên văn cho mọi lượt đọc lạnh (agent `general-purpose`, phiên trắng). Thay `<TRANG>` bằng đường dẫn trang; Task 8, 10 đổi danh sách file cho đúng.

```
You are doing a "cold read" test of documentation. Read ONLY these files:
- /home/dangminhphuc/github/agent-workflow-v2/interface/overview.md
- /home/dangminhphuc/github/agent-workflow-v2/interface/invariants.md
- /home/dangminhphuc/github/agent-workflow-v2/interface/job-types.md   (only if it exists)
- <TRANG>
Do not read any other file, search the repo, or use outside knowledge. Pages are Vietnamese; answer in Vietnamese.
Answer, quoting the lines you relied on (say exactly what is missing instead of guessing):
1. Stage này là gì, vì sao cần? 2. Nhận gì vào? 3. Trả gì ra? 4. Khi nào xong, ai cho phép kết thúc? 5. Một ví dụ cụ thể làm sai.
Then list: terms a newcomer could not understand (out of scope, do not report: file formats, storage, approval-mark shape, how checks are implemented, the empty "Kịch bản xuyên suốt", other stages' details); ambiguous sentences with both readings; contradictions between sections or files; backtick words that are not a stage, artifact, id or a value in the "Giá trị" table.
Rate each finding MAJOR (reader would act wrongly or cannot answer one of the 5) or MINOR. For each MAJOR say whether it belongs to this page or outside it. Do not edit files. Under 500 words.
```

## Bản đồ artifact (nháp; chốt khi từng trang được duyệt)

| Artifact | Tạo bởi | Approval | Ghi chú |
|---|---|---|---|
| work-item | plan | yes | |
| requirements | require | yes | đã duyệt |
| open-questions | require | no | đã duyệt |
| design | design | quyết ở Task 2 | |
| task-plan | breakdown | no (quyết ở Task 3) | |
| change, test-evidence, task-evidence, security-evidence | implement | no | |
| review-report | verify | yes | đã duyệt (D-023) |
| delivery | deploy | quyết ở Task 6 | |
| operational-feedback | operate | no | vào lại `plan` |
| reproduction-evidence | implement (bugfix) | no | thêm bởi job type, `verify` đọc |
| performance-evidence | implement (perf) | no | thêm bởi job type, `verify` đọc |

## Chu trình trang (dùng cho Task 1–7)

Mỗi task 1–7 gồm sáu bước này, cùng thứ tự. Phần riêng của từng task nằm ở bước 1.

- [ ] **Bước 1 — Soạn** `interface/stages/NN-<id>.md` theo khuôn (Global Constraints), từ nguồn v1 ghi ở task. Liệt kê riêng: capability v1 đã **chuyển** sang `invariants.md` (và thêm `INV` mới nếu có), đã **loại** (kèm lý do vào Rationale), hoặc **đẩy** sang SP7 (ghi `docs/decisions.md` § Ứng viên SP7).
- [ ] **Bước 2 — Tự kiểm.** Chạy A1–A6, B, C1–C3. Mọi lệnh phải ra kết quả Expected.
- [ ] **Bước 3 — Đọc lạnh** với Prompt đọc lạnh. Xử lý (spec §6.3): chữ, nhất quán, hệ quả trực tiếp của khuôn → tự sửa; quyết định nội dung hoặc đổi khuôn → gom thành **một tin** hỏi người; MAJOR ngoài trang → `docs/decisions.md` § Đang mở. Lặp tối đa 3 lần, dừng sớm khi không còn MAJOR trong trang.
- [ ] **Bước 4 — Rà.** Đối chiếu trang với spec §4–§5 và các trang đã duyệt: thuật ngữ, mã, và quan hệ Input/Output khớp nhau. Sửa hệ quả trực tiếp; ghi D-NNN cho mỗi sửa đáng kể.
- [ ] **Bước 5 — Người duyệt** đọc trang, duyệt hoặc chỉ chỗ sửa; sửa xong thì quay lại bước 2.
- [ ] **Bước 6 — Ghi nhận.** Ghi D-NNN (trang đã duyệt, các quyết định, trang bị đổi theo nếu có), cập nhật bảng Bản đồ artifact trong file này nếu tên hay Approval đổi, sửa `PROGRESS.md` (Bước tiếp theo), rồi `git add -A && git commit -m "docs(interface): trang <id> đã duyệt" && git push`.

---

### Task 1: Trang `plan`

**Files:**
- Create: `interface/stages/00-plan.md`
- Modify: `docs/decisions.md`, `PROGRESS.md`

**Interfaces:**
- Consumes: `operational-feedback` (từ `operate`, Required `no`); yêu cầu từ bên ngoài quy trình không phải artifact — nói ở Used for.
- Produces: `work-item` (Approval `yes`: người duyệt xác nhận loại việc, nguồn, điểm xuất phát).

- [ ] **Bước 1–6** theo Chu trình trang. Nguồn v1: `sdlc/stages/00-plan.md`; `docs/kien-truc.md` mục `00-intake` và "Vào ở phase nào cũng được".
- Hỏi người ở lượt đọc lạnh đầu:
  1. v1 có `CAP-plan-03` (xếp ưu tiên) và `CAP-plan-04` (ước lượng), engine v1 đặt ngoài phạm vi. Đề xuất: ghi vào `Not in this stage`, không làm capability.
  2. Một work item ghi gì ở mức interface: loại việc, nguồn, điểm xuất phát. Ai phân loại: agent đề xuất, người duyệt xác nhận (`Definition` của job type phải tới agent — `job-types.md`).
  3. `operational-feedback` có là Input của `plan` không (vòng operate → plan trong `overview.md`).
  4. "Vào ở phase nào cũng được" của v1 thuộc cách agent làm việc → chuyển SP3, ghi § Đang mở.

### Task 2: Trang `design`

**Files:**
- Create: `interface/stages/02-design.md`
- Modify: `docs/decisions.md`, `PROGRESS.md`, `interface/overview.md` (câu `design` nếu đổi)

**Interfaces:**
- Consumes: `requirements`, `open-questions` (từ `require`).
- Produces: `design`.

- [ ] **Bước 1–6** theo Chu trình trang. Nguồn v1: `sdlc/stages/02-design.md`; `docs/kien-truc.md` mục "Quyết định là thứ người duyệt", "Giả định chưa xác nhận".
- Hỏi người:
  1. Đơn vị duyệt: cả khối `design` (Approval `yes`, khớp `INV-001`) hay từng quyết định như v1. Đề xuất: cả khối ở interface; duyệt và mở lại từng quyết định là chi tiết engine (SP3/SP4).
  2. `CAP-design-02` v1 (agent độc lập tìm quyết định ngầm): giữ làm capability `agent`.
  3. Mode 2 chống neo của v1 (rủi ro cao → người phác quyết định trước): capability hay SP7.
  4. `CAP-design-04` v1 (tri thức bền vững): đẩy SP7.
  5. `Design: skip` là việc của `job-types.md` (Task 8), không ghi ở trang này.

### Task 3: Trang `breakdown`

**Files:**
- Create: `interface/stages/03-breakdown.md`
- Modify: `interface/invariants.md`, `docs/decisions.md`, `PROGRESS.md`

**Interfaces:**
- Consumes: `requirements`, `design`.
- Produces: `task-plan` (Approval `no`; `breakdown` chỉ do máy kiểm, v1).

- [ ] **Bước 1–6** theo Chu trình trang. Nguồn v1: `sdlc/stages/03-breakdown.md`; `sdlc/invariants.md` INV-001, INV-002, INV-006.
- Hỏi người:
  1. Thêm invariant (`Checked at: breakdown`): mọi task truy về một yêu cầu hoặc một phát hiện của review; mọi yêu cầu có task phủ hoặc được hoãn có lý do (v1 INV-001); mọi task chỉ dựa trên quyết định đã duyệt (v1 INV-002).
  2. Thêm invariant "artifact được dựng từ bản hiện hành của input" (v1 INV-006, `Checked at: all`)? Đây là lần đầu một artifact không cần duyệt vẫn phụ thuộc input đã duyệt.
  3. Phát hiện của review thành task mới (vòng verify → breakdown): ghi ở đây hay chỉ ở `verify`.

### Task 4: Trang `implement`

**Files:**
- Create: `interface/stages/04-implement.md`
- Modify: `interface/invariants.md`, `docs/decisions.md`, `PROGRESS.md`

**Interfaces:**
- Consumes: `requirements`, `design` (Required `yes`; job type bỏ `design` thì được phép vắng — do `job-types.md`), `task-plan`.
- Produces: `change`, `test-evidence`, `task-evidence`, `security-evidence` (đều Approval `no`).

- [ ] **Bước 1–6** theo Chu trình trang. Nguồn v1: `sdlc/stages/04-implement.md`; `sdlc/invariants.md` INV-003, INV-009; `docs/kien-truc.md` mục "Bằng chứng do máy ghi".
- Hỏi người:
  1. Thêm invariant "mọi yêu cầu có test, hoặc ghi lý do kiểm tay" với `Warned from: implement`, `Checked at: verify` (v1 INV-003). Đây là chỗ đầu tiên dùng trường `Warned from`.
  2. `security-evidence` ở `implement` hay `verify` (lỗi mơ hồ từ v1). Đề xuất: giữ ở `implement` (máy tạo, gắn với code); `verify` đọc.
  3. `CAP-implement-04/05` v1 (file nằm trong kế hoạch): giữ làm capability `machine`.
  4. `CAP-implement-07` v1 (tri thức bền vững): đẩy SP7.

### Task 5: Trang `verify`

**Files:**
- Create: `interface/stages/05-verify.md`
- Modify: `interface/invariants.md`, `interface/overview.md`, `docs/decisions.md`, `PROGRESS.md`

**Interfaces:**
- Consumes: `requirements`, `open-questions`, `design`, `task-plan`, `change`, `test-evidence`, `task-evidence`, `security-evidence`.
- Produces: `review-report` (Approval `yes`: người xác nhận phán quyết).

- [ ] **Bước 1–6** theo Chu trình trang. Nguồn v1: `sdlc/stages/05-verify.md`; `sdlc/invariants.md` INV-004; `docs/kien-truc.md` mục "Review", "Cross-check, trạng thái sạch, nhật ký".
- Hỏi người:
  1. **Merge nằm ở đâu** (ghi ở `docs/decisions.md` § Ghi chú cho các trang chưa viết): đề xuất `verify` kết thúc bằng phán quyết merge, người duyệt merge ở `deploy` (khớp `CAP-deploy-01` v1); khi đó sửa câu `deploy` trong `overview.md` và xem lại `INV-002`.
  2. Thêm capability `agent`: mọi yêu cầu khớp với câu trả lời của câu hỏi mở nó trỏ tới (bắt câu trả lời đến muộn, D-017).
  3. Thêm invariant "mọi yêu cầu có phán quyết trong review" (v1 INV-004, `Checked at: verify`).
  4. `CAP-verify-03/04/05` v1 (e2e, tải, UAT): giữ làm capability mô tả trạng thái đích (interface mô tả cả phần engine chưa làm), `Judged by` như v1; đề xuất gộp "tải" vào một capability.
  5. `CAP-verify-02` v1 (người đọc code nhạy cảm) và `CAP-verify-06` v1 (tri thức bền vững): giữ `02`, đẩy `06` sang SP7.

### Task 6: Trang `deploy`

**Files:**
- Create: `interface/stages/06-deploy.md`
- Modify: `docs/decisions.md`, `PROGRESS.md`, `interface/overview.md` (câu `deploy`)

**Interfaces:**
- Consumes: `change`, `review-report`.
- Produces: `delivery` (Approval quyết ở đây: v1 đòi người xác nhận đường lui trước khi phát hành).

- [ ] **Bước 1–6** theo Chu trình trang. Nguồn v1: `sdlc/stages/06-deploy.md`; D-003 trong `docs/decisions.md`.
- Hỏi người:
  1. Khớp quyết định merge của Task 5.
  2. `delivery` ghi gì ở mức interface: cái gì được giao, giao tới đâu, đường lui. Kết quả pipeline đi vào bằng cách nào là SP6, ngoài trang.
  3. Đường lui được ghi và người xác nhận trước khi phát hành (v1 `CAP-deploy-03`): giữ.
  4. Phát hành/triển khai thật (v1 `CAP-deploy-02`) là điểm nối với hệ thống ngoài (D-003): ghi rõ trong `Not in this stage` hay làm capability `machine` mô tả trạng thái đích.

### Task 7: Trang `operate`

**Files:**
- Create: `interface/stages/07-operate.md`
- Modify: `docs/decisions.md`, `PROGRESS.md`, `interface/overview.md` (câu `operate`)

**Interfaces:**
- Consumes: `delivery`.
- Produces: `operational-feedback` (Approval `no`); `plan` nhận nó thành work item mới.

- [ ] **Bước 1–6** theo Chu trình trang. Nguồn v1: `sdlc/stages/07-operate.md`; D-003.
- Hỏi người:
  1. Vòng operate → plan: Input của `plan` (Task 1) và Output của trang này phải khớp tên.
  2. Quan sát production (v1 `CAP-operate-01`) là điểm nối: capability `machine` mô tả trạng thái đích, hay `Not in this stage`.
  3. Sự cố thành work item mới, nêu nguồn (v1 `CAP-operate-02`): giữ, `Judged by: human`.
  4. Hậu kiểm sự cố (postmortem): đề xuất không đưa vào (YAGNI).

### Task 8: `job-types.md`

**Files:**
- Create: `interface/job-types.md`
- Modify: `interface/invariants.md`, `interface/overview.md`, `docs/decisions.md`, `PROGRESS.md`

**Interfaces:**
- Consumes: tên 8 stage và tên artifact của 8 trang đã duyệt.
- Produces: bảng `Job types` (Job type · Definition · Optional · Skipped); bảng `Added artifacts` (Job type · Artifact · Produced by · Consumed by · Description) với `reproduction-evidence` (bugfix) và `performance-evidence` (perf), cả hai `implement` → `verify`.

- [ ] **Bước 1 — Soạn** `job-types.md` theo spec §4.4 cho 5 loại `feature`, `bugfix`, `refactor`, `perf`, `chore`, từ `sdlc/profiles/*.md` và `sdlc/invariants.md` INV-007…INV-011 của v1. Chuyển luật riêng của từng loại thành invariant `Only for: <loại>` trong `invariants.md`: bugfix — test tái hiện đỏ trên code chưa sửa; refactor/perf — yêu cầu không thêm hành vi, test cũ được giữ; perf — số đo trước và sau do máy ghi; chore — không đụng code production, nâng dependency được khai, không nâng bản lớn.
- [ ] **Bước 2 — Thêm invariant** "stage tuỳ chọn bị bỏ phải có người duyệt việc bỏ" (spec §4.4); chọn `Checked at` cùng người.
- [ ] **Bước 3 — Tự kiểm.** A2–A5 cho `invariants.md` (mã `INV` đủ trường, không trùng), B cho `job-types.md`, C1 cho mỗi artifact ở `Added artifacts`.
- [ ] **Bước 4 — Đọc lạnh** (đổi danh sách file: có `job-types.md`; câu hỏi cho agent: một việc "sửa lỗi đăng nhập" thuộc loại nào, đi qua stage nào, thêm artifact gì) rồi **Bước 5 — Rà**, **Bước 6 — Người duyệt**, **Ghi nhận** theo Chu trình trang.
- Hỏi người: (1) `Definition` phân biệt từng loại với loại gần nó; (2) bảng v1 ghi `deploy` tuỳ chọn ở cả 5 loại, giữ nguyên hay thành quy tắc chung; (3) invariant chore "không nâng bản lớn" có ở interface hay thuộc SP7.

### Task 9: Hoàn thiện `overview.md`

**Files:**
- Modify: `interface/overview.md`, `docs/decisions.md`, `PROGRESS.md`

**Interfaces:**
- Consumes: `Definition` và Input/Output của 8 trang đã duyệt; bảng Giá trị.
- Produces: bảng Luồng với câu một dòng khớp từng trang; mục "Kịch bản xuyên suốt"; bảng Giá trị đủ mọi giá trị các trang dùng.

- [ ] **Step 1: Đối chiếu bảng Luồng** với `Definition` của 8 trang; sửa câu một dòng cho khớp; bỏ ghi chú nháp.
- [ ] **Step 2: Viết "Kịch bản xuyên suốt"**: một việc đi qua 8 stage dưới dạng bảng (Stage · Nhận · Trả · Ai duyệt · Nội dung ví dụ). Đề xuất kịch bản: sửa lỗi đăng nhập (job type bugfix) vì nó dùng được `design` tuỳ chọn, `reproduction-evidence`, câu hỏi mở có câu trả lời khác giả định; người chọn kịch bản trước khi viết.
- [ ] **Step 3: Kiểm.** A2 (backtick, cả bộ); mỗi artifact trong kịch bản nằm trong Bản đồ artifact; mỗi bước nhận đúng cái bước trước trả.
- [ ] **Step 4: Giữ nguyên** phần "nghĩa của `agent` chờ SP3" và ghi ở § Đang mở nếu chưa có.
- [ ] **Step 5: Người duyệt** `overview.md`, ghi D-NNN, commit `docs(interface): hoàn thiện overview`, push.

### Task 10: Đọc lạnh toàn bộ và duyệt SP1

**Files:**
- Modify: `docs/decisions.md`, `PROGRESS.md`, `docs/specs/SP1-interface.md` (Trạng thái)

**Interfaces:**
- Consumes: toàn bộ `interface/`.
- Produces: SP1 đã xong theo spec §9.

- [ ] **Step 1: Kiểm chéo** (cả bộ): A2–A5; D; C1–C3 chạy cho cả 8 trang; mỗi `Checked at` / `Warned from` / `Only for` của `invariants.md` trỏ tới stage hay job type có thật; mỗi artifact ở `Added artifacts` có `Produced by` và `Consumed by` là stage có thật.
- [ ] **Step 2: Đọc lạnh toàn bộ.** Một agent phiên trắng đọc cả `interface/`, đi theo "Kịch bản xuyên suốt", tìm chỗ hai trang mâu thuẫn hay một artifact không có nơi tạo ra. Dừng khi không còn MAJOR, tối đa 3 lần.
- [ ] **Step 3: Rà** bộ interface một lượt; gom quyết định cần người vào một tin.
- [ ] **Step 4: Người duyệt cả bộ.**
- [ ] **Step 5: Ghi D-NNN "SP1 xong"**; sửa `docs/specs/SP1-interface.md` Trạng thái thành "đã duyệt"; `PROGRESS.md`: SP1 `xong`, Bước tiếp theo = SP7 (chọn lại tính năng của v1), các mục § Đang mở của SP1 đã chuyển hết; commit `docs: SP1 xong`, push.
