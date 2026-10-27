### Nội bộ
- SP19 đợt 19c: gắn `# giữ:` cho 59/60 chỗ luật của `tools/check-spec.sh` — `tools/unclassified-rules.txt`
  `check-spec.sh` 60 → 1 (còn 1 chỗ `kc_quy_tac_loi`: file `rules_*` khai ở conventions không có / chưa
  commit, `uses_*` không tìm thấy skill/subagent — không capability nào giữ điều này, chờ người duyệt
  capability mới; các checker khác cùng mẫu này cũng đang chưa gắn). Mapping từng dòng ở plan
  `docs/superpowers/plans/2026-10-27-sp19c-gan-id-check-spec.md`.
- INV-005 (`Enforced by`) thêm `tools/check-spec.sh`: entry check của spec chặn khi intake.md không qua
  `aw check intake`. Ca test mới ở `tools/tests/02-spec.sh`.
- `toc_loi` trong `check-spec.sh` gắn INV-012 (SP35/#109 cho invariant này id; đề xuất "chờ capability mới"
  của đợt 19b cho `toc_loi` nay hết cần).
