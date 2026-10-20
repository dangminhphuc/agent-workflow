### Thay đổi
- **`aw check review` không còn chặn vì từ dịch trong artifact của phase trước — chỉ cảnh báo.**
  Trước đây một từ như "ô duyệt" trong `tdd.md` làm review `KHÔNG ĐẠT` dù code không còn Blocker
  nào; review không được sửa `tdd.md` nên phải quay về `/aw-design` chỉ vì một lỗi văn phong. Giờ
  review in `[CẢNH BÁO] tdd.md dòng 15: "ô duyệt" là từ dịch — viết `approval checkbox``, vẫn ĐẠT.
  Riêng `review.md` (file review tự viết, sửa được ngay) thì vẫn chặn. `aw check implement` vẫn
  cảnh báo như trước, nhưng tách từ dịch ra khỏi nhóm "review sẽ CHẶN nếu còn". Định dạng thông báo
  giữ nguyên.

### Sửa
- **Kiểm từ dịch không còn bắt chính chỗ trích lại từ đó.** Chữ trong code span `` `…` ``, ngoặc
  kép `"…"`, `“…”` và fenced code block được bỏ qua (cùng với dòng trích `>` như cũ), nên người rà
  soát viết được `"ô duyệt" là từ dịch` trong `review.md` mà không bị chặn.
