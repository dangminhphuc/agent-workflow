---
id: spec
name: Viết đặc tả
summary: Bước 2/6 · Biến BRD/PRD/ticket thành spec.md kiểm chứng được và liệt kê điểm mù cần người chốt
required: true
inputs:
  - intake.md
  - confluence
  - jira
  - file
outputs:
  - spec.md
  - open-questions.md
exit_machine:
  - aw check spec
exit_human:
  - Chủ repo duyệt danh sách yêu cầu và phần "Out of scope"
  - Chủ repo duyệt nhãn "Blocking" của từng [OPEN-QUESTION] (blocking | review-blocking | non-blocking)
  - Chủ repo duyệt "Risk" (high → design chạy Mode 2, người phác D-xx trước)
  - Duyệt xong, chủ repo tự tick ô "Approved by human" — design (chore thì plan) chặn tới lúc đó
needs_clean_context: true
trace_rule: true
---

# Phase 01 — Đặc tả

## Mục tiêu

Biến yêu cầu nghiệp vụ thành đặc tả **kiểm chứng được**, và lộ ra chỗ nguồn nói chưa rõ hoặc mâu thuẫn. **Không sinh yêu cầu mới** — chỉ dịch và làm sắc yêu cầu đã có. Luật nhãn nguồn: `rules/truy-vet-nguon.md`.

## Đầu vào

- `intake.md` — phải qua `aw check intake`. Chưa có → dừng, chạy `/aw-intake`.
- Mọi input liệt kê trong `intake.md`. Không đọc nguồn ngoài danh sách (muốn thêm → thêm vào `intake.md` trước).
- `aw rules spec` — đọc từng file nó in.

| Input | Cách đọc | Nhãn nguồn trong spec |
|---|---|---|
| `[CONFLUENCE]` | MCP Atlassian | `[CONFLUENCE]` URL + heading |
| `[JIRA]` | MCP Atlassian | `[JIRA]` mã issue + URL |
| `[FILE]` (kể cả incident note) | Đọc trực tiếp | `[FILE]` đường dẫn + heading |
| `[HUMAN]` | Nguyên văn trong `intake.md` | `[FILE] intake.md § Input` |

## Theo loại việc

| Loại | Spec phải có thêm |
|---|---|
| `bugfix` | `## Reproduction`: `Steps to reproduce:`, `Actual behavior:`, `Expected behavior:` |
| `refactor` | Mỗi YC có `Type: preserve \| structural`, **không có YC hành vi mới**. YC preserve có `Protected by: \`<file test>\`` — file **có sẵn trên nhánh gốc** |
| `perf` | Như refactor + ít nhất một `Type: performance` có `Target:` bằng số |

Refactor vùng chưa có test bảo vệ → checker chặn. Viết test thành việc riêng trước, hoặc thu hẹp phạm vi.

## Việc phải làm

1. **Đọc hết nguồn.** Ghi định danh chính xác và **phiên bản** đã đọc (Confluence: số version; Jira: `updated`; `[FILE]`: sha commit) vào `## Sources`. Không đọc lướt rồi tóm tắt.
2. **Trích nguyên văn** câu mang yêu cầu trước khi diễn giải — tách "nguồn nói gì" khỏi "ta hiểu thế nào".
3. **Viết YC kiểm chứng được.** Mỗi `YC-NNN`:
   - ít nhất một `- [ ] …` **quan sát được từ ngoài** ("dưới 300ms với 10k bản ghi", không phải "phải nhanh");
   - `Priority: must | should` — `should` **chỉ khi nguồn nói vậy** ("nice to have", "phase 2 nếu kịp"); nguồn im lặng = `must`.
4. **Rà NFR.** Với từng nhóm: việc có đụng không, nguồn nói gì?

   | Nhóm | Câu hỏi |
   |---|---|
   | Phân quyền | Ai được xem / sửa / duyệt? Vai trò nào bị chặn? |
   | Audit | Có phải lưu ai, lúc nào, giá trị cũ? |
   | Hiệu năng | Bao nhiêu bản ghi, người dùng đồng thời? |
   | Dữ liệu nhạy cảm | Dữ liệu cá nhân, tài chính? Che, mã hoá, thời hạn lưu? |
   | Tương thích ngược | API / file / báo cáo bên ngoài nào đang dùng thứ sắp đổi? |
   | Lỗi & khôi phục | Hệ thống ngoài lỗi thì sao? Thử lại, đảo ngược? |

   Nguồn có nói → YC. Có đụng mà nguồn im lặng → `[OPEN-QUESTION]` (thường `review-blocking`). Không đụng → bỏ qua. Không bịa số liệu.
5. **Bối cảnh:** vai trò người dùng theo nguồn vào `## Context`. Từ dễ hiểu lệch ("kỳ", "hạch toán") → `## Glossary` (tuỳ chọn), mỗi thuật ngữ kèm nguồn.
6. **Gắn nhãn nguồn** cho từng YC.
7. **Tách điểm mù:** chỗ nguồn không rõ → `[OPEN-QUESTION]` + mục trong `open-questions.md` với giả định tạm, "nếu sai phải làm lại gì", và `Blocking` đề xuất (bảng mức chặn trong `rules/truy-vet-nguon.md`). Chỉ `blocking` dừng flow ngay; lệnh `clarify` dẫn người trả lời.
8. **Rà mâu thuẫn** giữa các nguồn vào `## Source conflicts`. Cột "Xử lý" **chỉ** trỏ tới điểm mù (`open-questions.md § YC-NNN`) hoặc nguồn đã chốt (comment `[JIRA]` của PO, page `[CONFLUENCE]` mới hơn…). Không có → "Không phát hiện mâu thuẫn."
9. **`## Out of scope`:** liệt kê thẳng điều *không* làm — chặn phase sau làm quá tay. Không có → "Không có."
10. **`## Constraints & dependencies`:** hệ thống ngoài, quy định pháp lý–kế toán, deadline, việc team khác — kèm nguồn. Không có → "Không có ràng buộc hay phụ thuộc ngoài."
11. **Đề xuất `Risk`:** `high` khi đụng tiền/hạch toán, tích hợp mới, schema lõi, hoặc khó đảo ngược; còn lại `normal`. Lý do một dòng. `high` → design chạy Mode 2.
12. **Để ô `- [ ] **Approved by human**` chưa tick.** Mỗi lần sửa nội dung spec (kể cả chạy lại, kể cả `clarify`) đều **bỏ tick**. Tick + nội dung đổi → `aw check` chặn (hook `aw guard`, nếu cài, tự bỏ tick).
13. **Ghi dấu đầu vào:** `aw based-on <thư-mục-feature> spec.md intake.md`.

## Đầu ra

- `spec.md` theo `templates/spec.md`.
- `open-questions.md` theo `templates/open-questions.md` — **luôn tồn tại**; không có điểm mù thì ghi "No open questions" (file rỗng = đã rà; thiếu file = chưa rà).

## Cấm

- Bịa yêu cầu không truy được về nguồn.
- **Chọn giải pháp kỹ thuật** (thư viện, bảng, module) — việc của `02-design`.
- Tự chọn một cách hiểu cho chỗ mơ hồ mà không ghi `[OPEN-QUESTION]`.
- Gắn `[INFERRED]` cho quyết định nghiệp vụ; hạ `Risk`/`Blocking` để khỏi bị chặn; ghi `should` khi nguồn không nói.
- Tự phân xử mâu thuẫn nguồn ("chọn bên an toàn hơn").
- **Tick ô "Approved by human"**, sửa/xoá dấu duyệt.
- Viết code, kể cả minh hoạ.

## Điều kiện ra

**Máy:** `aw check spec` ra `[x] ĐẠT` (danh sách kiểm: `rules/truy-vet-nguon.md`).

**Người:**
- Duyệt YC và "Out of scope"; duyệt `Blocking` và `Risk`.
- Tick "Approved by human". `02-design` (chore: `03-plan`) chặn tới lúc đó. Sửa spec sau khi tick → duyệt lại: đọc chỗ đổi rồi xoá `<!-- approval-hash: … -->` (giữ tick), hoặc tick lại nếu tick đã bị bỏ.

Điểm mù còn mở: review không được kết luận `pass` cho YC đó; `blocking`/`review-blocking` còn mở thì review chặn.
