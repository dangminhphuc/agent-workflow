### Nội bộ
- **Sửa workflow `kiem-tra` không parse được sau #96.** Bước chẩn đoán tạm của job macOS viết
  `run:` một dòng có `": "` nên YAML không đọc được: mọi lần chạy `kiem-tra` (cả job Ubuntu) thất bại
  ngay, không job nào chạy. Giờ viết dạng khối `run: |`.
