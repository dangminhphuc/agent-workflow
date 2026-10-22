# Spec: SP1 — Capability gắn artifact, capability phạm vi

- Ngày: 2026-10-22
- Branch: `claude/brave-heisenberg-t70jup`
- Roadmap: `docs/superpowers/2026-10-22-roadmap-cai-thien.md` § SP1
- Interface: thêm `CAP-breakdown-02`, `CAP-implement-04`, `CAP-implement-05`, `CAP-implement-06`; thêm
  trường `- Artifact:` cho mọi capability. Không bỏ, không nới capability hay invariant nào.

## 1. Mục tiêu

Lượt đánh giá 10/2026 chỉ ra hai chỗ interface SDLC nói sai về engine:

1. **Không nói gì về phạm vi.** `workflow/phases/04-implement.md` gọi scope creep là lỗi điển hình, nhưng
   `sdlc/` không có capability hay invariant nào về phạm vi diff. Lỗ ở kiểm phạm vi (theo hợp mọi task,
   glob `*` khớp cả `/`) vì vậy không hiện trên roadmap.
2. **Nhãn `implemented` rẻ.** Trạng thái stage suy ra từ tỉ lệ capability có phase nhận; stage càng ít
   capability càng dễ `implemented`. `breakdown` có 1 capability, `implement` có 2; `task-evidence` mà
   `implement` provides không capability nào nói tới.

**Tiêu chí thành công:**

- Mọi capability khai `- Artifact:`; mọi loại trong `provides` của mọi stage có ít nhất một capability
  trỏ tới; `tools/check-sdlc.sh` chặn khi không như vậy.
- Interface có capability phạm vi, tách phần engine đã làm (nhận ngay) với phần chưa làm (SP3).
- `sh tools/check-sdlc.sh` ĐẠT; roadmap in `implement (partial)` với đúng một capability còn thiếu:
  `CAP-implement-05`.
- `sh tools/run-tests.sh` → `MỌI CA ĐẠT`; lệnh adapter sinh ra không đổi (`AW_COMPARE=1`).

## 2. Quyết định (đã chốt khi brainstorm)

| # | Câu hỏi | Chọn | Lý do |
|---|---|---|---|
| 1 | Luật "mỗi `provides` có capability" giữ thế nào | Máy kiểm qua trường `- Artifact:` | Luật không máy kiểm thành nghi thức; quy ước sẽ trôi |
| 2 | Áp cho `adds_provides` của profile? | Không | Artifact riêng của profile đã có invariant máy giữ, nêu tên ca test (INV-007, INV-010); thêm capability là nói lại một điều |
| 3 | Capability phạm vi tách thế nào | Ba capability: phạm vi cả việc (đã làm), phạm vi theo task + glob hẹp (chưa), task-evidence (đã làm) | Nhãn trung thực: roadmap không báo thiếu phần engine đã làm |
| 4 | `- Artifact:` bắt buộc hay tuỳ chọn | Bắt buộc, một hoặc nhiều giá trị | Luật không ngoại lệ; capability nào cũng chỉ ra thứ nó bảo đảm; bước A (SP12) có sẵn ánh xạ |

## 3. Thay đổi interface (`sdlc/stages/`)

### 3.1 Trường `- Artifact:`

Dòng trong khối capability, cạnh `- Rule:` và `- Judged by:`:

```markdown
### CAP-require-02 — Each open question carries an assumption and a blocking level
- Rule: …
- Judged by: machine
- Artifact: open-questions
```

- Giá trị: một hoặc nhiều loại artifact, cách nhau bằng dấu phẩy, viết trơn (không backtick); khoảng
  trắng quanh mỗi giá trị bị bỏ qua.
- Mỗi giá trị phải nằm trong `provides` của **chính stage** chứa capability.
- Như `Rule:` / `Judged by:`, dòng chỉ tính khi nằm trong khối của capability (trước heading kế tiếp).

### 3.2 Gắn `Artifact` cho capability có sẵn

| Stage | Capability → `Artifact` |
|---|---|
| plan | `CAP-plan-01`…`04` → `work-item` |
| require | `CAP-require-01` → `requirements`; `-02` → `open-questions`; `-03` → `requirements` |
| design | `CAP-design-01`…`03` → `design` |
| breakdown | `CAP-breakdown-01` → `task-plan` |
| implement | `CAP-implement-02` → `test-evidence`; `-03` → `security-evidence` |
| verify | `CAP-verify-01`…`05` → `review-report` |
| deploy | `CAP-deploy-01`…`03` → `delivery` |
| operate | `CAP-operate-01`, `-02` → `operational-feedback` |

### 3.3 Capability mới

Thân file stage tiếng Anh, `Rule:` không tên file hay cú pháp engine.

**`sdlc/stages/03-breakdown.md`**

```markdown
### CAP-breakdown-02 — Each task names the files it may change and how it is proven done
- Rule: every task lists the files it may change and a verification step; neither may be empty or a placeholder.
- Judged by: machine
- Artifact: task-plan
```

Engine đã làm (`tools/check-plan.sh` chặn `Expected files` / `Verify` trống, thiếu, còn chỗ giữ chỗ) →
`workflow/phases/03-plan.md` nhận ngay.

**`sdlc/stages/04-implement.md`**

```markdown
### CAP-implement-04 — Every changed file is planned or declared as unplanned
- Rule: each file the change touches is listed in some task's files or declared unplanned with a reason; the implement stage warns, the verify stage blocks.
- Judged by: machine
- Artifact: change

### CAP-implement-05 — Each task changes only its own files, and file patterns are narrow enough to mean something
- Rule: the files changed while a task is in progress match that task's own list or are declared unplanned for it; a file pattern that matches far more files than the task needs is flagged.
- Judged by: machine
- Artifact: change

### CAP-implement-06 — A task is done only when its verification passes, recorded by the machine
- Rule: a task is marked done only by the machine, after its verification step passes or a record of manual verification is given.
- Judged by: machine
- Artifact: task-evidence
```

- `CAP-implement-04`: engine đã làm (`kc_pham_vi` trong `tools/lib/cross-check.sh`; `aw check implement`
  cảnh báo, `aw check review` chặn) → `04-implement.md` nhận ngay.
- `CAP-implement-05`: **chưa làm** — SP3.
- `CAP-implement-06`: engine đã làm (`aw task done`, `tools/task.sh`; `task-results.md`) → nhận ngay.
- `CAP-implement-01` để trống, không đánh số lại (đã chuyển thành `CAP-breakdown-01` khi tách stage —
  `docs/kien-truc.md` § Interface SDLC).

### 3.4 Trạng thái stage sau thay đổi

| Stage | Trước | Sau |
|---|---|---|
| breakdown | implemented | implemented (nhận 01, 02) |
| implement | implemented | **partial** (nhận 02, 03, 04, 06; thiếu 05) |
| còn lại | không đổi | không đổi |

`workflow.yaml`, khối `sdlc:`, thêm:

```yaml
  - stage: implement
    note: Phạm vi diff chỉ kiểm theo cả việc, chưa theo từng task; glob rộng không bị cảnh báo
```

## 4. Thay đổi `tools/check-sdlc.sh`

**Đọc.** Khối awk đọc capability (quanh dòng 138–169) bắt thêm `- Artifact:`; nhận danh sách
`provides` của stage (đã đọc vào `$W/p` ngay trước) qua `-v`. Mỗi capability ghi thêm danh sách
artifact để bước phủ `provides` dùng.

**Lỗi mới** (chặn — script không có mức cảnh báo):

| Điều kiện | `[LỖI]` |
|---|---|
| Thiếu `- Artifact:` hoặc giá trị rỗng | `CAP-x: thiếu "- Artifact:" — thêm loại artifact capability này bảo đảm, lấy trong provides của stage S: <danh sách>.` |
| Giá trị không có trong `provides` của stage | `CAP-x: Artifact "t" không có trong provides của stage S (<danh sách>) — sửa tên loại, hoặc chuyển capability sang stage provides loại đó.` |
| Loại trong `provides` không capability nào trỏ tới | `stage S: provides "t" — không capability nào khai "Artifact: t"; thêm hoặc gắn một capability.` |

**Không đổi:** dạng bảng stage → phase, roadmap, ma trận profile (không thêm cột); `adds_provides`
của profile không chịu luật này; CRLF vẫn đọc được.

**Chú thích đầu script** (khối "Chặn:", phần Capability): thêm ba điều kiện trên.

## 5. Test

Viết trước, thấy đỏ, rồi code (`AGENTS.md` § Verify).

`tools/tests/22-sdlc-stage-files.sh` — nhóm "capability trong file stage", mỗi ca hỏng một chỗ:

| Ca | Mong đợi |
|---|---|
| Capability mất `- Artifact:` | chặn: `CAP-deploy-01: thiếu "- Artifact:"` |
| `- Artifact:` rỗng | chặn: `CAP-deploy-01: thiếu "- Artifact:"` |
| `- Artifact: deliveryx` | chặn: `Artifact "deliveryx" không có trong provides của stage deploy` |
| Không capability nào của implement khai `task-evidence` | chặn: `stage implement: provides "task-evidence" — không capability nào khai` |
| `- Artifact:` lạc dưới `## Notes` sau capability cuối | chặn: `CAP-deploy-03: thiếu "- Artifact:"` |
| `- Artifact: requirements, open-questions` (nhiều giá trị, khoảng trắng) | ĐẠT |

`tools/tests/20-sdlc-conformance.sh`:

- Ca "in ánh xạ stage → phase": `implement +partial +implement`.
- Ca chuỗi trạng thái: `implement=partial`.
- Mới: phase implement nhận `CAP-implement-05` mà còn note → chặn `stage implement: suy ra implemented nhưng khối sdlc: còn note`.
- Mới: nhận `CAP-implement-05` + xoá mục implement khỏi khối `sdlc:` → ĐẠT, `implement +implemented`.
- Chạy lại ca bỏ `security-evidence` khỏi provides của stage: vẫn khớp thông báo cũ (thêm lỗi Artifact không làm hỏng ca).

## 6. Tài liệu

- `docs/interface-sdlc.md`: § 2 (ví dụ + bảng trường có `Artifact`), § 3 (luật phủ `provides`),
  § 4.3 (bước chọn `Artifact`), § 4.4 (phase mới: không đổi), § 5 (ba lỗi mới), § 6 (roadmap mới).
- `docs/kien-truc.md` § Interface SDLC: quyết định "Artifact bắt buộc; profile không áp" + lý do; bảng
  ánh xạ (`implement` partial, `CAP-implement-05`).
- `docs/superpowers/2026-10-22-roadmap-cai-thien.md`: cột Spec / Plan của SP1.
- `changes/claude-brave-heisenberg-t70jup.md`: mục `Nội bộ`. Không `Bỏ` / `Thay đổi` (không nới gì).
- `docs/viec-can-lam.md`: không đổi (mục 2 vẫn là SP3).

## 7. Ngoài phạm vi

- Kiểm phạm vi theo task, cảnh báo glob rộng → SP3 (nhận `CAP-implement-05`).
- `Rule:` không cú pháp engine, `Tested by:` nêu ca cho INV-001…006 → SP2.
- Gắn luật checker vào capability (bước A) → SP12.
- Thêm cột `Artifact` vào output roadmap — chưa cần.
