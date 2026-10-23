### Thay đổi

- **Bugfix: lệnh đã đỏ phải là lệnh đang xanh.** `repro.md` ghi cả lệnh kiểm thử, không ghi riêng tên một test, nên máy không tách tên test (dễ báo nhầm theo ngôn ngữ). `aw check implement` cảnh báo khi lệnh trong `repro.md` khác lệnh trong `test-results.md`. `aw check review` chặn. Người vẫn phán test đỏ đúng vì bug (`Repro test fails because:`).
- **INV-007** nới thêm điều này: sau khi sửa, verify chặn nếu lệnh xanh không phải lệnh đã đỏ; implement chỉ cảnh báo.
