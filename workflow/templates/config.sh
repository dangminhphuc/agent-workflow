# Cấu hình của bản clone này cho agent-workflow.
# Nằm ở $(git rev-parse --git-common-dir)/agent-workflow/ — KHÔNG commit, dùng chung
# mọi worktree. Do NGƯỜI sửa; aw init / aw upgrade không ghi đè.

# Adapter sinh lệnh cho agent team dùng — một hoặc nhiều id, cách nhau dấu cách:
#   ADAPTER="claude-code"            chỉ Claude Code (.claude/)
#   ADAPTER="claude-code cursor"     cả hai — mỗi worktree có cả .claude/ lẫn .cursor/
# Sửa xong thì chạy aw init (thêm exclude) rồi aw adapter build ở checkout chính.
ADAPTER="claude-code"

# Lệnh kiểm thử — điều kiện ra của phase 04-implement.
# Bỏ trống thì phase implement sẽ KHÔNG ĐẠT, không phải "bỏ qua".
LENH_KIEM_THU=""

# Lệnh đo hiệu năng — chỉ dùng cho loại việc perf. Phải in một dòng
# "KET_QUA: <số> <đơn vị>", vd: KET_QUA: 138 ms
LENH_DO_HIEU_NANG=""

# Lệnh chuẩn bị worktree mới (cài dependency…) — aw worktree IN RA cho người
# chạy, không tự chạy. Worktree mới chỉ có file đã commit: không có
# node_modules, .env… Vd: LENH_CHUAN_BI_WT="npm ci"
LENH_CHUAN_BI_WT=""
