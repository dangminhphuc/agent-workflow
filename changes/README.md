# Mảnh changelog

Mỗi PR ghi thay đổi của mình vào **một file mới** ở đây — `changes/<tên-nhánh>.md` (đổi `/` thành
`-`, vd `changes/feat-heading-ma-dinh-danh.md`) — không sửa `CHANGELOG.md`. Hai PR không bao giờ sửa
cùng một file, nên không còn conflict ở changelog khi merge.

Dạng file: chỉ các mục `### <tên mục>` (`Thêm`, `Thay đổi`, `Sửa`, `Bỏ`, `Nội bộ`) và nội dung
dưới mục, viết như một mục trong `CHANGELOG.md`:

```markdown
### Thêm
- **Tóm tắt thay đổi.** Vì sao, ai bị ảnh hưởng, cần làm gì.

### Nội bộ
- Thay đổi người dùng `aw` không thấy.
```

Không dùng heading `#`/`##`, không viết chữ trước mục đầu tiên. `tools/check-release.sh` (workflow
`kiem-tra` của PR) chặn mảnh sai dạng.

Khi phát hành, `tools/prepare-release.sh` gom mọi mảnh vào `## [<version>]` của `CHANGELOG.md`
(cùng tên mục gộp làm một, thứ tự `Thêm`, `Thay đổi`, `Sửa`, `Bỏ`, mục khác, `Nội bộ`) rồi xoá các
mảnh. File này không phải mảnh.
