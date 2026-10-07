#!/usr/bin/env sh
# Phần dùng chung của mọi adapter. Adapter là lớp MỎNG: dịch workflow/ sang dạng
# native của một agent và chỉ dẫn agent gọi `aw …`. Luật cứng nằm trong checker
# của engine (mã thoát + nhãn Kết quả), không nằm ở đây, không dựa vào tính năng
# riêng của agent nào.
#
# Người gọi đặt trước khi source: ROOT (gốc engine), OUT (thư mục đích), FORCE
# (0|1), DA_SINH (file ghi danh sách file sinh ra lần này). Sau đó source
# tools/lib/md.sh, tools/lib/ket-qua.sh, tools/lib/bang-lenh.sh.
#
# Đường dẫn trong lời dặn agent (tương đối với gốc worktree):
#   .agent-workflow/<tên-branch>/   artifact của việc (bị exclude, không commit)
#   .agent-workflow/.engine/        rules, templates, checkers của engine — aw adapter
#                                   build chép vào; conventions.md là liên kết tới
#                                   cấu hình của bản clone

MANIFEST="$ROOT/workflow.yaml"
man_scalar() { awk -v k="$1" '{ sub(/\r$/, "") } $0 ~ "^" k ":" { sub("^" k ":[ \t]*", ""); print; exit }' "$MANIFEST"; }
ART=$(man_scalar artifact_dir)
DOCS="$ART/.engine"
CONV_DOC="$DOCS/conventions.md"
FD='<thư-mục-feature>'

# ad_bi_theo_doi <file> -> 0 nếu git đang theo dõi file đó trong OUT. File của
# bộ cài cũ đã commit vào base: không ghi đè (sẽ thành thay đổi lọt vào commit).
ad_bi_theo_doi() {
  git -C "$OUT" ls-files --error-unmatch -- "${1#"$OUT"/}" >/dev/null 2>&1
}

# Khong ghi de file do NGUOI viet. File do adapter sinh ra deu mang dau
# "SINH TU DONG"; file dich khong co dau do nghia la co nguoi da viet tay.
kiem_tra_ghi_de() {
  [ -f "$1" ] || return 0
  [ "$FORCE" = "1" ] && return 0
  ad_bi_theo_doi "$1" && return 0
  if grep -q 'SINH TỰ ĐỘNG' "$1" 2>/dev/null; then return 0; fi
  echo "LỖI: $1 đã tồn tại và không phải file do adapter sinh ra." >&2
  echo "      Adapter sẽ không ghi đè công sức viết tay. Di chuyển file đó đi," >&2
  echo "      hoặc chạy lại với --force nếu chắc chắn muốn mất nội dung cũ." >&2
  exit 3
}

# ghi_file <dich> — doc stdin vao file tam roi moi chuyen vao cho. Build that
# bai giua chung khong duoc de lai mot file viet do: no trong nhu hop le nhung bi cut.
ghi_file() {
  if ad_bi_theo_doi "$1"; then
    cat > /dev/null; echo "$1" >> "$DA_SINH"
    echo "  skip    ${1#"$OUT"/} (git đang theo dõi — bộ cài cũ trong base; xoá khỏi base bằng một PR)"
    return 0
  fi
  mkdir -p "$(dirname "$1")"
  _tmp="$(dirname "$1")/.$(basename "$1").tmp"
  if cat > "$_tmp"; then mv "$_tmp" "$1"; echo "$1" >> "$DA_SINH"; echo "  build   ${1#"$OUT"/}"; else rm -f "$_tmp"; exit 4; fi
}

# don_file_cu <file...> — xoá file mang dấu "SINH TỰ ĐỘNG" mà lần build này không
# sinh ra (phase / lệnh đã đổi tên hoặc bị bỏ). File NGƯỜI viết, file git theo dõi: không đụng.
don_file_cu() {
  for _f in "$@"; do
    [ -f "$_f" ] || continue
    grep -q 'SINH TỰ ĐỘNG' "$_f" 2>/dev/null || continue
    grep -qxF "$_f" "$DA_SINH" && continue
    ad_bi_theo_doi "$_f" && continue
    rm -f "$_f"
    echo "  remove  ${_f#"$OUT"/} (không còn trong manifest)"
  done
}

canh_bao() {
  printf '> **File này được SINH TỰ ĐỘNG** từ `%s` (engine agent-workflow %s) bởi `aw adapter build`.\n' "$1" "$(cat "$ROOT/VERSION" 2>/dev/null)"
  printf '> Đừng sửa trực tiếp — file bị exclude khỏi git và sẽ bị sinh lại.\n\n'
}

# Kiem tra exit_machine, arguments va llm_checker TRUOC khi sinh file, va o SHELL CHINH.
#
# Dieu kien ra loai MAY phai la LENH CHAY DUOC: `aw check <ten>` voi <ten> co
# trong bang checker cua engine. Neu no chi la cau chu thi no la dieu kien loai
# NGUOI dang doi lot — agent se "tu danh gia la dat", dung cai ma
# nguyen-tac-chung.md cam.
#
# Khong dat kiem tra nay ben trong `... | while read` (subshell: `exit` chi thoat
# subshell). Doc tu file bang redirect thi van o shell chinh.
kiem_tra_nguon() {
  _src="$1"; _file="$2"
  _tmp="${TMPDIR:-/tmp}/em.$$"
  fm_list "$_src" exit_machine > "$_tmp"
  _bad=0
  while IFS= read -r _c; do
    [ -n "$_c" ] || continue
    case "$_c" in
      "aw check "*)
        _n=${_c#aw check }
        if ! bl_checker "$_n" >/dev/null; then
          echo "LỖI: $_file khai exit_machine \"$_c\" nhưng engine không có checker \"$_n\" (có: $BL_CHECKERS)" >&2
          _bad=1
        fi ;;
      *)
        echo "LỖI: $_file khai exit_machine \"$_c\" — đây không phải lệnh chạy được." >&2
        echo "      Điều kiện ra loại MÁY phải là \"aw check <tên>\", in khối Kết quả ĐẠT / KHÔNG ĐẠT." >&2
        echo "      Nếu chỉ người kiểm được thì chuyển xuống exit_human." >&2
        _bad=1 ;;
    esac
  done < "$_tmp"
  rm -f "$_tmp"
  _ar=$(fm_scalar "$_src" arguments)
  case "$_ar" in
    ""|input) ;;
    *) echo "LỖI: $_file khai arguments \"$_ar\" — chỉ nhận \"input\" (bỏ trống = tên feature)." >&2; _bad=1 ;;
  esac
  _lc=$(fm_scalar "$_src" llm_checker)
  if [ -n "$_lc" ] && [ ! -f "$ROOT/$_lc" ]; then
    echo "LỖI: $_file khai llm_checker \"$_lc\" nhưng không có file đó." >&2
    _bad=1
  fi
  [ "$_bad" = "0" ]
}

dich_lenh() {
  printf '  - `%s %s` → khối `Kết quả` cuối output phải đánh dấu `[x] ĐẠT`\n' "$1" "$FD"
}

mo_ta_input() {
  case "$1" in
    confluence) printf '  - Confluence qua MCP Atlassian — ghi lại URL page + tên heading\n' ;;
    jira)       printf '  - Jira qua MCP Atlassian — ghi lại mã issue + URL\n' ;;
    file)       printf '  - Tài liệu trong repo (kể cả incident note) — ghi lại đường dẫn + heading\n' ;;
    diff)       printf '  - Diff so với nhánh gốc (`git diff`, `git status`; nhánh gốc khai trong `%s`)\n' "$CONV_DOC" ;;
    *.md)       printf '  - `%s/%s`\n' "$FD" "$1" ;;
    *".md ("*)  printf '  - `%s/%s` (%s\n' "$FD" "${1%% (*}" "${1#* (}" ;;
    *)          printf '  - %s\n' "$1" ;;
  esac
}

mo_ta_output() {
  case "$1" in
    diff) printf '  - Thay đổi code trong repo\n' ;;
    *)    printf '  - `%s/%s`\n' "$FD" "$1" ;;
  esac
}

# Buoc 0 cua moi lenh: xac dinh feature. Thu tu branch -> tham so -> hoi la
# giao dien chung giua cac adapter, nen no nam trong engine (aw feature), khong trong prompt.
#   buoc_xac_dinh_feature <cách-viết-tham-số> [input]
buoc_xac_dinh_feature() {
  printf '## Bước 0 — Xác định feature (luôn làm trước)\n\n'
  if [ "${2:-}" = "input" ]; then
    # Tham so cua lenh la INPUT, khong phai ten feature: khong truyen vao aw feature,
    # neu khong "/intake JIRA-123" se tao thu muc artifact ten JIRA-123.
    printf 'Chạy `aw feature` — **không** truyền tham số của lệnh: tham số là input, không phải tên feature.\n\n'
    printf 'Đọc khối `Kết quả` cuối output — làm theo nhãn được đánh `[x]`:\n\n'
    printf -- '- **ĐÃ XÁC ĐỊNH:** stdout là thư mục feature — bên dưới gọi là `%s`. In ra `Đang làm với: %s` rồi mới đọc/ghi gì.\n' "$FD" "$FD"
    printf -- '- **ĐANG Ở CHECKOUT CHÍNH:** đang ở checkout chính → làm theo mục "Tạo worktree" trong mô tả phase: chốt loại việc với người, chạy `aw worktree new` để **đề xuất**, NGƯỜI chọn base, rồi mới `--create --base <ref>`. Ghi `intake.md` vào worktree mới, rồi dừng: người mở phiên mới ở đó.\n'
    printf -- '- **CẦN HỎI NGƯỜI:** đang trong worktree nhưng branch không khớp quy ước → dừng lại hỏi người. Không tự đặt tên.\n\n'
  else
    printf 'Chạy `aw feature %s`.\n\n' "$1"
    printf 'Đọc khối `Kết quả` cuối output — làm theo nhãn được đánh `[x]`:\n\n'
    printf -- '- **ĐÃ XÁC ĐỊNH:** stdout là thư mục feature — bên dưới gọi là `%s`. In ra `Đang làm với: %s` rồi mới đọc/ghi gì.\n' "$FD" "$FD"
    printf -- '- **ĐANG Ở CHECKOUT CHÍNH:** đang ở checkout chính → **dừng lại**. Quy trình bắt buộc làm trong worktree: bảo người mở phiên mới trong worktree của việc (chưa có thì chạy `/intake` ở checkout chính). Không tự chuyển thư mục.\n'
    printf -- '- **CẦN HỎI NGƯỜI:** branch không khớp quy ước và không có tham số → **dừng lại hỏi** người dùng tên feature. Không tự đặt tên.\n'
    printf -- '- **TÊN KHÔNG HỢP LỆ:** tên không hợp lệ → báo lại cho người dùng.\n\n'
  fi
  printf 'Lệnh `aw …` là lệnh của engine agent-workflow (cài global). Đường dẫn `templates/`, `rules/`, `checkers/` trong mô tả phase nằm trong `%s/`.\n' "$DOCS"
  printf 'Mọi `aw check` chạy đúng version engine ghi ở dòng `Engine:` của `intake.md` — không tự đổi dòng đó.\n\n'
}

# Buoc 0b cua /intake: tham so -> dong "## Input". Nhan do engine gan, khong do
# agent doan; nguyen van di qua heredoc co nhay de khong bi shell dien giai.
#   buoc_phan_loai_input <cách-viết-tham-số>
buoc_phan_loai_input() {
  printf '## Bước 0b — Phân loại tham số thành input\n\n'
  printf 'Tham số của lệnh: `%s`\n\n' "$1"
  printf 'Bước này không cần thư mục feature: khi Bước 0 ra `CẦN HỎI NGƯỜI`, chạy nó trước để có input mà chốt loại việc với người.\n\n'
  printf '**Không tự gán nhãn.** Chạy đúng như dưới, giữ nguyên văn tham số (kể cả dấu nháy, xuống dòng). Thêm `--skip %s/intake.md` khi file đó **đã có** (chạy lại = gộp thêm, xem mục "Chạy lại" trong mô tả phase):\n\n' "$FD"
  printf '```sh\naw input [--skip %s/intake.md] - <<'"'"'HET_INPUT'"'"'\n%s\nHET_INPUT\n```\n\n' "$FD" "$1"
  printf 'Stdout là **đúng các dòng** ghi vào `## Input` — chép nguyên, không sửa. Làm theo nhãn được đánh `[x]` trong khối `Kết quả`:\n\n'
  printf -- '- **NGUỒN:** các tham số đều là nguồn. Stdout rỗng = không có input mới.\n'
  printf -- '- **LỜI NGƯỜI DÙNG:** tham số là lời người dùng → stdout là một mục `[NGƯỜI-DÙNG]` nguyên văn. Nếu stderr có "Đề xuất tách thêm": hỏi người, chỉ ghi các dòng đó khi người đồng ý.\n'
  printf -- '- **KHÔNG CÓ THAM SỐ:** không có tham số → hỏi người dùng input, rồi chạy lại lệnh trên với **nguyên văn câu trả lời**.\n'
  printf -- '- **ĐƯỜNG DẪN KHÔNG TỒN TẠI:** có đường dẫn không tồn tại → hỏi lại người dùng. Không tự đoán đường dẫn.\n\n'
}

# doc_truoc — mục "Đọc trước khi làm" chung
doc_truoc() {
  printf '### Đọc trước khi làm\n\n'
  printf -- '- `%s/rules/nguyen-tac-chung.md`\n' "$DOCS"
  printf -- '- `%s/rules/truy-vet-nguon.md`\n' "$DOCS"
  printf -- '- `%s` — quy ước của repo (cấu hình của bản clone, không nằm trong git)\n\n' "$CONV_DOC"
}

# buoc_quy_tac_repo <phase> — đọc quy tắc riêng của repo. Danh sách lấy LÚC CHẠY
# bằng `aw rules`, không chép vào lúc build: conventions.md sửa là có hiệu lực ngay.
buoc_quy_tac_repo() {
  printf '### Quy tắc riêng của repo\n\n'
  printf 'Chạy `aw rules %s`. Stdout là danh sách file (đường dẫn từ gốc repo) — **đọc từng file** trước khi làm. Làm theo nhãn được đánh `[x]` trong khối `Kết quả`:\n\n' "$1"
  printf -- '- **ĐÃ LIỆT KÊ:** đọc hết các file đó và theo chúng trong phase này. Không in gì = không có quy tắc riêng.\n'
  printf -- '- **KHAI SAI:** dừng lại, báo người sửa khoá `quy_tac_*` trong `%s`. Không tự đoán file thay thế.\n\n' "$CONV_DOC"
  printf 'Quy tắc repo xếp **dưới** `spec.md`, `tdd.md`, `plan.md` và luật quy trình: mâu thuẫn thì làm theo artifact và nêu ra, không vì quy tắc mà vượt phạm vi phase. File `SKILL.md` trong danh sách cũng đọc như tài liệu thường.\n\n'
}

# luat_tom_tat — bảy luật không được vi phạm, dùng trong file tổng của agent
luat_tom_tat() {
  printf '1. **Bàn giao bằng file.** Phase không được nhận đầu vào từ hội thoại phía trên.\n'
  printf '2. **Không tự tuyên bố đạt** với điều kiện ra loại MÁY — phải chạy `aw check …` và dán kết quả thật.\n'
  printf '3. **Agent không tự duyệt.** Không tick ô "Người duyệt …" (spec, D-xx), không sửa dấu duyệt; sửa nội dung đã tick thì bỏ tick. Checker LLM chỉ được chặn.\n'
  printf '4. **Không vượt phạm vi phase.** Việc thuộc phase khác thì ghi lại, không làm luôn.\n'
  printf '5. **Không xoá artifact của phase trước.** Chạy lại là cập nhật, không viết đè trắng.\n'
  printf '6. **Mọi yêu cầu phải truy được về nguồn.**\n'
  printf '7. **Artifact viết cho NGƯỜI đọc.** Phân cấp rõ (heading, danh sách, bảng); câu ngắn, từ đơn giản.\n\n'
  printf 'Bản đầy đủ: `%s/rules/nguyen-tac-chung.md` và `%s/rules/truy-vet-nguon.md`.\n\n' "$DOCS" "$DOCS"
}
