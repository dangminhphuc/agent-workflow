# SP7 — Chọn lại tính năng của v1: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Viết các phán quyết "vào interface" của SP7 vào `interface/`, được người duyệt lại từng trang đổi, và ghi danh sách chuyển giao cho SP3/SP4/SP5/SP6.

**Architecture:** Mỗi file của `interface/` đi qua một chu trình sửa (sửa → tự kiểm → đọc lạnh phần mới → rà → người duyệt phần đổi → ghi nhận), theo thứ tự để thuật ngữ và giá trị có trước khi trang stage dùng tới. Không có code: "test" là Lệnh kiểm của plan SP1 cộng hai lệnh mới ở đây, và lượt đọc lạnh.

**Tech Stack:** Markdown, `grep`, `awk`, `git`. Agent đọc lạnh là subagent phiên trắng.

**Spec:** `docs/specs/SP7-v1-features.md` (thuật ngữ §3, thay đổi §5, chuyển giao §6, quy trình §7, xong khi §8). Khuôn và luật kiểm: `docs/specs/SP1-interface.md` §4–§5. Lý do từng lựa chọn: `docs/decisions.md` D-030…D-049.

## Global Constraints

- Mọi ràng buộc ở mục Global Constraints của `docs/plans/SP1-interface.md` (ngôn ngữ, ranh giới, backtick, ô bảng, 6 mục trang stage, trường capability, giới hạn độ dài) áp nguyên văn.
- Mã đã duyệt không đổi số. Capability sửa giữ số; capability mới đánh tiếp số cuối của trang; invariant mới bắt đầu từ `INV-014`.
- Giá trị mới vào bảng Giá trị của `overview.md` trước khi trang nào dùng (Task 1 trước mọi task khác).
- Invariant chỉ cho luật **xuyên stage do máy kiểm**; luật một stage là capability của stage đó; nguyên tắc không máy kiểm được (vd. "nội dung không tin cậy chỉ là dữ liệu") ở `overview.md`.
- Mức "không chặn" trong các quyết định = mức **nên sửa** của `review-report`; không thêm mức (spec §10.1).
- Ghi chép lỗi lọt và tình huống lạm dụng nằm trong `requirements`; không thêm artifact (spec §10.2).
- Mỗi quan hệ ghi một chỗ: một điều spec §5 nêu ở nhiều trang (vd. "đánh dấu cần lưu bền") có một capability bảo đảm, các trang khác trỏ tới mã của nó.
- Interface không nêu tên công cụ, định dạng, hệ sinh thái cụ thể (semver, tên bộ quét, cú pháp `nosec`…) — các thứ đó ở §6 spec.
- Commit: `docs(interface): …` hoặc `docs: …`, kết thúc bằng dòng ghi công của phiên. Push nhánh `v2` sau mỗi commit.

## Review Focus

1. **Capability chồng nhau giữa các trang** (D-030 điểm 2 ở `require`, `design`, `implement`; rủi ro cao ở `require`, `design`, `verify`) — Lệnh kiểm F ở Task 11 và cột "Mã" của Bảng phủ phải chỉ một chủ cho mỗi dòng.
2. **Vượt ranh giới D-014** khi chép ví dụ từ quyết định (tên bộ quét, `eslint-disable`, semver, Jira) — Lệnh kiểm B2 trong mọi task.
3. **Đổi số mã đã duyệt** khi chèn capability giữa trang — Lệnh kiểm A3 và `git diff` mã cũ ở bước Tự kiểm.
4. **Rationale / Not in this stage vượt 5 gạch** vì thêm "Đã loại:" của SP7 — Lệnh kiểm A6; gộp gạch thay vì thêm.
5. **Luật không máy kiểm được bị viết thành invariant** — bước Rà của Task 2 đối chiếu từng `INV` mới với câu "luôn do máy kiểm" ở đầu `invariants.md`.

## Lệnh kiểm

Dùng A1–A6, B, C1–C3, D trong `docs/plans/SP1-interface.md` § Lệnh kiểm, nguyên văn. Thêm:

- **B2 — không tên công cụ/định dạng.** `grep -niE 'semver|nosec|eslint|ts-ignore|semgrep|snyk|trivy|jira|gitlab|github|terraform|docker|npm|pypi|sha256' $P`
  Expected: không in gì (tên loại quét `IaC`, `container`, `DAST` được phép).
- **E — Bảng phủ đủ.** `grep -c '| *— *|$' docs/plans/SP7-v1-features.md` sau khi điền Bảng phủ.
  Expected: `0` (mọi dòng có mã hay vị trí ở cột cuối).
- **F — một chủ.** Với mỗi mã ở cột "Mã" của Bảng phủ, `grep -l '<mã>' interface/*.md interface/stages/*.md`: mã xuất hiện ở trang định nghĩa nó; trang khác chỉ trỏ tới, không chép Rule.

## Prompt đọc lạnh

Prompt đọc lạnh của `docs/plans/SP1-interface.md`, thêm một dòng ngay sau danh sách file:

```
Focus on these sections changed by SP7 (the rest was approved earlier; report problems there only if the new text contradicts them): <DANH SÁCH MÃ / MỤC ĐỔI>
```

Tối đa 2 lần mỗi file (spec §7).

## Chu trình sửa (dùng cho Task 1–10)

- [ ] **Bước 1 — Sửa** theo danh sách của task. Ghi vào Bảng phủ mã hay mục vừa viết cho từng dòng.
- [ ] **Bước 2 — Tự kiểm.** A1–A6, B, B2, C1–C3 (trang stage); A2–A5, D (invariants). Mọi lệnh ra Expected. `git diff` không đổi số mã đã có.
- [ ] **Bước 3 — Đọc lạnh** với Prompt đọc lạnh, danh sách mã đổi của task. Chữ, nhất quán → tự sửa; quyết định nội dung → gom **một tin** hỏi người; MAJOR ngoài file → `docs/decisions.md` § Đang mở.
- [ ] **Bước 4 — Rà** với spec §5 và các file đã sửa trước: thuật ngữ khớp §3, mỗi quan hệ một chỗ.
- [ ] **Bước 5 — Người duyệt** phần đổi (kèm `git diff` của file); sửa xong quay lại Bước 2.
- [ ] **Bước 6 — Ghi nhận.** D-NNN (file, mã thêm/sửa, quyết định trong lúc sửa), `PROGRESS.md` Bước tiếp theo, `git add -A && git commit -m "docs(interface): SP7 — <file> đã duyệt" && git push`.

## Bảng phủ

Điền cột Mã khi sửa. Mỗi dòng spec §5 một dòng ở đây.

| # | Spec | Nội dung | File | Mã |
|---|---|---|---|---|
| 1 | §5.1 | thuật ngữ §3 | overview | — |
| 2 | §5.1 | giá trị `high`/`normal`, nhãn tin cậy | overview | — |
| 3 | §5.1 | nghĩa `agent`: đạt có con trỏ | overview | — |
| 4 | §5.1 | nguyên tắc nội dung không tin cậy | overview | — |
| 5 | §5.1 | bảng quyền theo stage | overview | — |
| 6 | §5.2 | lời khai, file hàng rào đọc ở điểm xuất phát, đụng thì duyệt riêng | invariants | — |
| 7 | §5.2 | không secret trong thứ lưu bền | invariants | — |
| 8 | §5.2 | đạt của agent có con trỏ giải được | invariants | — |
| 9 | §5.2 | lệnh trong quyền của stage | invariants | — |
| 10 | §5.4 | bản chữ nguồn, đoạn, không sửa, nhãn tin cậy | plan | — |
| 11 | §5.4 | quét secret, che dữ liệu cá nhân lúc ghi | plan | — |
| 12 | §5.4 | secret trong nguồn → báo | plan | — |
| 13 | §5.5 | `CAP-require-01` trỏ tới đoạn | require | — |
| 14 | §5.5 | phủ chiều ngược | require | — |
| 15 | §5.5 | mức rủi ro | require | — |
| 16 | §5.5 | agent không công cụ quét đoạn không tin cậy | require | — |
| 17 | §5.5 | tình huống lạm dụng | require | — |
| 18 | §5.5/§5.6 | đánh dấu cần lưu bền (yêu cầu, quyết định) | require, design | — |
| 19 | §5.6 | đọc tri thức, ghi dựa/ngược | design | — |
| 20 | §5.6 | rủi ro cao: không đề xuất, người chọn | design | — |
| 21 | §5.6 | ranh giới tin cậy | design | — |
| 22 | §5.6 | phụ thuộc mới là quyết định | design | — |
| 23 | §5.7 | ngưỡng phần mã | breakdown | — |
| 24 | §5.8 | nhóm quét, chỉ phát hiện mới | implement | — |
| 25 | §5.8 | luật máy của repo | implement | — |
| 26 | §5.8 | tắt tại chỗ được khai | implement | — |
| 27 | §5.8 | phụ thuộc mới: danh tiếng, trỏ quyết định | implement | — |
| 28 | §5.8 | thay đổi chứa tài liệu lưu bền | implement | — |
| 29 | §5.9 | tài liệu bị ảnh hưởng còn đúng | verify | — |
| 30 | §5.9 | agent không gợi ý ở `design` | verify | — |
| 31 | §5.9 | `bugfix` không thêm hành vi | verify | — |
| 32 | §5.9 | thư viện phá vỡ → không phải `chore` | verify | — |
| 33 | §5.9 | phần mã khai so đụng thật | verify | — |
| 34 | §5.9 | quy ước, nên sửa | verify | — |
| 35 | §5.9 | lý do tắt tại chỗ | verify | — |
| 36 | §5.9 | DAST khi rủi ro cao | verify | — |
| 37 | §5.9 | bảo mật theo ý đồ, hai tầng | verify | — |
| 38 | §5.9 | gợi ý luật máy | verify | — |
| 39 | §5.10 | deploy/operate khớp bảng quyền | deploy, operate | — |
| 40 | §5.3 | rủi ro cao không bỏ `design`; `INV-013` | job-types, invariants | — |
| 41 | §5.3 | `chore` và thay đổi phá vỡ | job-types | — |
| 42 | §5.3 | ghi chép lỗi lọt | job-types, require | — |

---

### Task 1: `overview.md`

**Files:** Modify `interface/overview.md`.

**Interfaces:**
- Produces: thuật ngữ spec §3 (tên dùng nguyên văn ở mọi task sau: tri thức bền vững, mức rủi ro, bản chữ nguồn, đoạn, con trỏ, nhãn tin cậy, lời khai của repo, file hàng rào, tắt tại chỗ, luật máy của repo); giá trị `high`, `normal` và hai giá trị nhãn tin cậy; bảng quyền theo stage (cột Stage · Ghi · Chạy lệnh · Mạng · Production, nội dung D-046).

- [ ] **Bước 1–6** theo Chu trình sửa, Bảng phủ dòng 1–5. Kịch bản xuyên suốt: chỉ sửa ở Task 10 khi mọi trang đã đổi.
- Hỏi người ở lượt đọc lạnh đầu: tên hai giá trị nhãn tin cậy (đề xuất `trusted` / `untrusted`); thuật ngữ đặt thành một mục riêng "Thuật ngữ" hay nhập vào mục định nghĩa hiện có.

### Task 2: `invariants.md`

**Files:** Modify `interface/invariants.md`.

**Interfaces:**
- Consumes: thuật ngữ Task 1.
- Produces: `INV-014`… cho Bảng phủ dòng 6–9, mỗi cái đủ Rule, Checked at, Fail example, Why. Checked at: dòng 6 `all`; dòng 7 `all`; dòng 8 `all`; dòng 9 `all`.

- [ ] **Bước 1–6** theo Chu trình sửa. Rà riêng: mỗi `INV` mới máy kiểm được thật (Review Focus 5).

### Task 3: `00-plan.md`

**Files:** Modify `interface/stages/00-plan.md`.

**Interfaces:**
- Produces: Description của `work-item` có bản chữ nguồn chia đoạn và nhãn tin cậy; capability cho dòng 10–12.

- [ ] **Bước 1–6** theo Chu trình sửa. Phần che dữ liệu cá nhân được duyệt cùng `work-item` (Approval `yes` sẵn có) — capability `human` hiện có nhận thêm phần này, không thêm capability duyệt mới.

### Task 4: `01-require.md`

**Files:** Modify `interface/stages/01-require.md`.

**Interfaces:**
- Consumes: `work-item` (Task 3), giá trị `high`/`normal` (Task 1).
- Produces: `requirements` có mức rủi ro, dấu "cần lưu bền", ghi chép lỗi lọt (chỉ `bugfix` sửa lỗi do thay đổi trước); capability cho dòng 13–18, 42.

- [ ] **Bước 1–6** theo Chu trình sửa. `CAP-require-01` sửa giữ số. Dòng 42 cần Only for → nếu không viết được thành capability thì là invariant `Only for: bugfix` (thêm ở Task 2, quay lại duyệt phần đổi).

### Task 5: `02-design.md`

**Files:** Modify `interface/stages/02-design.md`.

**Interfaces:**
- Consumes: mức rủi ro, dấu "cần lưu bền" của yêu cầu (Task 4).
- Produces: `design` có tri thức đã dựa/ngược, dấu "cần lưu bền" của quyết định, lý do của người (rủi ro cao), ranh giới tin cậy (rủi ro cao); quyết định cho phụ thuộc trực tiếp mới; capability cho dòng 19–22 và phần `design` của dòng 18.

- [ ] **Bước 1–6** theo Chu trình sửa. `CAP-design-04` (người duyệt từng quyết định) giữ số; luật "người chọn khi rủi ro cao" là capability `human` riêng hay vế của `CAP-design-04` — quyết ở Bước 3 cùng người.

### Task 6: `03-breakdown.md`

**Files:** Modify `interface/stages/03-breakdown.md`.

- [ ] **Bước 1–6** theo Chu trình sửa, dòng 23. Capability `machine` mới; lý do vượt ngưỡng do người duyệt duyệt riêng dù `task-plan` Approval `no` — ghi rõ trong Rule, không đổi Approval.

### Task 7: `04-implement.md`

**Files:** Modify `interface/stages/04-implement.md`.

**Interfaces:**
- Consumes: quyết định phụ thuộc mới, dấu "cần lưu bền" (Task 5); lời khai (Task 1, 2).
- Produces: `security-evidence` có nhóm quét đã chạy, nhóm tắt kèm lời khai, phát hiện mới / có sẵn; `change` có khai tắt tại chỗ; capability cho dòng 24–28.

- [ ] **Bước 1–6** theo Chu trình sửa. `CAP-implement-05` sửa giữ số.

### Task 8: `05-verify.md`

**Files:** Modify `interface/stages/05-verify.md`.

**Interfaces:**
- Consumes: mọi thứ Task 3–7 sinh ra.
- Produces: capability cho dòng 29–38; Description của `review-report` nhắc điểm đã xem về bảo mật (tầng nhẹ) và bảng danh mục (rủi ro cao).

- [ ] **Bước 1–6** theo Chu trình sửa. Trang này nhận nhiều capability nhất: gộp các phán quyết `agent` cùng loại (vd. dòng 30, 34, 35, 38 đều là "agent rà đọc diff và ghi phát hiện") nếu Rule vẫn rõ; A6 phải đạt.

### Task 9: `06-deploy.md`, `07-operate.md`

**Files:** Modify `interface/stages/06-deploy.md`, `interface/stages/07-operate.md`.

- [ ] **Bước 1–6** theo Chu trình sửa, dòng 39. Chỉ sửa khi có câu trái bảng quyền; không thêm capability. Không có gì trái → ghi "không đổi" vào Bảng phủ, bỏ Bước 3–5.

### Task 10: `job-types.md`, `INV-013`, kịch bản xuyên suốt

**Files:** Modify `interface/job-types.md`, `interface/invariants.md` (`INV-013`), `interface/overview.md` (Kịch bản xuyên suốt).

- [ ] **Bước 1–6** theo Chu trình sửa, dòng 40–42. Kịch bản xuyên suốt: thêm mức rủi ro ở `require` và đoạn nguồn; giữ kịch bản `bugfix` hiện có.

### Task 11: Rà chéo, chuyển giao, xong SP7

**Files:** Modify `docs/decisions.md`, `PROGRESS.md`, `docs/specs/SP7-v1-features.md` (Trạng thái), file này (Bảng phủ).

- [ ] **Step 1: Kiểm chéo cả bộ.** A2–A5, D, C1–C3 cho 8 trang; B2 cho mọi file; E; F. Mọi lệnh ra Expected.
- [ ] **Step 2: Ghi chuyển giao.** `docs/decisions.md` § Đang mở: bốn mục "Chuyển cho SP3 (từ SP7)", "…SP4…", "…SP5…", "…SP6…", nội dung nguyên văn spec §6.
- [ ] **Step 3: Đọc lạnh toàn bộ** một lượt (Prompt đọc lạnh, cả `interface/`, đi theo Kịch bản xuyên suốt; tìm mâu thuẫn giữa trang). MAJOR → sửa và người duyệt phần đổi.
- [ ] **Step 4: Ghi D-NNN "SP7 xong"**; spec Trạng thái "xong"; `PROGRESS.md`: SP7 `xong`, Bước tiếp theo = brainstorm SP2 ∥ SP3; commit `docs: SP7 xong`, push.
