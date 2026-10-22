# Spec: SP2 — Invariant chặt hơn

- Ngày: 2026-10-22 · Branch: `claude/brave-heisenberg-t70jup` (PR #79)
- Roadmap: `docs/superpowers/2026-10-22-roadmap-cai-thien.md` § SP2
- Interface: sửa nội dung INV-001…INV-011 (chỉ cách viết, không đổi luật); thêm luật cấu trúc cho
  `Rule:`. Không bỏ, không nới capability / invariant nào.

## 1. Mục tiêu

1. INV-001…INV-006 chỉ trỏ tới **file** test; máy chỉ kiểm file có tồn tại. INV-007…INV-011 nêu
   **tên ca**, máy kiểm từng ca có trong file. Hai chuẩn cho cùng một loại lời khai.
2. `Rule:` của invariant chứa cú pháp engine (`` `Based on: DEC-xxx` ``, `` `covers:` ``, `REQ`,
   `` `production_code` ``, `"Modified existing tests"`). Interface tự nhận "không biết engine", nên
   implementation thứ hai không tuân thủ được nếu không chép cú pháp của engine này.
3. Bảng ánh xạ stage → phase và ma trận profile có **hai ảnh chụp** (`docs/interface-sdlc.md` § 6 và
   `docs/kien-truc.md` § Interface SDLC), lệch output `check-sdlc.sh` mà không ai biết.

**Thành công:** mọi invariant nêu tên ca; mọi `Rule:` (capability và invariant) không backtick, không
mã định danh của engine; một ảnh chụp duy nhất, có test so với output; `check-sdlc.sh` ĐẠT; bộ test đạt.

## 2. Thiết kế

### 2.1 `Tested by:` nêu ca cho INV-001…INV-006

Mỗi invariant nêu ít nhất một ca chặn có thật trong file test đã trỏ (cú pháp sẵn có:
`` `tools/tests/NN-x.sh` "ca", "ca" ``). Chọn ca chứng minh **chặn** đúng luật đó (không chọn ca ĐẠT).
`check-sdlc.sh` thêm luật: **mọi** invariant phải có ít nhất một ca nêu tên — thiếu thì chặn:
`INV-NNN: "Tested by:" không nêu ca test nào — thêm tên ca (trong "…") sau đường dẫn file.`

### 2.2 `Rule:` trừu tượng, cú pháp engine sang `- Engine:`

- `Rule:` (của capability và invariant) không được chứa backtick, cũng không chứa mã dạng
  `(REQ|DEC|TSK|RVW|FND|RFR|BR)-` — `check-sdlc.sh` chặn:
  `<id>: "Rule:" chứa cú pháp engine (<cái tìm thấy>) — viết trừu tượng, chuyển cú pháp sang "- Engine:".`
- Dòng mới `- Engine:` (tuỳ chọn, chỉ ở invariant): cách engine này hiện thực luật, được phép backtick
  và mã. Máy không kiểm nội dung dòng này.
- Viết lại `Rule:` của INV-001…INV-011 (ví dụ INV-002: *"every task names only design decisions that
  exist in the approved design"*, `- Engine: task line \`Based on: DEC-xxx\``). Capability hiện có không
  vi phạm (đã rà) — luật áp cho capability để giữ về sau.

### 2.3 Một ảnh chụp, có test

- `docs/interface-sdlc.md` § 6 giữ khối ảnh chụp gồm **ba bảng** của output (Stage → phase, roadmap,
  ma trận job type × stage cùng dòng "có thể vắng"), chép nguyên văn.
- `docs/kien-truc.md` § Interface SDLC: bỏ bảng ánh xạ và bảng ma trận, thay bằng một câu trỏ tới
  `interface-sdlc.md` § 6. Phần "Thêm" theo profile (artifact, invariant) của ma trận chuyển thành
  danh sách ngắn — nó không có trong output nên không phải ảnh chụp.
- Test mới ở `tools/tests/20-sdlc-conformance.sh`: khối ``` đầu tiên sau heading `## 6.` của
  `docs/interface-sdlc.md` phải trùng từng dòng với output `sh tools/check-sdlc.sh` từ dòng
  `Stage → phase` tới trước dòng `Engine tuân thủ interface SDLC.`. Lệch → ca hỏng, in diff.

## 3. Test

- `22-sdlc-stage-files.sh`: invariant chỉ có file, không ca → chặn; `Rule:` có backtick → chặn;
  `Rule:` có `REQ-` → chặn; `Rule:` capability có `DEC-` → chặn; `- Engine:` có backtick → ĐẠT.
- `20-sdlc-conformance.sh`: ảnh chụp § 6 khớp output; ảnh chụp sửa một dòng → ca so sánh báo lệch
  (chạy hàm so sánh trên bản chép).

## 4. Tài liệu

`docs/interface-sdlc.md` § 2 (trường `- Engine:` của invariant), § 4.1 bước 4 (nêu ca), § 5 (lỗi mới),
§ 6; `docs/kien-truc.md` § Interface SDLC; `sdlc/invariants.md` đoạn mở đầu; `changes/…` (`Nội bộ`).

## 5. Ngoài phạm vi

Kiểm nội dung `- Engine:` khớp checker thật; ánh xạ từng luật checker vào invariant (SP12).
