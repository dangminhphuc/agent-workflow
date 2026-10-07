#!/usr/bin/env sh
# Phần dùng chung của mọi adapter. Adapter là lớp MỎNG: dịch workflow/ sang dạng
# native của một agent và chỉ dẫn agent gọi `aw …`. Luật cứng nằm trong checker
# của engine (mã thoát + nhãn Kết quả), không nằm ở đây, không dựa vào tính năng
# riêng của agent nào.
#
# Toàn bộ việc sinh file (lệnh phase, lệnh tiện ích, subagent rà soát, subagent
# checker LLM, skill tổng, dọn file cũ) nằm ở đây — ad_sinh. Một adapter chỉ khai
# AD_ID, AD_TEN, AD_GOC rồi định nghĩa các hook (xem "Hook của adapter" bên dưới).
# Nhờ vậy hợp đồng phase của mọi adapter là MỘT: tools/chay-thu.sh build mọi
# adapter với AW_DOI_CHIEU=1 (hook in tên thay cho nội dung) và đòi output giống
# hệt nhau từng byte.
#
#   ROOT=…; AD_ID=cursor; AD_TEN=Cursor; AD_GOC=.cursor
#   . "$ROOT/adapters/lib/chung.sh"
#   ad_tham_so() { … }   …các hook khác…
#   ad_sinh "$@"         # --out <thư-mục> [--force]
#
# Đường dẫn trong lời dặn agent (tương đối với gốc worktree):
#   .agent-workflow/<tên-branch>/   artifact của việc (bị exclude, không commit)
#   .agent-workflow/.engine/        rules, templates, checkers của engine — aw adapter
#                                   build chép vào; conventions.md là liên kết tới
#                                   cấu hình của bản clone

. "$ROOT/tools/lib/md.sh"
. "$ROOT/tools/lib/ket-qua.sh"
. "$ROOT/tools/lib/bang-lenh.sh"
kq_khai build.sh \
  "0=ĐÃ SINH" \
  "2=SAI THAM SỐ" \
  "3=CÓ FILE VIẾT TAY — không ghi đè; dời file đó đi hoặc dùng --force" \
  "4=ĐỊNH NGHĨA QUY TRÌNH LỖI — sửa workflow/ trong repo agent-workflow"

OUT=""; FORCE=0; DA_SINH=""

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

# canh_bao <nguồn> — đầu mọi file sinh ra: dấu "SINH TỰ ĐỘNG" (kiem_tra_ghi_de,
# don_file_cu dựa vào nó), version engine, và file dành cho agent nào. Dòng cuối
# cần thiết vì agent có thể nạp thư mục của agent khác (Cursor nạp .claude/ để
# tương thích): lời dặn viết cho tool của agent này thì agent kia không làm được.
canh_bao() {
  printf '> **File này được SINH TỰ ĐỘNG** từ `%s` (engine agent-workflow %s) bởi `aw adapter build`.\n' "$1" "$(cat "$ROOT/VERSION" 2>/dev/null)"
  printf '> Đừng sửa trực tiếp — file bị exclude khỏi git và sẽ bị sinh lại.\n'
  printf '> %s\n\n' "$(_hk ad_danh_cho)"
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
  _ag=$(fm_scalar "$_src" approval_gate)
  case "$_ag" in
    ""|true) ;;
    *) echo "LỖI: $_file khai approval_gate \"$_ag\" — chỉ nhận \"true\" (bỏ trống = không)." >&2; _bad=1 ;;
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
  printf -- '- **LỜI NGƯỜI DÙNG:** tham số là lời người dùng → stdout là một mục `[HUMAN]` nguyên văn. Nếu stderr có "Đề xuất tách thêm": hỏi người, chỉ ghi các dòng đó khi người đồng ý.\n'
  printf -- '- **KHÔNG CÓ THAM SỐ:** không có tham số → hỏi người dùng input, rồi chạy lại lệnh trên với **nguyên văn câu trả lời**.\n'
  printf -- '- **ĐƯỜNG DẪN KHÔNG TỒN TẠI:** có đường dẫn không tồn tại → hỏi lại người dùng. Không tự đoán đường dẫn.\n\n'
}

# buoc_cong_duyet <phase> — phase khai approval_gate: true. Người gõ lệnh phase
# tiếp theo khi phần trước chưa duyệt: agent KHÔNG tick hộ, chỉ cho người thấy rõ
# còn gì chờ duyệt (máy dựng: aw approval) rồi hỏi. Cách hỏi cụ thể do adapter
# thêm ngay sau (Claude Code: AskUserQuestion); adapter không có giao diện lựa
# chọn thì in lựa chọn đánh số.
buoc_cong_duyet() {
  case "$1" in
    design) _cd_gi="spec"; _cd_lenh="/design" ;;
    plan)   _cd_gi="mọi quyết định D-xx (chore: spec)"; _cd_lenh="/plan" ;;
    *)      _cd_gi="phần trước"; _cd_lenh="/$1" ;;
  esac
  printf '## Bước 1 — Cổng duyệt (làm ngay sau Bước 0, trước mọi việc khác)

'
  printf 'Vào `%s` cần %s đã được **người** duyệt. Người gõ `%s` khi chưa duyệt thì hỏi lại cho rõ — **không** tự tick, **không** coi việc gõ lệnh là đã duyệt.

' "$_cd_lenh" "$_cd_gi" "$_cd_lenh"
  printf 'Chạy `aw approval %s %s`. Làm theo nhãn được đánh `[x]` trong khối `Kết quả`:

' "$1" "$FD"
  printf -- '- **ĐÃ DUYỆT:** đi tiếp phase, không hỏi gì.
'
  printf -- '- **CHƯA DUYỆT:** in **nguyên văn** stdout cho người trong một khối ```` ```text ```` (máy đã viết sẵn cho người đọc — không tóm tắt, không thêm bớt), rồi hỏi bằng **hộp xác nhận** bên dưới. Dừng ở đó cho tới khi người chọn.
'
  printf -- '- **SAI THAM SỐ HOẶC THIẾU FILE:** thiếu file thì báo người chạy phase trước. Lệnh không có (việc ghim engine cũ) thì bỏ qua bước này — `aw check` vẫn chặn.

'
  printf '**Hộp xác nhận** — một câu hỏi, ba lựa chọn theo thứ tự:

'
  printf '1. **Tôi đã duyệt xong — kiểm lại** → chạy lại `aw approval %s %s`. ĐÃ DUYỆT thì báo một dòng ("Đã thấy bạn duyệt — vào %s") rồi đi tiếp. Vẫn CHƯA DUYỆT thì chỉ in lại phần `Trạng thái` và `Cách duyệt`/`Chưa duyệt` mới, rồi hỏi lại hộp này.
' "$1" "$FD" "$_cd_lenh"
  printf '2. **Giải thích từng điểm cần duyệt** → đi qua từng mục trong stdout, mỗi mục 2–3 dòng: nó nói gì, nguồn ở đâu (YC, dòng, tài liệu), duyệt sai thì hậu quả gì. Đọc từ file, không suy diễn thêm. Xong thì hỏi lại hộp này.
'
  printf '3. **Dừng — tôi duyệt sau** → không làm gì của phase. Nhắc: duyệt xong thì gõ lại `%s`.

' "$_cd_lenh"
  printf 'Người gõ "duyệt hộ", "tick giúp", "ok cứ làm đi"… thì **từ chối** một dòng (chỉ người được tick — ô duyệt là bằng chứng người đã đọc), chỉ lại đúng file và dòng, rồi hỏi lại hộp này. Người muốn sửa nội dung thì đó là việc của phase trước (`/spec`, hoặc `/design` cho D-xx) — nói vậy, không sửa ở đây.

'
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
  printf '3. **Agent không tự duyệt.** Không tick ô "Approved by human" (spec, D-xx), không sửa dấu duyệt `approval-hash`; sửa nội dung đã tick thì bỏ tick. Checker LLM chỉ được chặn.\n'
  printf '4. **Không vượt phạm vi phase.** Việc thuộc phase khác thì ghi lại, không làm luôn.\n'
  printf '5. **Không xoá artifact của phase trước.** Chạy lại là cập nhật, không viết đè trắng.\n'
  printf '6. **Mọi yêu cầu phải truy được về nguồn.**\n'
  printf '7. **Artifact viết cho NGƯỜI đọc.** Phân cấp rõ (heading, danh sách, bảng); câu ngắn, từ đơn giản.\n\n'
  printf 'Bản đầy đủ: `%s/rules/nguyen-tac-chung.md` và `%s/rules/truy-vet-nguon.md`.\n\n' "$DOCS" "$DOCS"
}

# ======================================================================
# Hook của adapter — adapter PHẢI định nghĩa (ad_sinh kiểm trước khi sinh):
#
#   ad_tham_so                     cách viết tham số của lệnh trong lời dặn
#                                  (Claude Code: $ARGUMENTS — agent tự thay)
#   ad_dau_lenh <id> <mô-tả> <gợi-ý-tham-số>
#                                  phần đầu file lệnh (frontmatter…)
#   ad_mo_dau_lenh <id> <gợi-ý-tham-số> <arguments>
#                                  khối ngay sau cảnh báo của mọi lệnh (rỗng được)
#   ad_hoi_lua_chon                lệnh khai choice_ui: true — cách hỏi lựa chọn
#   ad_hoi_cong_duyet <phase>      phase khai approval_gate: true — hộp xác nhận
#   ad_danh_cho                    một dòng: file dành cho agent nào; agent khác
#                                  nạp nhầm thì phải làm gì
#
# Có mặc định (adapter định nghĩa lại sau khi source để thay):
#
#   ad_dau_agent <tên> <mô-tả>     frontmatter subagent
#   ad_dau_skill <tên> <mô-tả>     frontmatter skill
#
# Mọi lời gọi hook đi qua _hk: AW_DOI_CHIEU=1 thì hook in tên của nó thay cho
# nội dung — test đối chiếu đòi mọi adapter cho ra output giống hệt nhau, nên
# chữ riêng của một agent chỉ được nằm trong hook.
# ======================================================================

AD_HOOK="ad_tham_so ad_dau_lenh ad_mo_dau_lenh ad_hoi_lua_chon ad_hoi_cong_duyet ad_danh_cho"

_hk() {
  if [ "${AW_DOI_CHIEU:-}" = 1 ]; then printf '<<%s>>\n' "$*"; return 0; fi
  "$@"
}

ad_dau_agent() {
  printf -- '---\nname: %s\ndescription: %s\n---\n\n' "$1" "$2"
}

ad_dau_skill() {
  printf -- '---\nname: %s\ndescription: %s\n---\n\n' "$1" "$2"
}

ten_agent_checker() { printf 'soat-%s' "$(basename "$1" .md)"; }

# ad_doc_tham_so "$@" — --out <thư-mục> [--force]; từ chối --out nằm trong engine.
ad_doc_tham_so() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --out)   [ -n "${2:-}" ] || { echo "Thieu gia tri cho --out" >&2; exit 2; }; OUT="$2"; shift 2 ;;
      --force) FORCE=1; shift ;;
      *) echo "Tham so la: $1" >&2; exit 2 ;;
    esac
  done
  [ -n "$OUT" ] || { echo "Thieu --out <thu-muc-repo-dich>" >&2; exit 2; }
  if [ -d "$OUT" ]; then
    case "$(CDPATH= cd -- "$OUT" && pwd)/" in
      "$ROOT"/*)
        echo "LỖI: --out nằm trong repo agent-workflow ($OUT)." >&2
        echo "      Sinh vào đây sẽ lẫn $AD_GOC/ vào mã nguồn; hãy trỏ tới repo đích." >&2
        exit 2 ;;
    esac
  fi
}

ad_kiem_hook() {
  [ -n "${AD_ID:-}" ] && [ -n "${AD_TEN:-}" ] && [ -n "${AD_GOC:-}" ] ||
    { echo "LỖI: adapter thiếu AD_ID / AD_TEN / AD_GOC." >&2; exit 4; }
  for _h in $AD_HOOK; do
    command -v "$_h" >/dev/null 2>&1 || { echo "LỖI: adapter $AD_ID thiếu hook $_h (xem adapters/lib/chung.sh)." >&2; exit 4; }
  done
}

sinh_command() {
  id="$1"; file="$2"; req="$3"; when="$4"
  src="$ROOT/$file"
  name=$(fm_scalar "$src" name)
  summary=$(fm_scalar "$src" summary)
  clean=$(fm_scalar "$src" needs_clean_context)
  fresh=$(fm_scalar "$src" requires_fresh_agent)
  lc=$(fm_scalar "$src" llm_checker)
  args=$(fm_scalar "$src" arguments)
  if [ "$args" = "input" ]; then hint='[mã-issue | URL | đường-dẫn …]'; else hint='[tên-feature]'; fi
  ts=$(_hk ad_tham_so)

  _hk ad_dau_lenh "$id" "$name — $summary" "$hint"
  canh_bao "$file"
  _hk ad_mo_dau_lenh "$id" "$hint" "$args"
  buoc_xac_dinh_feature "$ts" "$args"
  [ "$args" = "input" ] && buoc_phan_loai_input "$ts"
  if [ "$(fm_scalar "$src" approval_gate)" = "true" ]; then
    buoc_cong_duyet "$id"
    _hk ad_hoi_cong_duyet "$id"
  fi

  printf '## Hợp đồng phase\n\n'
  if [ "$req" = "true" ]; then
    printf -- '- **Bắt buộc:** có\n'
  else
    printf -- '- **Bắt buộc:** không — chỉ chạy khi %s\n' "${when:-người dùng yêu cầu}"
  fi

  printf -- '- **Đọc vào:**\n'
  ins=$(fm_list "$src" inputs)
  if [ -z "$ins" ]; then
    printf -- '  - (không có — phase này không đọc artifact nào)\n'
  else
    echo "$ins" | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
  fi

  printf -- '- **Ghi ra:**\n'
  fm_list "$src" outputs | while IFS= read -r o; do [ -n "$o" ] && mo_ta_output "$o"; done

  fm_list "$src" outputs | while IFS= read -r o; do
    case "$o" in
      *.md)
        if [ -f "$ROOT/workflow/templates/$o" ]; then
          printf -- '- **Mẫu cho `%s`:** `%s/templates/%s` — đọc mẫu trước khi viết\n' "$o" "$DOCS" "$o"
        fi ;;
    esac
  done

  if [ -n "$lc" ]; then
    lco=$(fm_scalar "$ROOT/$lc" output)
    printf -- '- **Checker LLM — chỉ được CHẶN, không được DUYỆT.** Sau khi viết xong, gọi subagent `%s` (ngữ cảnh sạch) với `%s`; nó ghi `%s/%s`. Không có file đó = KHÔNG ĐẠT, không phải "không có gì để báo".\n' \
      "$(ten_agent_checker "$lc")" "$FD" "$FD" "$lco"
  fi

  em=$(fm_list "$src" exit_machine)
  if [ -n "$em" ]; then
    printf -- '- **Điều kiện ra — MÁY kiểm.** Bạn KHÔNG được tự tuyên bố đạt; phải chạy lệnh và dán kết quả thật:\n'
    echo "$em" | while IFS= read -r c; do [ -n "$c" ] && dich_lenh "$c"; done
  fi

  eh=$(fm_list "$src" exit_human)
  if [ -n "$eh" ]; then
    printf -- '- **Điều kiện ra — NGƯỜI xác nhận.** Nêu ra rồi dừng, không tự duyệt thay:\n'
    echo "$eh" | while IFS= read -r c; do [ -n "$c" ] && printf '  - %s\n' "$c"; done
  fi

  if [ "$clean" = "true" ]; then
    printf -- '- **Ngữ cảnh:** phase này phải chạy được từ phiên trắng. Chỉ nhận đầu vào từ file, không từ hội thoại phía trên.\n'
  fi
  if [ "$fresh" = "true" ]; then
    printf -- '- **Bắt buộc:** chạy qua subagent `ra-soat-doc-lap`, truyền cho nó `%s`. KHÔNG rà soát bằng chính phiên vừa viết code.\n' "$FD"
  fi

  printf '\n'
  doc_truoc
  case " $BL_QUY_TAC " in *" $id "*) buoc_quy_tac_repo "$id" ;; esac
  printf -- '---\n'
  md_body "$src"
}

# ad_sinh "$@" — sinh toàn bộ file native của adapter vào $OUT/$AD_GOC/.
ad_sinh() {
  ad_doc_tham_so "$@"
  ad_kiem_hook
  L="$OUT/$AD_GOC/commands"; A="$OUT/$AD_GOC/agents"; SK="$OUT/$AD_GOC/skills/quy-trinh-agent/SKILL.md"

  # Danh sach file sinh ra LAN NAY — de don file do lan truoc sinh ra ma nay
  # khong con trong manifest. Ghi ra file vi ghi_file chay trong subshell cua
  # pipeline, bien shell khong song sot.
  DA_SINH="${TMPDIR:-/tmp}/.aw_da_sinh.$$"
  PH_LIST="${TMPDIR:-/tmp}/.wf_phases.$$"
  CMD_LIST="${TMPDIR:-/tmp}/.wf_cmds.$$"
  : > "$DA_SINH"
  kq_don 'rm -f "$PH_LIST" "$DA_SINH" "$CMD_LIST"'

  # ---------- lệnh cho từng phase ----------
  wf_phases "$MANIFEST" > "$PH_LIST"
  REV_SRC=""; REV_FILE=""
  CHECKERS=""
  while IFS='|' read -r id file req when; do
    [ -n "$id" ] || continue
    src="$ROOT/$file"
    if [ ! -f "$src" ]; then
      echo "  CẢNH BÁO: bỏ qua /$id — không tìm thấy $file" >&2
      continue
    fi
    if [ "$(fm_scalar "$src" status)" = "chưa hiện thực" ]; then
      echo "  skip    /$id (status: chưa hiện thực)"
      continue
    fi
    kiem_tra_nguon "$src" "$file" || exit 4
    kiem_tra_ghi_de "$L/$id.md"
    sinh_command "$id" "$file" "$req" "$when" | ghi_file "$L/$id.md"
    if [ "$(fm_scalar "$src" requires_fresh_agent)" = "true" ]; then REV_SRC="$src"; REV_FILE="$file"; fi
    lc=$(fm_scalar "$src" llm_checker)
    [ -n "$lc" ] && CHECKERS="$CHECKERS $lc"
  done < "$PH_LIST"

  # ---------- subagent rà soát (phase có requires_fresh_agent) ----------
  if [ -n "$REV_SRC" ]; then
    kiem_tra_ghi_de "$A/ra-soat-doc-lap.md"
    {
      _hk ad_dau_agent ra-soat-doc-lap 'Rà soát độc lập diff theo spec.md, tdd.md và plan.md bằng ngữ cảnh sạch. Dùng cho phase review. Không dùng chính phiên vừa hiện thực để rà soát. Người gọi phải truyền thư mục feature.'
      canh_bao "$REV_FILE"
      printf 'Bạn là người rà soát độc lập. Bạn CHƯA từng nhìn thấy code này và không biết\n'
      printf 'gì về lập luận đã dẫn tới nó — đó chính là giá trị của bạn. Đừng suy đoán ý\n'
      printf 'định của người viết; chỉ đối chiếu code với đặc tả và thiết kế đã duyệt.\n\n'
      printf 'Người gọi truyền cho bạn `%s` (vd `%s/feat_tao-todo`). Không có thì dừng lại hỏi.\n\n' "$FD" "$ART"
      printf 'Đọc vào:\n'
      fm_list "$REV_SRC" inputs | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
      printf '\nGhi ra `%s/review.md` theo mẫu `%s/templates/review.md`, rồi chạy\n' "$FD" "$DOCS"
      printf '`aw check review %s` và dán kết quả thật.\n' "$FD"
      printf 'Đường dẫn `templates/`, `rules/` bên dưới nằm trong `%s/`.\n\n' "$DOCS"
      buoc_quy_tac_repo review
      printf -- '---\n'
      md_body "$REV_SRC"
    } | ghi_file "$A/ra-soat-doc-lap.md"
  fi

  # ---------- subagent cho từng checker LLM ----------
  for lc in $CHECKERS; do
    csrc="$ROOT/$lc"; ten=$(ten_agent_checker "$lc")
    # quy_tac: <phase> — checker đọc quy tắc riêng của repo cho phase đó
    cqt=$(fm_scalar "$csrc" quy_tac)
    if [ -n "$cqt" ]; then
      case " $BL_QUY_TAC " in
        *" $cqt "*) ;;
        *) echo "LỖI: $lc khai quy_tac \"$cqt\" — chỉ nhận: $BL_QUY_TAC" >&2; exit 4 ;;
      esac
    fi
    kiem_tra_ghi_de "$A/$ten.md"
    {
      _hk ad_dau_agent "$ten" "$(fm_scalar "$csrc" summary) Người gọi phải truyền thư mục feature."
      canh_bao "$lc"
      printf 'Người gọi truyền cho bạn `%s`. Không có thì dừng lại hỏi.\n\n' "$FD"
      printf 'Đọc vào:\n'
      fm_list "$csrc" inputs | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
      printf '\nGhi ra `%s/%s` theo mẫu `%s/templates/%s`.\n\n' "$FD" "$(fm_scalar "$csrc" output)" "$DOCS" "$(fm_scalar "$csrc" output)"
      [ -n "$cqt" ] && buoc_quy_tac_repo "$cqt"
      printf -- '---\n'
      md_body "$csrc"
    } | ghi_file "$A/$ten.md"
  done

  # ---------- lệnh tiện ích (commands: trong manifest) ----------
  # Khong phai phase: khong co hop dong vao/ra, chi co buoc xac dinh feature + than.
  # arguments: (bo trong) = tham so la ten feature; mixed = con tham so khac, ten
  # feature (neu co) nam lan trong do — agent tach ra.
  wf_commands "$MANIFEST" > "$CMD_LIST"
  while IFS='|' read -r cid cfile; do
    [ -n "$cid" ] || continue
    csrc="$ROOT/$cfile"
    [ -f "$csrc" ] || { echo "LỖI: workflow.yaml khai lệnh \"$cid\" → \"$cfile\" nhưng không có file đó." >&2; exit 4; }
    case "$(fm_scalar "$csrc" choice_ui)" in
      ""|true) ;;
      *) echo "LỖI: $cfile khai choice_ui \"$(fm_scalar "$csrc" choice_ui)\" — chỉ nhận \"true\" (bỏ trống = không)." >&2; exit 4 ;;
    esac
    cargs=$(fm_scalar "$csrc" arguments)
    case "$cargs" in
      ""|mixed) ;;
      *) echo "LỖI: $cfile khai arguments \"$cargs\" — lệnh tiện ích chỉ nhận \"mixed\" (bỏ trống = tên feature)." >&2; exit 4 ;;
    esac
    kiem_tra_ghi_de "$L/$cid.md"
    {
      _h=$(fm_scalar "$csrc" argument_hint); _h=${_h:-[tên-feature]}
      ts=$(_hk ad_tham_so)
      _hk ad_dau_lenh "$cid" "$(fm_scalar "$csrc" name) — $(fm_scalar "$csrc" summary)" "$_h"
      canh_bao "$cfile"
      _hk ad_mo_dau_lenh "$cid" "$_h" "$cargs"
      if [ "$cargs" = "mixed" ]; then
        printf 'Tham số: `%s`\n\n' "$ts"
        buoc_xac_dinh_feature '<tên-feature nếu người dùng truyền>'
      else
        buoc_xac_dinh_feature "$ts"
      fi
      [ "$(fm_scalar "$csrc" choice_ui)" = "true" ] && _hk ad_hoi_lua_chon
      doc_truoc
      printf -- '---\n'
      md_body "$csrc"
    } | ghi_file "$L/$cid.md"
  done < "$CMD_LIST"

  # ---------- skill tổng ----------
  kiem_tra_ghi_de "$SK"
  {
    _hk ad_dau_skill quy-trinh-agent 'Quy trình phát triển dựa trên AI agent của repo này. Dùng khi bắt đầu một tính năng mới, khi viết đặc tả từ BRD/PRD hoặc ticket Jira/Confluence, khi thiết kế kỹ thuật, khi lập kế hoạch, khi hiện thực theo kế hoạch, khi rà soát thay đổi, khi đưa tài liệu từ tool khác vào quy trình, khi cần chốt điểm mù (open questions) hoặc phân xử phát hiện của checker LLM đang chặn phase, hoặc khi được hỏi quy trình làm việc của repo này là gì.'
    printf '# Quy trình phát triển dựa trên AI agent\n\n'
    canh_bao "workflow.yaml"
    printf 'Repo này theo một quy trình có phase. Mỗi phase nhận đầu vào là **file** do\n'
    printf 'phase trước ghi ra, không phải ngữ cảnh hội thoại. Nhờ vậy mỗi phase chạy\n'
    printf 'được từ phiên trắng, và quy trình không phụ thuộc vào một agent cụ thể.\n\n'
    printf '## Các phase\n\n'
    printf '| Lệnh | Phase | Ghi ra | Bắt buộc |\n'
    printf '|---|---|---|---|\n'
    while IFS='|' read -r id file req when; do
      [ -n "$id" ] || continue
      src="$ROOT/$file"
      [ -f "$src" ] || continue
      [ "$(fm_scalar "$src" status)" = "chưa hiện thực" ] && continue
      nm=$(fm_scalar "$src" name)
      oo=$(fm_list "$src" outputs | tr '\n' ',' | sed 's/,$//; s/,/, /g')
      if [ "$req" = "true" ]; then bb="có"; else bb="không"; fi
      printf '| `/%s` | %s | %s | %s |\n' "$id" "$nm" "${oo:-—}" "$bb"
    done < "$PH_LIST"
    if [ -s "$CMD_LIST" ]; then
      printf '\n## Lệnh tiện ích (không phải phase)\n\n'
      while IFS='|' read -r cid cfile; do
        [ -n "$cid" ] || continue
        printf -- '- `/%s` — %s\n' "$cid" "$(fm_scalar "$ROOT/$cfile" summary)"
      done < "$CMD_LIST"
    fi
    printf '\n## Luật không được vi phạm\n\n'
    luat_tom_tat
    printf '## Artifact và lệnh\n\n'
    printf -- '- Artifact của từng feature: `%s/<tên-branch>/` — xác định bằng `aw feature`; nằm ngoài git (bị exclude)\n' "$ART"
    printf -- '- Quy ước của repo (branch, nhánh gốc, file test, tag `covers:`): `%s`\n' "$CONV_DOC"
    printf -- '- Quy tắc riêng của repo cho từng phase (coding style, skill, chuẩn kiến trúc): `aw rules <phase>` — phase: %s\n' "$BL_QUY_TAC"
    printf -- '- Luật, mẫu, checker LLM của engine: `%s/`\n' "$DOCS"
    printf -- '- Checker máy: `aw check <tên> %s` — tên: %s\n' "$FD" "$BL_CHECKERS"
  } | ghi_file "$SK"

  # ---------- dọn file cũ ----------
  don_file_cu "$L"/*.md "$A"/*.md
}
