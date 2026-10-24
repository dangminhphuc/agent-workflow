### Nội bộ
- **Một bộ đọc token `Expected files` cho mọi nơi kiểm phạm vi.** Token trong backtick của `plan.md` (dòng `Expected files`, mục `Unplanned`) trước đây được đọc bằng bốn bản awk chép nhau (`kc_pham_vi`, `kc_glob_chuyen_tiep`, `kc_glob_rong` trong `tools/lib/cross-check.sh`, `kt_duong_plan` trong `tools/lib/knowledge.sh`); nay dùng chung `kc_token_plan`, chuẩn bị cho SP18 đổi ngữ nghĩa glob ở một chỗ. Hành vi giữ nguyên: kiểm phạm vi diff và cảnh báo glob chuyển tiếp lấy mọi token (Expected files ở bất kỳ đâu + cột `Extra files` / dòng lẻ của `Unplanned`); cảnh báo glob rộng và `aw knowledge implement` chỉ lấy `Expected files` dưới heading `### TSK-…`. Ca test mới ghim khác biệt này.

### Sửa
- **Cảnh báo glob rộng (`scope_glob_max_files`) bỏ sót file có dấu trong tên.** `kc_glob_rong` đọc cây Base không tắt `core.quotepath`, nên tên như `tài-liệu/x.txt` bị git trích dạng `"t\303\240i-..."` và không khớp mẫu. Nay đếm đúng.
