### Thay đổi
- **`aw toc` sửa được link của mục vừa đổi tên, một lượt là xong.** Trước: đổi chữ một heading
  (`### REQ-001 — Đăng nhập` → `### REQ-001 — Đăng nhập bằng OTP`) thì mọi link cũ tới nó thành
  link chết và `aw toc` chỉ báo, người viết phải sửa tay từng link hoặc chạy `sed`, thường mất
  3–4 lượt chạy. Nay `aw toc` mở rộng lại anchor theo mã (`req-001…`) nên một lần chạy phủ hết
  thư mục là `ĐÃ KHỚP`. Mã ID không chỉ đúng một mục thì máy không đoán — vẫn báo và nói rõ có
  mấy mục cùng mã để người sửa tự chọn.
- **Lỗi dạng in kèm số dòng và dạng đúng.** Mỗi dòng `[LỖI]` của `aw toc` và checker giờ có
  `(dòng N)` và một câu cho biết dạng đúng: `dạng đúng là mục #q-001--…`, `không có heading nào
  mã Q-009`, `còn chỗ giữ chỗ: điền anchor mục thật`. Mọi lỗi in cùng một lượt, không dừng ở lỗi
  đầu. Ai bị ảnh hưởng: agent mọi phase viết artifact; phía repo đích không phải đổi gì.
- **Một lượt `aw toc`, không phải sau từng file.** `rules/general.md` §6 đổi từ "sau mỗi lần sửa
  thì chạy `aw toc`" thành "chạy **một lần** khi viết xong artifact, trước `aw based-on`";
  checker LLM của spec và design thôi tự chạy `aw toc` cho từng file (phase chạy một lần cho cả
  thư mục).
  Intent: bớt vòng chạy lại để tiết kiệm token.
- **Lệnh `/aw-spec`… nêu đường dẫn template đầy đủ.** Dòng **Templates** trong lệnh sinh ra giờ là
  `.agent-workflow/.engine/templates/spec.md` thay vì `templates/spec.md` — agent đọc được ngay,
  không phải đoán chỗ cất.

### Nội bộ
- **Requirement "viết đúng dạng ngay lần đầu" đã làm đợt 1** (PR #109): spec
  `docs/superpowers/specs/2026-10-26-spec-dung-dang-lan-dau-design.md` §6 đã chốt — interface là
  **`INV-012`** (link giữa các artifact do máy giữ cho đúng), không thêm capability riêng cho
  `require`; phase spec thêm bước "Shape first, one pass" (chép khung template trước khi viết);
  roadmap SP35 trạng thái `một phần` (còn REQ-006: đo token bằng journal SP9). Test:
  `tools/tests/01-fixture-engine-toc.sh` — 9 ca mới cho INV-012.
