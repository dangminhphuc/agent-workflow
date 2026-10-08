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
#                                   quy ước hiệu lực (repo + khoá máy của bản clone)

. "$ROOT/tools/lib/md.sh"
. "$ROOT/tools/lib/ket-qua.sh"
. "$ROOT/tools/lib/bang-lenh.sh"
. "$ROOT/adapters/lib/dinh-dang.sh"
kq_khai build.sh \
  "0=ĐÃ SINH" \
  "2=SAI THAM SỐ" \
  "3=CÓ FILE VIẾT TAY — không ghi đè; dời file đó đi hoặc dùng --force" \
  "4=ĐỊNH NGHĨA QUY TRÌNH LỖI — sửa workflow/ trong repo agent-workflow" \
  "5=SAI CHUẨN $AD_TEN — file sinh ra không đúng định dạng $AD_TEN đọc; sửa adapters/$AD_ID/build.sh hoặc workflow/"

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
  cat > "$_tmp" || { rm -f "$_tmp"; exit 4; }
  # Sai chuẩn của agent: không cho vào chỗ — agent sẽ lặng lẽ bỏ qua hay hiểu sai file.
  if [ "${AW_DOI_CHIEU:-}" != 1 ] && ! dd_kiem "$_tmp" "$1"; then rm -f "$_tmp"; exit 5; fi
  mv "$_tmp" "$1"; echo "$1" >> "$DA_SINH"; echo "  build   ${1#"$OUT"/}"
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
  printf '> **File này được SINH TỰ ĐỘNG** từ `%s` (engine agent-workflow %s) bởi `aw adapter build` — generated, do not edit.\n' "$1" "$(cat "$ROOT/VERSION" 2>/dev/null)"
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
    confluence) printf '  - Confluence (MCP Atlassian) — record URL + heading\n' ;;
    jira)       printf '  - Jira (MCP Atlassian) — record issue key + URL\n' ;;
    file)       printf '  - Repo files (incl. incident notes) — record path + heading\n' ;;
    diff)       printf '  - Diff against the base (`git diff`, `git status`)\n' ;;
    *.md)       printf '  - `%s/%s`\n' "$FD" "$1" ;;
    *".md ("*)  printf '  - `%s/%s` (%s\n' "$FD" "${1%% (*}" "${1#* (}" ;;
    *)          printf '  - %s\n' "$1" ;;
  esac
}

mo_ta_output() {
  case "$1" in
    diff) printf '  - Code changes in the repo\n' ;;
    *)    printf '  - `%s/%s`\n' "$FD" "$1" ;;
  esac
}

# Buoc 0 cua moi lenh: xac dinh feature. Thu tu branch -> tham so -> hoi la
# giao dien chung giua cac adapter, nen no nam trong engine (aw feature), khong trong prompt.
#   buoc_xac_dinh_feature <cách-viết-tham-số> [input] [true = phase có việc ở checkout chính]
buoc_xac_dinh_feature() {
  printf '## Step 0 — Identify the feature (always first)\n\n'
  printf 'Talk to the human in Vietnamese. Every `aw …` command (agent-workflow engine, installed globally) ends with a `Kết quả` block — act on the label marked `[x]`.\n\n'
  if [ "${2:-}" = "input" ]; then
    # Tham so cua lenh la INPUT, khong phai ten feature: khong truyen vao aw feature,
    # neu khong "/aw-intake JIRA-123" se tao thu muc artifact ten JIRA-123.
    printf 'Run `aw feature` — **do not** pass the command arguments (they are input, not a feature name):\n\n'
    printf -- '- **ĐÃ XÁC ĐỊNH:** stdout = `%s`. Print `Đang làm với: %s` before reading/writing anything.\n' "$FD" "$FD"
    printf -- '- **ĐANG Ở CHECKOUT CHÍNH:** follow "Create the worktree" in the phase description: agree the work type, `aw worktree new` to **propose**, the HUMAN picks the base, only then `--create --base <ref>`. Write `intake.md` in the new worktree, then stop.\n'
    printf -- '- **CẦN HỎI NGƯỜI:** in a worktree whose branch does not match the convention → stop, ask the human. Never invent a name.\n\n'
  else
    printf 'Run `aw feature %s`:\n\n' "$1"
    printf -- '- **ĐÃ XÁC ĐỊNH:** stdout = `%s`. Print `Đang làm với: %s` before reading/writing anything.\n' "$FD" "$FD"
    if [ "${3:-}" = "true" ]; then
      printf -- '- **ĐANG Ở CHECKOUT CHÍNH:** follow "On the main checkout" in the description below (no feature dir needed). Never change directory yourself.\n'
    else
      printf -- '- **ĐANG Ở CHECKOUT CHÍNH:** stop — tell the human to open a session in the job'"'"'s worktree (none yet → `/aw-intake` on the main checkout). Never change directory yourself.\n'
    fi
    printf -- '- **CẦN HỎI NGƯỜI:** stop, ask the human for the feature name. Never invent one.\n'
    printf -- '- **TÊN KHÔNG HỢP LỆ:** tell the human.\n\n'
  fi
  printf '`templates/`, `rules/`, `checkers/` in the description live in `%s/`. Every `aw check` runs the engine version on the `Engine:` line of `intake.md` — never edit that line.\n\n' "$DOCS"
}

# Buoc 0b cua /aw-intake: tham so -> dong "## Input". Nhan do engine gan, khong do
# agent doan; nguyen van di qua heredoc co nhay de khong bi shell dien giai.
#   buoc_phan_loai_input <cách-viết-tham-số>
buoc_phan_loai_input() {
  printf '## Step 0b — Arguments to input\n\n'
  printf 'Arguments: `%s`. Needs no feature dir (if Step 0 gives `CẦN HỎI NGƯỜI`, run this first to have input for agreeing the work type).\n\n' "$1"
  printf '**Never label input yourself.** Run exactly as below, arguments verbatim; add `--skip %s/intake.md` when that file **already exists** (rerun = append):\n\n' "$FD"
  printf '```sh\naw input [--skip %s/intake.md] - <<'"'"'HET_INPUT'"'"'\n%s\nHET_INPUT\n```\n\n' "$FD" "$1"
  printf 'Stdout = **exactly the lines** for `## Input`, copy unchanged:\n\n'
  printf -- '- **NGUỒN:** all arguments are sources. Empty stdout = no new input.\n'
  printf -- '- **LỜI NGƯỜI DÙNG:** stdout is one verbatim `[HUMAN]` entry. Stderr has "Đề xuất tách thêm" → ask the human; add those lines only if they agree.\n'
  printf -- '- **KHÔNG CÓ THAM SỐ:** ask the human for input, rerun with their **verbatim** answer.\n'
  printf -- '- **ĐƯỜNG DẪN KHÔNG TỒN TẠI:** ask the human again. Never guess.\n\n'
}

# buoc_cong_duyet <phase> — phase khai approval_gate: true. Người gõ lệnh phase
# tiếp theo khi phần trước chưa duyệt: agent KHÔNG tick hộ, chỉ cho người thấy rõ
# còn gì chờ duyệt (máy dựng: aw approval) rồi hỏi. Cách hỏi cụ thể do adapter
# thêm ngay sau (Claude Code: AskUserQuestion); adapter không có giao diện lựa
# chọn thì in lựa chọn đánh số.
buoc_cong_duyet() {
  case "$1" in
    design) _cd_gi="the spec"; _cd_lenh="/aw-design" ;;
    plan)   _cd_gi="every D-xx decision (chore: the spec)"; _cd_lenh="/aw-plan" ;;
    *)      _cd_gi="the previous phase"; _cd_lenh="/$(ten_lenh "$1")" ;;
  esac
  printf '## Step 1 — Approval gate (right after Step 0, before anything else)\n\n'
  printf '`%s` needs %s approved by a **human**. Typing the command is not approval; the agent **never** ticks.\n\n' "$_cd_lenh" "$_cd_gi"
  printf 'Run `aw approval %s %s`:\n\n' "$1" "$FD"
  printf -- '- **ĐÃ DUYỆT:** continue, ask nothing.\n'
  printf -- '- **CHƯA DUYỆT:** print stdout **verbatim** in a ```` ```text ```` block (no summarising), then ask the **confirmation box**. Wait for the human'"'"'s choice.\n'
  printf -- '- **SAI THAM SỐ HOẶC THIẾU FILE:** missing file → tell the human to run the previous phase. Command missing (old engine) → skip this step (`aw check` still blocks).\n\n'
  printf '**Confirmation box** — three options, in this order (labels shown to the human, keep verbatim):\n\n'
  printf '1. **Tôi đã duyệt xong — kiểm lại** → rerun `aw approval %s %s`. ĐÃ DUYỆT → one line ("Đã thấy bạn duyệt — vào %s"), continue. Still CHƯA DUYỆT → reprint only `Trạng thái` and `Cách duyệt`/`Chưa duyệt`, ask again.\n' "$1" "$FD" "$_cd_lenh"
  printf '2. **Giải thích từng điểm cần duyệt** → 2–3 lines per item in stdout: what it says, where the source is, what goes wrong if approved by mistake. Read from files only. Then ask again.\n'
  printf '3. **Dừng — tôi duyệt sau** → do nothing of the phase; remind them to run `%s` again after approving.\n\n' "$_cd_lenh"
  printf '"Duyệt hộ", "tick giúp", "ok cứ làm đi"… → **refuse** in one line (only the human may tick), point to the exact file and line, ask again. Wants to change content → that is `/aw-spec` (D-xx: `/aw-design`), do not edit here.\n\n'
}

# doc_truoc — mục "Đọc trước khi làm" chung
doc_truoc() {
  printf '**Read first:** `%s/rules/nguyen-tac-chung.md`' "$DOCS"
  if [ "${1:-}" = "true" ]; then printf ', `%s/rules/truy-vet-nguon.md`' "$DOCS"; fi
  printf '. Repo conventions (look up when needed): `%s`.\n\n' "$CONV_DOC"
}

# buoc_quy_tac_repo <phase> — đọc quy tắc riêng của repo. Danh sách lấy LÚC CHẠY
# bằng `aw rules`, không chép vào lúc build: conventions.md sửa là có hiệu lực ngay.
buoc_quy_tac_repo() {
  printf '**Repo-specific rules:** run `aw rules %s` — **ĐÃ LIỆT KÊ:** read every printed file before working (nothing printed = none) · **KHAI SAI:** stop, ask the human to fix `rules_*` in `%s`; never guess a replacement. Priority: `rules/nguyen-tac-chung.md` § 7.\n\n' "$1" "$CONV_DOC"
}

# luat_tom_tat — bảy luật không được vi phạm, dùng trong file tổng của agent
luat_tom_tat() {
  printf '1. **Hand off through files** — never take input from earlier chat.\n'
  printf '2. **Never declare a pass yourself** — run `aw check …`, paste the real result.\n'
  printf '3. **Never approve** — never tick "Approved by human" or edit `approval-hash`; editing ticked content → untick. LLM checkers only block.\n'
  printf '4. **Stay inside the phase** — record other phases'"'"' work, do not do it.\n'
  printf '5. **Never delete earlier artifacts** — rerun = update.\n'
  printf '6. **Every requirement traces to a source.**\n'
  printf '7. **Artifacts are for humans** — Vietnamese, clear structure, short sentences.\n\n'
  printf 'Full rules: `%s/rules/`.\n\n' "$DOCS"
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
  # Chuẩn định dạng của agent — dd_kiem (adapters/lib/dinh-dang.sh) kiểm mọi file theo nó.
  case "${AD_LENH_FM:-}" in co|khong) ;; *) echo "LỖI: adapter $AD_ID khai AD_LENH_FM \"${AD_LENH_FM:-}\" — chỉ nhận co|khong (xem adapters/lib/dinh-dang.sh)." >&2; exit 4 ;; esac
  [ -n "${AD_AGENT_KHOA:-}" ] && [ -n "${AD_SKILL_KHOA:-}" ] && { [ "$AD_LENH_FM" = khong ] || [ -n "${AD_LENH_KHOA:-}" ]; } ||
    { echo "LỖI: adapter $AD_ID thiếu AD_LENH_KHOA / AD_AGENT_KHOA / AD_SKILL_KHOA (xem adapters/lib/dinh-dang.sh)." >&2; exit 4; }
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

  printf '## Phase contract\n\n'
  if [ "$req" = "true" ]; then
    printf -- '- **Required:** yes\n'
  else
    printf -- '- **Required:** no — run only when %s\n' "${when:-the user asks}"
  fi

  printf -- '- **Reads:**\n'
  ins=$(fm_list "$src" inputs)
  if [ -z "$ins" ]; then
    printf -- '  - (no artifacts)\n'
  else
    echo "$ins" | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
  fi

  printf -- '- **Writes:**\n'
  fm_list "$src" outputs | while IFS= read -r o; do
    [ -n "$o" ] || continue
    mo_ta_output "$o"
    case "$o" in
      *.md) if [ -f "$ROOT/workflow/templates/$o" ]; then printf '    — template `%s/templates/%s` (read before writing)\n' "$DOCS" "$o"; fi ;;
    esac
  done

  if [ -n "$lc" ]; then
    lco=$(fm_scalar "$ROOT/$lc" output)
    printf -- '- **LLM checker (may only BLOCK, never APPROVE):** when done writing, call subagent `%s` (clean context) with `%s`; it writes `%s/%s`. File missing = KHÔNG ĐẠT.\n' \
      "$(ten_agent_checker "$lc")" "$FD" "$FD" "$lco"
  fi

  em=$(fm_list "$src" exit_machine)
  if [ -n "$em" ]; then
    printf -- '- **Exit — MACHINE** (run it, paste the real result, never declare a pass yourself):\n'
    echo "$em" | while IFS= read -r c; do [ -n "$c" ] && dich_lenh "$c"; done
  fi

  eh=$(fm_list "$src" exit_human)
  if [ -n "$eh" ]; then
    printf -- '- **Exit — HUMAN** (state it, then stop; never approve for them):\n'
    echo "$eh" | while IFS= read -r c; do [ -n "$c" ] && printf '  - %s\n' "$c"; done
  fi

  if [ "$clean" = "true" ]; then
    printf -- '- **Context:** must run from a blank session; input only from files.\n'
  fi
  if [ "$fresh" = "true" ]; then
    printf -- '- **Mandatory:** run through subagent `ra-soat-doc-lap`, passing `%s`. NEVER review in the session that wrote the code.\n' "$FD"
  fi

  printf '\n'
  if [ "$fresh" = "true" ]; then
    # Phiên chính chỉ bàn giao: mô tả phase đầy đủ nằm trong subagent, nạp ở đây là phí ngữ cảnh.
    _o=$(fm_list "$src" outputs | head -1); _c=$(fm_list "$src" exit_machine | head -1)
    printf '## What this session does\n\n'
    printf '1. Call subagent `ra-soat-doc-lap` with `%s`. It holds the full phase description, writes `%s`, runs `%s`. This session does **not** review and does not edit `%s`.\n' "$FD" "$_o" "$_c" "$_o"
    printf '2. When it finishes: give the human its verdict and the real `%s` result (in Vietnamese); state the HUMAN exit conditions above, then stop.\n' "$_c"
    printf '3. Cannot call subagents: tell the human to open a new session loading only the `ra-soat-doc-lap` subagent file + the feature dir.\n'
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
      _hk ad_dau_agent ra-soat-doc-lap 'Independent clean-context review of the diff against spec.md, tdd.md and plan.md. Used by the review phase; never the session that implemented. The caller must pass the feature dir.'
      canh_bao "$REV_FILE"
      printf 'You are an independent reviewer: you have NEVER seen this code or the reasoning behind it. Do not guess the author'"'"'s intent; only compare the code with the approved spec and design. Write `review.md` in Vietnamese.\n\n'
      printf 'The caller passes `%s` (e.g. `%s/feat_tao-todo`); missing → stop and ask.\n\n' "$FD" "$ART"
      printf 'Reads:\n'
      fm_list "$REV_SRC" inputs | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
      printf '\nWrite `%s/review.md` per template `%s/templates/review.md`, then run `aw check review %s` and paste the real result. `templates/`, `rules/` below live in `%s/`.\n\n' "$FD" "$DOCS" "$FD" "$DOCS"
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
      _hk ad_dau_agent "$ten" "$(fm_scalar "$csrc" summary) The caller must pass the feature dir."
      canh_bao "$lc"
      printf 'The caller passes `%s`; missing → stop and ask.\n\n' "$FD"
      printf 'Reads:\n'
      fm_list "$csrc" inputs | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
      printf '\nWrite `%s/%s` per template `%s/templates/%s`.\n\n' "$FD" "$(fm_scalar "$csrc" output)" "$DOCS" "$(fm_scalar "$csrc" output)"
      [ -n "$cqt" ] && buoc_quy_tac_repo "$cqt"
      printf -- '---\n'
      md_body "$csrc"
    } | ghi_file "$A/$ten.md"
  done

  # ---------- lệnh tiện ích (commands: trong manifest) ----------
  # Khong phai phase: khong co hop dong vao/ra, chi co buoc xac dinh feature + than.
  # arguments: (bo trong) = tham so la ten feature; mixed = con tham so khac, ten
  # feature (neu co) nam lan trong do — agent tach ra.
  # runs_on_main_checkout: true = co viec o checkout chinh (muc "On the main checkout"
  # trong than), nhu phase 06-ship.
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
    cmc=$(fm_scalar "$csrc" runs_on_main_checkout)
    case "$cmc" in
      ""|true) ;;
      *) echo "LỖI: $cfile khai runs_on_main_checkout \"$cmc\" — chỉ nhận \"true\" (bỏ trống = không)." >&2; exit 4 ;;
    esac
    kiem_tra_ghi_de "$L/$(ten_lenh "$cid").md"
    {
      _h=$(fm_scalar "$csrc" argument_hint); _h=${_h:-[tên-feature]}
      ts=$(_hk ad_tham_so)
      _hk ad_dau_lenh "$(ten_lenh "$cid")" "$(fm_scalar "$csrc" name)" "$(fm_scalar "$csrc" summary)" "$_h"
      canh_bao "$cfile"
      _hk ad_mo_dau_lenh "$(ten_lenh "$cid")" "$_h" "$cargs"
      if [ "$cargs" = "mixed" ]; then
        printf 'Arguments: `%s`\n\n' "$ts"
        buoc_xac_dinh_feature '<feature-name if the user gave one>' "" "$cmc"
      else
        buoc_xac_dinh_feature "$ts" "" "$cmc"
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
    _hk ad_dau_skill quy-trinh-agent 'This repo'"'"'s AI-agent development workflow. Use when starting new work, writing a spec from a BRD/PRD or Jira/Confluence ticket, technical design, planning, implementing a plan, reviewing changes, importing documents from other tools, settling open questions or LLM-checker findings that block a phase, making the repo answer a fresh agent session (AGENTS.md, Makefile, module docs, ADR), or when asked how this repo works.'
    printf '# AI-agent development workflow\n\n'
    canh_bao "workflow.yaml"
    printf 'Each phase takes **files** written by the previous one as input, never chat — it runs from a blank session, with any agent. Talk to the human in Vietnamese.\n\n'
    printf '## Phases\n\n'
    printf '| Command | Phase | Writes | Required |\n'
    printf '|---|---|---|---|\n'
    while IFS='|' read -r id file req when; do
      [ -n "$id" ] || continue
      src="$ROOT/$file"
      [ -f "$src" ] || continue
      [ "$(fm_scalar "$src" status)" = "chưa hiện thực" ] && continue
      nm=$(fm_scalar "$src" name)
      oo=$(fm_list "$src" outputs | tr '\n' ',' | sed 's/,$//; s/,/, /g')
      if [ "$req" = "true" ]; then bb="yes"; else bb="no"; fi
      printf '| `/%s` | %s | %s | %s |\n' "$(ten_lenh "$id")" "$nm" "${oo:-—}" "$bb"
    done < "$PH_LIST"
    if [ -s "$CMD_LIST" ]; then
      printf '\n## Utility commands (not phases)\n\n'
      while IFS='|' read -r cid cfile; do
        [ -n "$cid" ] || continue
        printf -- '- `/%s` — %s\n' "$(ten_lenh "$cid")" "$(fm_scalar "$ROOT/$cfile" summary)"
      done < "$CMD_LIST"
    fi
    printf '\n## Hard rules\n\n'
    luat_tom_tat
    printf '## Artifacts and commands\n\n'
    printf -- '- Job artifacts: `%s/<branch-name>/` (`aw feature`; outside git)\n' "$ART"
    printf -- '- Repo conventions: `%s`; per-phase repo rules: `aw rules <phase>` (%s)\n' "$CONV_DOC" "$BL_QUY_TAC"
    printf -- '- Engine rules, templates, LLM checkers: `%s/`\n' "$DOCS"
    printf -- '- Machine checkers: `aw check <name> %s` — names: %s\n' "$FD" "$BL_CHECKERS"
    printf -- '- Session start: `aw ready %s` (environment ready?, next step)\n' "$FD"
    printf -- '- Tasks: `aw task next|start|done %s [T-NN]` — never edit `Status` yourself\n' "$FD"
    printf -- '- Agent failure no checker caught: `aw journal add <task|context|env|verify|state|model> "<description>"`\n'
  } | ghi_file "$SK"

  # ---------- dọn file cũ ----------
  don_file_cu "$L"/*.md "$A"/*.md
}
