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

# Tên lệnh trong repo đích: /aw-<id> (file commands/aw-<id>.md). Tiền tố gom mọi
# lệnh của quy trình lại khi gõ "/aw-" và không đụng lệnh của team. Dấu "-" chứ
# không phải "aw:" (thư mục con): agent nào cũng hiểu tên file thường, và tên
# trùng nhau giữa các adapter (Cursor nạp .claude/ để tương thích, .cursor/ che).
TIEN_TO_LENH="aw-"
ten_lenh() { printf '%s%s' "$TIEN_TO_LENH" "$1"; }

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
  printf '> **File này được SINH TỰ ĐỘNG** từ `%s` (engine agent-workflow %s) bởi `aw adapter build` — đừng sửa, sẽ bị sinh lại.\n' "$1" "$(cat "$ROOT/VERSION" 2>/dev/null)"
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
  _mc=$(fm_scalar "$_src" runs_on_main_checkout)
  case "$_mc" in
    ""|true) ;;
    *) echo "LỖI: $_file khai runs_on_main_checkout \"$_mc\" — chỉ nhận \"true\" (bỏ trống = không)." >&2; _bad=1 ;;
  esac
  if [ "$_mc" = true ] && [ "$_ar" = input ]; then
    echo "LỖI: $_file khai cả runs_on_main_checkout và arguments: input — phase input đã có lối riêng ở checkout chính." >&2; _bad=1
  fi
  _lc=$(fm_scalar "$_src" llm_checker)
  if [ -n "$_lc" ] && [ ! -f "$ROOT/$_lc" ]; then
    echo "LỖI: $_file khai llm_checker \"$_lc\" nhưng không có file đó." >&2
    _bad=1
  fi
  [ "$_bad" = "0" ]
}

dich_lenh() {
  printf '  - `%s %s` → `[x] ĐẠT`\n' "$1" "$FD"
}

mo_ta_input() {
  case "$1" in
    confluence) printf '  - Confluence (MCP Atlassian) — ghi URL + heading\n' ;;
    jira)       printf '  - Jira (MCP Atlassian) — ghi mã issue + URL\n' ;;
    file)       printf '  - File trong repo (kể cả incident note) — ghi đường dẫn + heading\n' ;;
    diff)       printf '  - Diff so với base (`git diff`, `git status`)\n' ;;
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
#   buoc_xac_dinh_feature <cách-viết-tham-số> [input] [true = phase có việc ở checkout chính]
buoc_xac_dinh_feature() {
  printf '## Bước 0 — Xác định feature (luôn làm trước)\n\n'
  printf 'Mọi lệnh `aw …` (engine agent-workflow, cài global) in khối `Kết quả` cuối output — làm theo nhãn được đánh `[x]`.\n\n'
  if [ "${2:-}" = "input" ]; then
    # Tham so cua lenh la INPUT, khong phai ten feature: khong truyen vao aw feature,
    # neu khong "/aw-intake JIRA-123" se tao thu muc artifact ten JIRA-123.
    printf 'Chạy `aw feature` — **không** truyền tham số của lệnh (tham số là input, không phải tên feature):\n\n'
    printf -- '- **ĐÃ XÁC ĐỊNH:** stdout = `%s`. In `Đang làm với: %s` rồi mới đọc/ghi.\n' "$FD" "$FD"
    printf -- '- **ĐANG Ở CHECKOUT CHÍNH:** làm mục "Tạo worktree" của mô tả phase: chốt loại việc, `aw worktree new` để **đề xuất**, NGƯỜI chọn base, rồi mới `--create --base <ref>`. Ghi `intake.md` vào worktree mới rồi dừng.\n'
    printf -- '- **CẦN HỎI NGƯỜI:** trong worktree nhưng branch không khớp quy ước → dừng, hỏi người. Không tự đặt tên.\n\n'
  else
    printf 'Chạy `aw feature %s`:\n\n' "$1"
    printf -- '- **ĐÃ XÁC ĐỊNH:** stdout = `%s`. In `Đang làm với: %s` rồi mới đọc/ghi.\n' "$FD" "$FD"
    if [ "${3:-}" = "true" ]; then
      printf -- '- **ĐANG Ở CHECKOUT CHÍNH:** làm mục "Ở checkout chính" của mô tả phase (không cần thư mục feature). Không tự chuyển thư mục.\n'
    else
      printf -- '- **ĐANG Ở CHECKOUT CHÍNH:** dừng lại — bảo người mở phiên trong worktree của việc (chưa có → `/aw-intake` ở checkout chính). Không tự chuyển thư mục.\n'
    fi
    printf -- '- **CẦN HỎI NGƯỜI:** dừng, hỏi người tên feature. Không tự đặt tên.\n'
    printf -- '- **TÊN KHÔNG HỢP LỆ:** báo người.\n\n'
  fi
  printf '`templates/`, `rules/`, `checkers/` trong mô tả nằm ở `%s/`. Mọi `aw check` chạy đúng version ở dòng `Engine:` của `intake.md` — không sửa dòng đó.\n\n' "$DOCS"
}

# Buoc 0b cua /aw-intake: tham so -> dong "## Input". Nhan do engine gan, khong do
# agent doan; nguyen van di qua heredoc co nhay de khong bi shell dien giai.
#   buoc_phan_loai_input <cách-viết-tham-số>
buoc_phan_loai_input() {
  printf '## Bước 0b — Tham số thành input\n\n'
  printf 'Tham số: `%s`. Bước này không cần thư mục feature (Bước 0 ra `CẦN HỎI NGƯỜI` thì chạy nó trước để có input mà chốt loại việc).\n\n' "$1"
  printf '**Không tự gán nhãn.** Chạy đúng như dưới, giữ nguyên văn tham số; thêm `--skip %s/intake.md` khi file đó **đã có** (chạy lại = gộp thêm):\n\n' "$FD"
  printf '```sh\naw input [--skip %s/intake.md] - <<'"'"'HET_INPUT'"'"'\n%s\nHET_INPUT\n```\n\n' "$FD" "$1"
  printf 'Stdout = **đúng các dòng** ghi vào `## Input`, chép nguyên:\n\n'
  printf -- '- **NGUỒN:** mọi tham số là nguồn. Stdout rỗng = không có input mới.\n'
  printf -- '- **LỜI NGƯỜI DÙNG:** stdout là một mục `[HUMAN]` nguyên văn. Stderr có "Đề xuất tách thêm" → hỏi người, đồng ý mới ghi.\n'
  printf -- '- **KHÔNG CÓ THAM SỐ:** hỏi người input, chạy lại với **nguyên văn** câu trả lời.\n'
  printf -- '- **ĐƯỜNG DẪN KHÔNG TỒN TẠI:** hỏi lại người. Không đoán.\n\n'
}

# buoc_cong_duyet <phase> — phase khai approval_gate: true. Người gõ lệnh phase
# tiếp theo khi phần trước chưa duyệt: agent KHÔNG tick hộ, chỉ cho người thấy rõ
# còn gì chờ duyệt (máy dựng: aw approval) rồi hỏi. Cách hỏi cụ thể do adapter
# thêm ngay sau (Claude Code: AskUserQuestion); adapter không có giao diện lựa
# chọn thì in lựa chọn đánh số.
buoc_cong_duyet() {
  case "$1" in
    design) _cd_gi="spec"; _cd_lenh="/aw-design" ;;
    plan)   _cd_gi="mọi quyết định D-xx (chore: spec)"; _cd_lenh="/aw-plan" ;;
    *)      _cd_gi="phần trước"; _cd_lenh="/$(ten_lenh "$1")" ;;
  esac
  printf '## Bước 1 — Cổng duyệt (ngay sau Bước 0, trước mọi việc khác)\n\n'
  printf 'Vào `%s` cần %s đã được **người** duyệt. Gõ lệnh không phải là duyệt; agent **không** tick.\n\n' "$_cd_lenh" "$_cd_gi"
  printf 'Chạy `aw approval %s %s`:\n\n' "$1" "$FD"
  printf -- '- **ĐÃ DUYỆT:** đi tiếp, không hỏi.\n'
  printf -- '- **CHƯA DUYỆT:** in **nguyên văn** stdout trong khối ```` ```text ```` (không tóm tắt), rồi hỏi **hộp xác nhận**. Dừng tới khi người chọn.\n'
  printf -- '- **SAI THAM SỐ HOẶC THIẾU FILE:** thiếu file → báo người chạy phase trước. Lệnh không tồn tại (engine cũ) → bỏ qua bước này (`aw check` vẫn chặn).\n\n'
  printf '**Hộp xác nhận** — ba lựa chọn, đúng thứ tự:\n\n'
  printf '1. **Tôi đã duyệt xong — kiểm lại** → chạy lại `aw approval %s %s`. ĐÃ DUYỆT → báo một dòng ("Đã thấy bạn duyệt — vào %s"), đi tiếp. Vẫn CHƯA DUYỆT → chỉ in lại `Trạng thái` và `Cách duyệt`/`Chưa duyệt`, hỏi lại.\n' "$1" "$FD" "$_cd_lenh"
  printf '2. **Giải thích từng điểm cần duyệt** → mỗi mục trong stdout 2–3 dòng: nói gì, nguồn ở đâu, duyệt sai thì hậu quả gì. Chỉ đọc từ file. Xong hỏi lại.\n'
  printf '3. **Dừng — tôi duyệt sau** → không làm gì của phase; nhắc gõ lại `%s` sau khi duyệt.\n\n' "$_cd_lenh"
  printf '"Duyệt hộ", "tick giúp", "ok cứ làm đi"… → **từ chối** một dòng (chỉ người được tick), chỉ đúng file và dòng, hỏi lại. Muốn sửa nội dung → việc của `/aw-spec` (D-xx: `/aw-design`), không sửa ở đây.\n\n'
}

# doc_truoc — mục "Đọc trước khi làm" chung
doc_truoc() {
  printf '**Đọc trước:** `%s/rules/nguyen-tac-chung.md`' "$DOCS"
  if [ "${1:-}" = "true" ]; then printf ', `%s/rules/truy-vet-nguon.md`' "$DOCS"; fi
  printf '. Quy ước repo (tra khi cần): `%s`.\n\n' "$CONV_DOC"
}

# buoc_quy_tac_repo <phase> — đọc quy tắc riêng của repo. Danh sách lấy LÚC CHẠY
# bằng `aw rules`, không chép vào lúc build: conventions.md sửa là có hiệu lực ngay.
buoc_quy_tac_repo() {
  printf '**Quy tắc riêng của repo:** chạy `aw rules %s` — **ĐÃ LIỆT KÊ:** đọc từng file in ra trước khi làm (không in gì = không có) · **KHAI SAI:** dừng, báo người sửa `rules_*` trong `%s`, không đoán file thay thế. Thứ tự ưu tiên: `rules/nguyen-tac-chung.md` § 7.\n\n' "$1" "$CONV_DOC"
}

# luat_tom_tat — bảy luật không được vi phạm, dùng trong file tổng của agent
luat_tom_tat() {
  printf '1. **Bàn giao bằng file** — không nhận đầu vào từ hội thoại phía trên.\n'
  printf '2. **Không tự tuyên bố đạt** — chạy `aw check …`, dán kết quả thật.\n'
  printf '3. **Không tự duyệt** — không tick "Approved by human", không sửa `approval-hash`; sửa nội dung đã tick thì bỏ tick. Checker LLM chỉ được chặn.\n'
  printf '4. **Không vượt phạm vi phase** — việc của phase khác thì ghi lại.\n'
  printf '5. **Không xoá artifact phase trước** — chạy lại là cập nhật.\n'
  printf '6. **Mọi yêu cầu truy được về nguồn.**\n'
  printf '7. **Artifact viết cho người đọc** — tiếng Việt, phân cấp rõ, câu ngắn.\n\n'
  printf 'Bản đầy đủ: `%s/rules/`.\n\n' "$DOCS"
}

# ======================================================================
# Hook của adapter — adapter PHẢI định nghĩa (ad_sinh kiểm trước khi sinh):
#
#   ad_tham_so                     cách viết tham số của lệnh trong lời dặn
#                                  (Claude Code: $ARGUMENTS — agent tự thay)
#   ad_dau_lenh <lệnh> <name> <summary> <gợi-ý-tham-số>
#                                  phần đầu file lệnh (frontmatter…); <lệnh> là tên
#                                  người gõ, không có "/" (vd aw-spec). Mô tả hiện
#                                  trong menu là <summary> — <name> lặp lại tên phase
#   ad_mo_dau_lenh <lệnh> <gợi-ý-tham-số> <arguments>
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

  _hk ad_dau_lenh "$(ten_lenh "$id")" "$name" "$summary" "$hint"
  canh_bao "$file"
  _hk ad_mo_dau_lenh "$(ten_lenh "$id")" "$hint" "$args"
  buoc_xac_dinh_feature "$ts" "$args" "$(fm_scalar "$src" runs_on_main_checkout)"
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

  printf -- '- **Đọc:**\n'
  ins=$(fm_list "$src" inputs)
  if [ -z "$ins" ]; then
    printf -- '  - (không đọc artifact nào)\n'
  else
    echo "$ins" | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
  fi

  printf -- '- **Ghi:**\n'
  fm_list "$src" outputs | while IFS= read -r o; do
    [ -n "$o" ] || continue
    mo_ta_output "$o"
    case "$o" in
      *.md) if [ -f "$ROOT/workflow/templates/$o" ]; then printf '    — mẫu `%s/templates/%s` (đọc trước khi viết)\n' "$DOCS" "$o"; fi ;;
    esac
  done

  if [ -n "$lc" ]; then
    lco=$(fm_scalar "$ROOT/$lc" output)
    printf -- '- **Checker LLM (chỉ CHẶN, không DUYỆT):** viết xong thì gọi subagent `%s` (ngữ cảnh sạch) với `%s`; nó ghi `%s/%s`. Thiếu file đó = KHÔNG ĐẠT.\n' \
      "$(ten_agent_checker "$lc")" "$FD" "$FD" "$lco"
  fi

  em=$(fm_list "$src" exit_machine)
  if [ -n "$em" ]; then
    printf -- '- **Điều kiện ra — MÁY** (chạy và dán kết quả thật, không tự tuyên bố đạt):\n'
    echo "$em" | while IFS= read -r c; do [ -n "$c" ] && dich_lenh "$c"; done
  fi

  eh=$(fm_list "$src" exit_human)
  if [ -n "$eh" ]; then
    printf -- '- **Điều kiện ra — NGƯỜI** (nêu ra rồi dừng, không duyệt thay):\n'
    echo "$eh" | while IFS= read -r c; do [ -n "$c" ] && printf '  - %s\n' "$c"; done
  fi

  if [ "$clean" = "true" ]; then
    printf -- '- **Ngữ cảnh:** chạy được từ phiên trắng; chỉ nhận đầu vào từ file.\n'
  fi
  if [ "$fresh" = "true" ]; then
    printf -- '- **Bắt buộc:** chạy qua subagent `ra-soat-doc-lap`, truyền `%s`. KHÔNG rà soát bằng phiên vừa viết code.\n' "$FD"
  fi

  printf '\n'
  if [ "$fresh" = "true" ]; then
    # Phiên chính chỉ bàn giao: mô tả phase đầy đủ nằm trong subagent, nạp ở đây là phí ngữ cảnh.
    _o=$(fm_list "$src" outputs | head -1); _c=$(fm_list "$src" exit_machine | head -1)
    printf '## Việc của phiên này\n\n'
    printf '1. Gọi subagent `ra-soat-doc-lap` với `%s`. Nó đọc mô tả phase đầy đủ, ghi `%s`, chạy `%s`. Phiên này **không** tự rà, không sửa `%s`.\n' "$FD" "$_o" "$_c" "$_o"
    printf '2. Subagent xong: đưa người kết luận và kết quả `%s` thật; nêu các điều kiện ra NGƯỜI ở trên rồi dừng.\n' "$_c"
    printf '3. Không gọi được subagent: bảo người mở phiên mới, chỉ nạp file subagent `ra-soat-doc-lap` + thư mục feature.\n'
    return 0
  fi
  doc_truoc "$(fm_scalar "$src" trace_rule)"
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
      echo "  CẢNH BÁO: bỏ qua /$(ten_lenh "$id") — không tìm thấy $file" >&2
      continue
    fi
    if [ "$(fm_scalar "$src" status)" = "chưa hiện thực" ]; then
      echo "  skip    /$(ten_lenh "$id") (status: chưa hiện thực)"
      continue
    fi
    kiem_tra_nguon "$src" "$file" || exit 4
    kiem_tra_ghi_de "$L/$(ten_lenh "$id").md"
    sinh_command "$id" "$file" "$req" "$when" | ghi_file "$L/$(ten_lenh "$id").md"
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
      printf 'Bạn là người rà soát độc lập: CHƯA từng thấy code này hay lập luận dẫn tới nó. Không đoán ý người viết; chỉ đối chiếu code với đặc tả và thiết kế đã duyệt.\n\n'
      printf 'Người gọi truyền `%s` (vd `%s/feat_tao-todo`); không có thì dừng, hỏi.\n\n' "$FD" "$ART"
      printf 'Đọc:\n'
      fm_list "$REV_SRC" inputs | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
      printf '\nGhi `%s/review.md` theo mẫu `%s/templates/review.md`, rồi chạy `aw check review %s`, dán kết quả thật. `templates/`, `rules/` bên dưới nằm ở `%s/`.\n\n' "$FD" "$DOCS" "$FD" "$DOCS"
      doc_truoc
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
      printf 'Người gọi truyền `%s`; không có thì dừng, hỏi.\n\n' "$FD"
      printf 'Đọc:\n'
      fm_list "$csrc" inputs | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
      printf '\nGhi `%s/%s` theo mẫu `%s/templates/%s`.\n\n' "$FD" "$(fm_scalar "$csrc" output)" "$DOCS" "$(fm_scalar "$csrc" output)"
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
    kiem_tra_ghi_de "$L/$(ten_lenh "$cid").md"
    {
      _h=$(fm_scalar "$csrc" argument_hint); _h=${_h:-[tên-feature]}
      ts=$(_hk ad_tham_so)
      _hk ad_dau_lenh "$(ten_lenh "$cid")" "$(fm_scalar "$csrc" name)" "$(fm_scalar "$csrc" summary)" "$_h"
      canh_bao "$cfile"
      _hk ad_mo_dau_lenh "$(ten_lenh "$cid")" "$_h" "$cargs"
      if [ "$cargs" = "mixed" ]; then
        printf 'Tham số: `%s`\n\n' "$ts"
        buoc_xac_dinh_feature '<tên-feature nếu người dùng truyền>'
      else
        buoc_xac_dinh_feature "$ts"
      fi
      [ "$(fm_scalar "$csrc" choice_ui)" = "true" ] && _hk ad_hoi_lua_chon
      doc_truoc "$(fm_scalar "$csrc" trace_rule)"
      printf -- '---\n'
      md_body "$csrc"
    } | ghi_file "$L/$(ten_lenh "$cid").md"
  done < "$CMD_LIST"

  # ---------- skill tổng ----------
  kiem_tra_ghi_de "$SK"
  {
    _hk ad_dau_skill quy-trinh-agent 'Quy trình phát triển dựa trên AI agent của repo này. Dùng khi bắt đầu một tính năng mới, khi viết đặc tả từ BRD/PRD hoặc ticket Jira/Confluence, khi thiết kế kỹ thuật, khi lập kế hoạch, khi hiện thực theo kế hoạch, khi rà soát thay đổi, khi đưa tài liệu từ tool khác vào quy trình, khi cần chốt điểm mù (open questions) hoặc phân xử phát hiện của checker LLM đang chặn phase, hoặc khi được hỏi quy trình làm việc của repo này là gì.'
    printf '# Quy trình phát triển dựa trên AI agent\n\n'
    canh_bao "workflow.yaml"
    printf 'Mỗi phase nhận đầu vào là **file** phase trước ghi, không phải hội thoại — chạy được từ phiên trắng, bằng agent nào cũng được.\n\n'
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
      printf '| `/%s` | %s | %s | %s |\n' "$(ten_lenh "$id")" "$nm" "${oo:-—}" "$bb"
    done < "$PH_LIST"
    if [ -s "$CMD_LIST" ]; then
      printf '\n## Lệnh tiện ích (không phải phase)\n\n'
      while IFS='|' read -r cid cfile; do
        [ -n "$cid" ] || continue
        printf -- '- `/%s` — %s\n' "$(ten_lenh "$cid")" "$(fm_scalar "$ROOT/$cfile" summary)"
      done < "$CMD_LIST"
    fi
    printf '\n## Luật không được vi phạm\n\n'
    luat_tom_tat
    printf '## Artifact và lệnh\n\n'
    printf -- '- Artifact của việc: `%s/<tên-branch>/` (`aw feature`; ngoài git)\n' "$ART"
    printf -- '- Quy ước repo: `%s`; quy tắc riêng từng phase: `aw rules <phase>` (%s)\n' "$CONV_DOC" "$BL_QUY_TAC"
    printf -- '- Luật, mẫu, checker LLM của engine: `%s/`\n' "$DOCS"
    printf -- '- Checker máy: `aw check <tên> %s` — tên: %s\n' "$FD" "$BL_CHECKERS"
    printf -- '- Đầu phiên: `aw ready %s` (môi trường đủ chưa, bước tiếp)\n' "$FD"
    printf -- '- Task: `aw task next|start|done %s [T-NN]` — không tự sửa `Status`\n' "$FD"
    printf -- '- Agent làm hỏng mà checker không bắt: `aw journal add <task|context|env|verify|state|model> "<mô tả>"`\n'
  } | ghi_file "$SK"

  # ---------- dọn file cũ ----------
  don_file_cu "$L"/*.md "$A"/*.md
}
