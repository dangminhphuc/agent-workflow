# Mẫu Makefile cho repo đích — tài liệu của engine agent-workflow, KHÔNG phải luật.
# Chép vào gốc repo (cp .agent-workflow/.engine/templates/repo-dich/Makefile Makefile),
# thay từng dòng `chua_khai` bằng lệnh thật, commit qua PR.
#
# Mục đích: lệnh kiểm nằm TRONG GIT, một chỗ cho cả người, CI và agent-workflow.
#   - pipeline CI gọi `make test`, `make security`… thay vì chép lệnh vào file pipeline;
#   - .git/agent-workflow/config.sh khai LENH_KIEM_THU="make test" và
#     LENH_KIEM_TRA_BAO_MAT với các dòng `secret: make security-secret`…
# Sửa lệnh ở đây là CI và agent-workflow cùng đổi — không còn lệch nhau.
#
# Target chưa khai thì thoát mã 1: "quên khai" không bao giờ thành "xanh".

.PHONY: setup test lint security security-secret security-sast security-sca

chua_khai = { echo "make $@: chưa khai — sửa Makefile" >&2; exit 1; }

setup:            ## cài dependency (worktree mới chỉ có file đã commit)
	@$(chua_khai)

test:             ## toàn bộ test — điều kiện ra của 04-implement
	@$(chua_khai)

lint:             ## lint + format check
	@$(chua_khai)

security: security-secret security-sast security-sca

security-secret:  ## vd: gitleaks detect --no-banner --redact --exit-code 1
	@$(chua_khai)

security-sast:    ## vd: semgrep scan --config p/ci --error --metrics off
	@$(chua_khai)

security-sca:     ## vd: trivy fs --scanners vuln --severity HIGH,CRITICAL --exit-code 1 .
	@$(chua_khai)
