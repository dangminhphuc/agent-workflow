### Sửa
- **`aw conventions check` không còn in ký tự hỏng (`ví d�`)** khi cắt dòng dài trong cảnh báo "còn placeholder"
  và lỗi "không phải khoá: giá trị". Trước đây dòng bị cắt theo byte nên có thể đứt giữa chữ có dấu; nay bỏ cả
  ký tự dở. Thêm ca test ở `tools/tests/15-conventions-task.sh`. Không đổi luật, không đổi mã thoát.
