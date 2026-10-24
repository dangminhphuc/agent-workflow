### Thêm
- **`aw journal retro <thư-mục-việc>`: tổng kết cuối việc.** In phần máy (phase, thiết kế, cỡ diff, số lần bị chặn) và danh sách các lần bị chặn đánh số. Với cờ `--nham`, `--phut`, `--vuong`, `--gay-boi`, `--lop` hoặc `--bo-qua` thì ghi một dòng vào `jobs.tsv`; chạy lại thì thay dòng cũ. Bước cuối phase review hỏi người (lần chặn nào nhầm, mất bao nhiêu phút, chỗ nào vướng) và ghi giúp.
- **Mốc bắt đầu phase (`phases.tsv`).** `aw rules <phase>` chạy trong worktree của việc ghi mốc phase. Không đổi kết quả hay mã thoát của `aw rules`.
- **Report mới.** Độ chính xác của từng checker, thời gian trung vị từng phase, việc theo loại và cỡ diff, lỗi lọt theo lớp. `aw journal report --version <v>` chỉ tính dòng của một version engine.

### Thay đổi
- **Mọi dòng nhật ký có cột version engine ở cuối** (`checks`, `failures`, `approvals`, `findings`, `phases`, `jobs`).
- **`aw journal report` đọc được file export cũ** (không cột version): dòng cũ được coi là version `?`. `aw journal export` thêm hai nguồn `phases` và `jobs`.

### Nội bộ
- Tách `aw journal retro` sang `tools/journal-retro.sh`; hàm dùng chung (version, định dạng ô, epoch, trung vị) nằm ở `tools/lib/journal-util.sh`.
- Test mới `tools/tests/27-journal-retro.sh`.
- Tài liệu: hướng dẫn đo lường, kiến trúc (điểm yếu 23: thời gian phase và phần người là xấp xỉ), thuật ngữ `retro`.
