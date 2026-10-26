# Requirement — Phase spec viết đúng dạng ngay lần đầu (tiết kiệm token)

- **Loại:** tối ưu quy trình agent (phase `spec`)
- **Trạng thái:** đợt 1 đã làm ở [#109](https://github.com/dangminhphuc/agent-workflow/pull/109) (REQ-001…005);
  REQ-006 chờ số liệu SP9 — roadmap SP35
- **Interface:** `INV-012` (máy giữ pointer giữa artifact đúng — xem §6.1); `CAP-require-01`…`03` giữ nguyên

## 1. Vấn đề

Agent chạy `/aw-spec` hiện thường:

1. Viết `spec.md` + `open-questions.md` khi chưa đọc kỹ template.
2. Chạy `aw toc` → lộ lỗi heading / anchor.
3. Sửa file nhiều lần, có khi bằng `sed`/`perl`.
4. Chạy `aw toc` 3–4 lần, rồi `aw check spec`.

Hậu quả: tốn ~2–3 lần token cần thiết (ước lượng của người dùng: 50–70K so với 15–20K mỗi feature).

Gốc rễ: agent không biết trước dạng chính xác mà máy kiểm; vòng sửa–chạy–sửa dùng `aw toc`
như trình dò lỗi thay vì công cụ hoàn tất.

## 2. Mục tiêu

Một lượt: đọc template → viết đúng dạng → `aw toc` một lần → `aw check spec` đạt.

| | Hiện tại | Mục tiêu |
|---|---|---|
| Lần viết/sửa artifact | 3–4 | 1 (+ sửa nội dung do checker LLM, không tính) |
| Lần chạy `aw toc` | 3–4 | 1 |
| Sửa link bằng `sed`/`perl` | có | không |
| Token phase spec | 1x mốc | ≤ 1/3 mốc (đo bằng SP9 journal) |

## 3. Dạng đúng (theo engine hiện tại — nguồn: template, không phải bản nháp của người dùng)

Bản nháp yêu cầu có vài điểm lệch với engine; requirement này lấy engine làm chuẩn:

| Bản nháp | Engine thực tế | Nguồn |
|---|---|---|
| Field dạng `**Quote:** "..."` | Dòng list `- Quote:` + khối `> …` nguyên văn, không ngoặc kép; `Source`, `Priority`, `Description`, `Acceptance criteria` cũng là `- Field:` | `workflow/templates/spec.md` |
| `**Risk:**` không có `Reason` | `- **Risk:**`, `- **Reason:**`, `- **Design:**`, `- [ ] **Approved by human**` | `workflow/templates/spec.md` |
| Phải viết anchor đầy đủ `#q-001--title` | Viết anchor rút gọn `#q-001`, `#req-001`; `aw toc` tự mở rộng | `workflow/rules/general.md` §6, `tools/toc.sh` |
| `**Temporary assumption:**` | `- **Assumption:**`, kèm `Source says`, `Question`, `Ask`, `Status`, `Answer` | `workflow/templates/open-questions.md` |
| `aw toc` exit 1 = "chỉ cảnh báo" | Nhãn `CÒN LINK SAI` = còn link chết, phải sửa; chỉ `ĐÃ KHỚP` mới là xong | `tools/toc.sh` (`kq_khai`) |
| Thứ tự mục `Constraints`, `Source Conflicts`… | Theo template: `Sources`, `Context`, (`Glossary` tuỳ chọn), `Requirements`, … | `workflow/templates/spec.md` |

Điểm khớp, giữ nguyên: heading `### REQ-NNN — Tiêu đề`, `### Q-NNN — Câu hỏi`, `### FND-NNN — …`;
`## Contents` để trống, máy sinh; `## Questions` là mục cha của các `Q-NNN`.

## 4. Requirements

### REQ-001 — Đọc dạng trước khi viết

Body phase `spec` bắt agent đọc template `spec.md`, `open-questions.md`, `spec-findings.md`
(từ engine đã cài) **trước** khi viết artifact đầu tiên, rồi chép khung template làm điểm xuất phát
thay vì viết từ trí nhớ.

- [x] `workflow/phases/01-spec.md` có bước đọc template đứng trước bước viết (mở đầu § Steps: "Shape first, one pass").
- [x] Lệnh adapter sinh ra nêu rõ đường dẫn template trong repo đích (`ds_mau` in `.agent-workflow/.engine/templates/…`).

### REQ-002 — Viết anchor rút gọn, không tự tính anchor đầy đủ

Agent chỉ viết `[spec.md § REQ-001](spec.md#req-001)`, `open-questions.md#q-001`; không tự gõ
`#req-001--tiêu-đề`. Luật đã có ở `general.md` §6 — phase spec chỉ trỏ tới, không chép lại.

- [x] Không phase/checker nào yêu cầu agent gõ anchor đầy đủ (kiểm 2026-10-26: `grep anchor` trong `workflow/phases/`, `workflow/checkers/` không có kết quả liên quan).

### REQ-003 — `aw toc` một lần, cuối lượt viết

Trình tự trong phase spec: viết xong cả ba artifact → `aw toc <dir>` một lần → `aw check spec`.
Không chạy `aw toc` sau từng file.

- [x] Phase body nói rõ "viết hết rồi mới chạy `aw toc`" (đầu § Steps + bước 14; `general.md` §6 và `checkers/spec.md` thôi chạy theo từng file).
- [ ] Fixture chép nguyên template thì `aw toc` lần đầu chưa `ĐÃ KHỚP`: `templates/spec-findings.md` còn `[spec.md § <mục>](spec.md#<anchor>)`. Lỗi giờ nêu rõ "còn chỗ giữ chỗ" nên sửa một lần là xong; bỏ hẳn chỗ giữ chỗ đó khỏi template là việc còn lại.

### REQ-004 — Lỗi dạng phải tự sửa được trong một lượt

Khi `aw toc` / `aw check spec` báo lỗi dạng, output nêu đủ để sửa một lần: file, dòng, dạng sai,
dạng đúng. Agent không cần dò thêm hay chạy lại để biết lỗi kế tiếp.

- [x] Mỗi lỗi dạng in kèm dạng mong đợi: link chết nêu `dạng đúng là mục #…`, mã không có heading nêu `không có heading nào mã Q-009`, placeholder nêu `còn chỗ giữ chỗ` — kèm số dòng.
- [x] Checker in **mọi** lỗi dạng một lượt, không dừng ở lỗi đầu (đã vậy từ trước; có ca test hai lỗi ở hai file cùng in).
- [x] Test hai chiều: `tools/tests/01-fixture-engine-toc.sh` "link tới mã không có → còn chặn sau một lượt aw toc", "heading đổi → aw toc một lượt, ĐÃ KHỚP".

### REQ-005 — Không cần `sed`/`perl` để sửa link

Mọi link chết do anchor sai (heading đổi, anchor rút gọn) được `aw toc` sửa; lỗi còn lại chỉ là
link tới mục không tồn tại, cần sửa nội dung.

- [x] Đổi tiêu đề một REQ rồi chạy `aw toc` một lần → mọi link tới nó (cùng file và khác file) đúng (`mo_rong` mở rộng lại theo mã ID).

### REQ-006 — Đo được

Token phase spec đo bằng journal (SP9 / SP9b) trước và sau thay đổi, cùng một bộ feature mẫu.

- [ ] Số lần gọi `aw toc` trong một phiên spec được ghi vào journal.
- [ ] Báo cáo so sánh trước/sau trong PR thực hiện; mục tiêu ≤ 1/3 token, ít nhất ≤ 1/2.

## 5. Ngoài phạm vi

- Đổi dạng template (field, heading) — chỉ cho agent theo đúng dạng hiện có.
- Vòng sửa nội dung do checker LLM (`spec-findings.md`) — đó là sửa ý, không phải sửa dạng.
- Tối ưu token các phase khác (có thể áp cùng mẫu sau, thành dự án con riêng).

## 6. Chốt (2026-10-26, đợt 1 — PR #109)

1. **Interface:** không thêm capability cho riêng `require` — REQ-004/005 là luật liên stage
   (mọi artifact đều có link tới mục). Ghi thành **`INV-012`** trong `sdlc/invariants.md`,
   `Enforced by: tools/lib/toc.sh`, gắn `# giữ: INV-012` ở luật kiểm link; `CAP-require-01…03` giữ nguyên.
2. **Mức chặn:** REQ-001/003 là chỉ dẫn trong phase body + `general.md` §6, **không** thêm luật máy
   đếm số lần `aw toc` (chưa có số liệu, nguyên tắc 3 của roadmap). Phần máy kiểm chỉ là INV-012:
   link chết vẫn chặn, nhưng một lượt sửa là đủ.
3. **REQ-006:** làm REQ-001…005 trước (xong ở #109), đo sau khi có journal của SP9.
4. **Roadmap:** SP35, trạng thái `một phần` (còn REQ-006 và chỗ giữ chỗ trong template
   `spec-findings.md`).
