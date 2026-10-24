# Spec: SP31 — Tên lệnh theo stage SDLC

- Ngày: 2026-10-23 · Branch: `claude/keen-fermi-2le5x4`
- Roadmap § SP31 · Nguồn: lượt đánh giá "slash command phase so với SDLC stage" ngày 2026-10-23.
- Trạng thái: **nháp — §1–§4 người đã chốt, §5 chờ người chốt** trước khi viết plan.
- Interface: không đổi capability/invariant; `check-sdlc.sh` thêm luật cấu trúc (§4). Riêng §5.3,
  §5.5 đổi interface nếu được chọn.

## 0. Vấn đề

| Lệnh hiện tại | Stage nó làm | Ghi chú |
|---|---|---|
| `/aw-intake` | `plan` | khác tên |
| `/aw-spec` | `require` | khác tên |
| `/aw-design` | `design` | |
| `/aw-plan` | `breakdown` | **trùng chữ**: stage `plan` lại do `/aw-intake` làm |
| `/aw-implement` | `implement` | |
| `/aw-review` | `verify` | khác tên |
| `/aw-ship` | `deploy` | khác tên, tuỳ chọn |

4/7 lệnh khác tên stage; người đọc `sdlc/` song song với lệnh dễ hiểu sai, nặng nhất là chữ "plan".
Summary phase đếm "Bước 1/6 … 6/6, Bước 7 (tuỳ chọn)" trong khi stage đánh số `00`–`07`.

**Thành công:** tên lệnh, id phase và id stage là một; số thứ tự lấy từ stage; máy chặn khi lệch.

## 1. Đặt tên theo stage, tiền tố `aw-` (chốt)

| Cũ | Mới | File phase |
|---|---|---|
| `/aw-intake` | `/aw-plan` | `workflow/phases/00-plan.md` |
| `/aw-spec` | `/aw-require` | `01-require.md` |
| `/aw-design` | `/aw-design` | `02-design.md` |
| `/aw-plan` | `/aw-breakdown` | `03-breakdown.md` |
| `/aw-implement` | `/aw-implement` | `04-implement.md` |
| `/aw-review` | `/aw-verify` | `05-verify.md` |
| `/aw-ship` | `/aw-deploy` | `06-deploy.md` |

- `id:` của phase = id stage nó `implements:` (phạm vi đổi tên ngoài lệnh: §5.1).
- Giữ tiền tố `aw-` và dấu `-` (`TIEN_TO_LENH`, `adapters/lib/common.sh`) — lý do ở §3.
- Lệnh tiện ích (`/aw-import`, `/aw-clarify`, `/aw-bootstrap`, `/aw-refactor`, `/aw-approvals`) giữ tên.
- Mọi chỗ nhắc tên lệnh cũ đổi theo: thân phase, `workflow/*.md`, rules, checker LLM, chuỗi adapter
  sinh (`adapters/lib/common.sh`, `adapters/*/build.sh`), output `aw`, README, `docs/`, test grep chữ.
  Hiện có ~51 file `.md`/`.sh` (ngoài `CHANGELOG.md`, `docs/superpowers/`) nhắc `/aw-<phase>`.

## 2. Deploy vẫn tuỳ chọn (chốt)

- `/aw-deploy` giữ `required: false` + `when:`; stage `deploy` giữ "tuỳ" trong ma trận job type.
- `CAP-deploy-03` (rollback) **không** làm trong SP31 (đề xuất ở §5.3).

## 3. Lệnh con kiểu `aw-{stage}-approve` / `aw-{stage}:approve` (đánh giá — chờ chốt ở §5.2)

### 3.1 Dấu `:` hay `-` qua các agent

| Agent | Lệnh dự án | Tên lệnh lấy từ | `:` |
|---|---|---|---|
| Claude Code | `.claude/commands/*.md`, `.claude/skills/<name>/SKILL.md` | tên file / `name` | Dành cho namespace plugin (`/plugin:lệnh`). Thư mục con không thành `a:b` (chỉ hiện ở mô tả). `name` của skill chỉ nhận chữ thường, số, `-` |
| Cursor | `.cursor/commands/*.md` | tên file | Không có namespace; `:` phải nằm trong tên file |
| Gemini CLI | `.gemini/commands/**/*.toml` | đường dẫn | Thư mục con → `/a:b` (dạng gốc của Gemini) |
| Codex CLI | prompt/skill | tên file | `/prompts:<tên>` là namespace của chính Codex |
| Copilot (VS Code), Windsurf | `.github/prompts/*.prompt.md`, `.windsurf/workflows/*.md` | tên file | Không có namespace |

(Theo tài liệu các agent tới 2026-06; kiểm lại khi viết plan.)

- **`:` trong tên file hỏng trên Windows** (NTFS cấm `:`), và với Claude Code thì `:` trông như lệnh
  của plugin tên `aw-require`. Chỉ Gemini có `:` gốc, nhưng qua thư mục con — tức là mỗi adapter phải
  sinh khác nhau, trái với test so sánh (`AW_COMPARE=1`, output giống hệt giữa các adapter).
- **`-` chạy ở mọi agent** và đã là quyết định có sẵn (chú thích `TIEN_TO_LENH`).
- ⇒ Nếu có lệnh con: **`aw-{stage}-{việc}`**, không dùng `:`.

### 3.2 Có nên có lệnh con không

Hiện chỉ stage `require`, `design` có ô "Approved by human" do máy tick qua `/aw-approvals`
(`aw approvals tick`); `plan`, `verify`, `deploy` là xác nhận trong hội thoại, không có ô.

| Hướng | Được | Mất |
|---|---|---|
| A. `/aw-require-approve`, `/aw-design-approve` | Gõ thẳng, gợi ý khi gõ `/aw-require` | +2 lệnh (nhiều hơn nếu thêm việc khác: `-clarify`…); trùng việc với `/aw-approvals`; hai đường duyệt cho một ô |
| B. Tham số: `/aw-approvals require` (lọc theo stage) | 0 lệnh mới; Claude Code (`$ARGUMENTS`) và Cursor (chữ sau tên lệnh) đều nhận tham số — đã dùng cho `/aw-plan <input>` | Phải nhớ tên stage làm tham số |
| C. Giữ nguyên | Không tốn gì | Không lọc được theo stage |

**Đề xuất: B.** Một ô duyệt, một đường; không thêm lệnh vào menu `/aw-`. Lệnh tiện ích không vào
ngữ cảnh khi không gọi (`disable-model-invocation`), nên lý do chọn là gọn menu và "một luật một chỗ",
không phải token.

## 4. Đánh số khớp stage (chốt)

- File phase `NN-<id>.md`: `NN` = `NN` của file stage cùng id (`sdlc/stages/NN-<id>.md`).
- Summary bỏ "Bước x/6" viết tay; dạng mới `Stage NN/07 · …` (hoặc `Bước NN+1/8`, xem §5.6),
  `deploy` thêm "(tuỳ chọn)". Stage `operate` (07) không có phase — số vẫn giữ chỗ.
- `check-sdlc.sh` **chặn** (luật cấu trúc, `# giữ:` không cần vì không phải luật của artifact):
  - phase `id` ≠ `implements`;
  - `NN` file phase ≠ `NN` file stage;
  - số trong summary ≠ `NN` stage;
  - id lệnh tiện ích trùng id một stage (tránh `/aw-plan` kiểu cũ tái diễn).
- Test: `tools/tests/20-sdlc-conformance.sh` — mỗi luật một ca chặn + engine hiện tại đạt.

## 5. Đề xuất chờ người chốt

### 5.1 Đổi tên tới đâu
- **Đề xuất:** đổi cả id phase, `aw check <id>`, `tools/check-<id>.sh`, `exit_machine`, `BL_CHECKERS`
  (`tools/lib/commands.sh`), CLI `aw ship …` → `aw deploy …`. Lý do: `/aw-breakdown` mà
  `aw check plan` thì lại lệch đúng chỗ đang sửa.
- **Giữ tên artifact** (`intake.md`, `spec.md`, `plan.md`, `review.md`, `merge-request.md`, `ship.md`):
  artifact không phải stage; checker khớp chuỗi tên file; repo đích đã có artifact cũ trong branch việc.
- `aw journal report` đọc nhật ký cũ: ánh xạ tên phase cũ → mới.

### 5.2 Lệnh con duyệt
- **Đề xuất:** hướng B ở §3.2 (`/aw-approvals <stage>`). Nếu chọn A: tên `aw-{stage}-approve`.

### 5.3 Chuyển tiếp tên cũ
- Bốn tên cũ không va chạm (`intake`, `spec`, `review`, `ship`): **đề xuất** giữ một bản phát hành làm
  bí danh — `aw check intake` chạy `check-plan.sh` và in một dòng "đã đổi tên"; lệnh `/aw-intake` cũ
  không sinh nữa (adapter build xoá file sinh cũ, vì có dấu "SINH TỰ ĐỘNG").
- **`plan` đổi nghĩa** (cũ = breakdown, mới = tiếp nhận) — không làm bí danh được:
  - `/aw-plan` (mới) chạy ở main checkout; gọi trong worktree của một việc đã có `intake.md` → dừng,
    chỉ `/aw-breakdown` (bổ sung task cho `RVW-NNN` cũng ở đó).
  - `aw check plan` ở bản chuyển tiếp: thư mục việc không có `plan.md` mà có `intake.md` → kiểm như
    tiếp nhận; còn lại in "giờ là `aw check breakdown`" và trả SAI THAM SỐ (không âm thầm kiểm nhầm).
  - `CHANGELOG` mục `Thay đổi`, chữ đậm: ai có script/CI gọi `aw check plan` phải sửa.

### 5.4 Rollback (`CAP-deploy-03`)
- **Đề xuất:** không làm trong SP31 (deploy còn tuỳ chọn). Chỉ sửa `note` stage `deploy` ở
  `workflow.yaml`: bỏ "release, tag, triển khai" (đã `out_of_scope` qua `CAP-deploy-02`), còn
  "Rollback chưa làm". Rollback thành dự án con riêng khi deploy thành bắt buộc.

### 5.5 Lệnh tiện ích làm hộ stage
- `/aw-approvals` tick ô mà `CAP-require-03`, `CAP-design-03` cần; `/aw-clarify` đóng vòng
  `CAP-require-02`; `/aw-refactor` là đầu vào stage `plan`. `check-sdlc.sh` không thấy phần này.
- **Đề xuất:** ngoài SP31. Ghi lý do trong `docs/kien-truc.md` § Interface SDLC; nếu sau này cần thì
  thêm khoá chỉ-tham-khảo `supports: [CAP-…]` (không tính vào trạng thái stage) — dự án con riêng.

### 5.6 Dạng số trong summary
- **Đề xuất:** `Stage 01/07 · …` — số đúng như file stage, không cần cộng một. Phương án khác:
  `Bước 2/8 · …` (đếm từ 1, quen với người dùng hơn).

### 5.7 Operate và breakdown không duyệt
- `CAP-operate-02`: giữ như SP16 (gap, `[INCIDENT]` đã có) — ngoài SP31.
- `breakdown` → `implement` không có người duyệt (`INV-005` chỉ gắn `require`, `design`): đúng ý đồ vì
  task truy về DEC đã duyệt (`INV-001`, `INV-002`). **Đề xuất:** thêm một câu lý do vào
  `docs/kien-truc.md` trong PR SP31, không đổi luật.

## 6. Tài liệu đi kèm (khi implement)

README, `docs/huong-dan.md` (mọi tên lệnh), `docs/kien-truc.md` (bảng phase, § Interface SDLC — tên
phase = tên stage, lý do `-` thay `:`), `docs/thuat-ngu.md` (bỏ cặp tên phase/stage), `docs/interface-sdlc.md`,
`adapters/*/README.md`, `changes/<branch>.md` mục `Thay đổi` (đổi tên lệnh, việc người dùng phải làm:
`aw adapter build` lại, sửa script gọi `aw check plan`).
