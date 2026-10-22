### Nội bộ
- **Test hết chạy checker hai lần cho một lý do.** Cặp "…đúng lý do" còn escape chuyển sang
  `ky_vong_ly_do` (một lần chạy, vừa mã thoát vừa câu thông báo). Hai cặp kiểm hai thông báo một lúc
  giữ nguyên: mục lục vừa thiếu mục mới vừa thừa link cũ, và cả `test-results.md` lẫn
  `security-results.md` lỗi thời. Thêm một ca: `check-design` vẫn chặn khi spec khai `Design: skip`.
- **`check-sdlc.sh` tra một lần.** Capability, invariant, phase theo stage, stage `skippable: false`
  và requires của stage không còn gọi awk mỗi lần dò. Output không đổi; mỗi lần chạy khoảng 1,6 giây
  (trước khoảng 2 giây). Người dùng `aw` không thấy gì.
