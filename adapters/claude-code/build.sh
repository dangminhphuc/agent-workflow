#!/usr/bin/env sh
# Adapter Claude Code — bien dich spec trung lap thanh artifact native.
#
#   aw adapter build claude-code [--out <thu-muc>] [--force]
#   (hoặc trực tiếp: sh adapters/claude-code/build.sh --out <thu-muc> [--force])
#
# Sinh ra trong repo dich:
#   .claude/commands/<id>.md            slash command cho tung phase
#   .claude/commands/<id>.md            lenh tien ich (commands: trong manifest) —
#                                       import, clarify
#   .claude/agents/ra-soat-doc-lap.md   subagent ra soat (ngu canh sach)
#   .claude/agents/soat-<checker>.md    subagent cho tung checker LLM
#   .claude/skills/quy-trinh-agent/SKILL.md
#
# Lop mong: chi dan agent goi `aw ...`; phan dung chung o adapters/lib/chung.sh.
# File sinh ra nam trong .claude/ — aw init them vao .git/info/exclude (xem file
# exclude canh build.sh), khong bao gio lot vao commit.
#
# KHONG tu ghi .claude/settings.json — xem README.md muc "Hook".
# Ghi de settings cua repo dich la thao tac khong dao nguoc duoc.

set -e
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/tools/lib/md.sh"
. "$ROOT/tools/lib/ket-qua.sh"
. "$ROOT/tools/lib/bang-lenh.sh"
kq_khai build.sh \
  "0=ĐÃ SINH" \
  "2=SAI THAM SỐ" \
  "3=CÓ FILE VIẾT TAY — không ghi đè; dời file đó đi hoặc dùng --force" \
  "4=ĐỊNH NGHĨA QUY TRÌNH LỖI — sửa workflow/ trong repo agent-workflow"

OUT=""
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --out)   OUT="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    *) echo "Tham so la: $1" >&2; exit 2 ;;
  esac
done
[ -n "$OUT" ] || { echo "Thieu --out <thu-muc-repo-dich>" >&2; exit 2; }
if [ -d "$OUT" ]; then
  case "$(CDPATH= cd -- "$OUT" && pwd)/" in
    "$ROOT"/*)
      echo "LỖI: --out nằm trong repo agent-workflow ($OUT)." >&2
      echo "      Sinh vào đây sẽ lẫn .claude/ vào mã nguồn; hãy trỏ tới repo đích." >&2
      exit 2 ;;
  esac
fi

# Danh sach file sinh ra LAN NAY — de don file do lan truoc sinh ra ma nay
# khong con trong manifest. Ghi ra file vi ghi_file chay trong subshell cua
# pipeline, bien shell khong song sot.
DA_SINH="${TMPDIR:-/tmp}/.aw_da_sinh.$$"
: > "$DA_SINH"
. "$ROOT/adapters/lib/chung.sh"

# Lenh khai choice_ui: true — "cau hoi lua chon" trong mo ta trung lap dich sang
# tool AskUserQuestion cua Claude Code. O "Other" cua tool la lua chon tu nhap.
cach_hoi_lua_chon() {
  printf '## Cách hỏi lựa chọn trong Claude Code\n\n'
  printf 'Mỗi "câu hỏi lựa chọn" trong mô tả bên dưới là **một lần gọi tool `AskUserQuestion`** — một câu hỏi mỗi lần, `multiSelect: false`. Không in lựa chọn thành văn bản rồi bắt người gõ chữ cái.\n\n'
  printf -- '- Ngữ cảnh ngắn (tài liệu nói gì, nếu sai, hỏi ai) viết thành văn bản **ngay trước** lần gọi, tối đa 4 dòng.\n'
  printf -- '- `question`: câu hỏi, một câu, kết thúc bằng dấu `?`.\n'
  printf -- '- `header` (≤ 12 ký tự): mã và vị trí, vd `YC-001 1/8`.\n'
  printf -- '- `options` (tối đa 4), theo thứ tự: giữ giả định tạm · cách hiểu khác (nếu nguồn có) · `Chưa trả lời được` · `Chat về câu này`. `description` của mỗi lựa chọn là hệ quả một dòng.\n'
  printf -- '- **Không** thêm lựa chọn "Khác": Claude Code luôn tự thêm ô "Other" — đó chính là lựa chọn tự nhập. Câu trả lời trả về là nhãn được chọn, hoặc nguyên văn người gõ vào "Other".\n'
  printf -- '- Chọn `Chat về câu này` thì trả lời bằng văn bản thường; khi người đã rõ, gọi lại `AskUserQuestion` cho đúng câu đó.\n\n'
}

ten_agent_checker() { printf 'soat-%s' "$(basename "$1" .md)"; }

sinh_command() {
  id="$1"; file="$2"; req="$3"; when="$4"
  src="$ROOT/$file"
  name=$(fm_scalar "$src" name)
  summary=$(fm_scalar "$src" summary)
  clean=$(fm_scalar "$src" needs_clean_context)
  fresh=$(fm_scalar "$src" requires_fresh_agent)
  lc=$(fm_scalar "$src" llm_checker)
  args=$(fm_scalar "$src" arguments)

  printf -- '---\n'
  printf 'description: %s — %s\n' "$name" "$summary"
  if [ "$args" = "input" ]; then
    printf 'argument-hint: [mã-issue | URL | đường-dẫn …]\n'
  else
    printf 'argument-hint: [tên-feature]\n'
  fi
  printf -- '---\n\n'
  canh_bao "$file"
  buoc_xac_dinh_feature '$ARGUMENTS' "$args"
  [ "$args" = "input" ] && buoc_phan_loai_input '$ARGUMENTS'

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
  printf -- '---\n'
  md_body "$src"
}

# ---------- slash command cho tung phase ----------
PH_LIST="${TMPDIR:-/tmp}/.wf_phases.$$"
kq_don 'rm -f "$PH_LIST" "$DA_SINH"'
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
  kiem_tra_ghi_de "$OUT/.claude/commands/$id.md"
  sinh_command "$id" "$file" "$req" "$when" | ghi_file "$OUT/.claude/commands/$id.md"
  if [ "$(fm_scalar "$src" requires_fresh_agent)" = "true" ]; then REV_SRC="$src"; REV_FILE="$file"; fi
  lc=$(fm_scalar "$src" llm_checker)
  [ -n "$lc" ] && CHECKERS="$CHECKERS $lc"
done < "$PH_LIST"

# ---------- subagent ra soat (phase co requires_fresh_agent) ----------
if [ -n "$REV_SRC" ]; then
  kiem_tra_ghi_de "$OUT/.claude/agents/ra-soat-doc-lap.md"
  {
    printf -- '---\n'
    printf 'name: ra-soat-doc-lap\n'
    printf 'description: Rà soát độc lập diff theo spec.md, tdd.md và plan.md bằng ngữ cảnh sạch. Dùng cho phase review. Không dùng chính phiên vừa hiện thực để rà soát. Người gọi phải truyền thư mục feature.\n'
    printf -- '---\n\n'
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
    printf -- '---\n'
    md_body "$REV_SRC"
  } | ghi_file "$OUT/.claude/agents/ra-soat-doc-lap.md"
fi

# ---------- subagent cho tung checker LLM ----------
for lc in $CHECKERS; do
  csrc="$ROOT/$lc"; ten=$(ten_agent_checker "$lc")
  kiem_tra_ghi_de "$OUT/.claude/agents/$ten.md"
  {
    printf -- '---\n'
    printf 'name: %s\n' "$ten"
    printf 'description: %s Người gọi phải truyền thư mục feature.\n' "$(fm_scalar "$csrc" summary)"
    printf -- '---\n\n'
    canh_bao "$lc"
    printf 'Người gọi truyền cho bạn `%s`. Không có thì dừng lại hỏi.\n\n' "$FD"
    printf 'Đọc vào:\n'
    fm_list "$csrc" inputs | while IFS= read -r i; do [ -n "$i" ] && mo_ta_input "$i"; done
    printf '\nGhi ra `%s/%s` theo mẫu `%s/templates/%s`.\n\n' "$FD" "$(fm_scalar "$csrc" output)" "$DOCS" "$(fm_scalar "$csrc" output)"
    printf -- '---\n'
    md_body "$csrc"
  } | ghi_file "$OUT/.claude/agents/$ten.md"
done

# ---------- lenh tien ich (commands: trong manifest) ----------
# Khong phai phase: khong co hop dong vao/ra, chi co buoc xac dinh feature + than.
# arguments: (bo trong) = tham so la ten feature; mixed = con tham so khac, ten
# feature (neu co) nam lan trong do — agent tach ra.
CMD_LIST="${TMPDIR:-/tmp}/.wf_cmds.$$"
kq_don 'rm -f "$PH_LIST" "$DA_SINH" "$CMD_LIST"'
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
  kiem_tra_ghi_de "$OUT/.claude/commands/$cid.md"
  {
    printf -- '---\n'
    printf 'description: %s — %s\n' "$(fm_scalar "$csrc" name)" "$(fm_scalar "$csrc" summary)"
    _h=$(fm_scalar "$csrc" argument_hint)
    printf 'argument-hint: %s\n' "${_h:-[tên-feature]}"
    printf -- '---\n\n'
    canh_bao "$cfile"
    if [ "$cargs" = "mixed" ]; then
      printf 'Tham số: `$ARGUMENTS`\n\n'
      buoc_xac_dinh_feature '<tên-feature nếu người dùng truyền>'
    else
      buoc_xac_dinh_feature '$ARGUMENTS'
    fi
    [ "$(fm_scalar "$csrc" choice_ui)" = "true" ] && cach_hoi_lua_chon
    doc_truoc
    printf -- '---\n'
    md_body "$csrc"
  } | ghi_file "$OUT/.claude/commands/$cid.md"
done < "$CMD_LIST"

# ---------- skill tong ----------
kiem_tra_ghi_de "$OUT/.claude/skills/quy-trinh-agent/SKILL.md"
{
  printf -- '---\n'
  printf 'name: quy-trinh-agent\n'
  printf 'description: Quy trình phát triển dựa trên AI agent của repo này. Dùng khi bắt đầu một tính năng mới, khi viết đặc tả từ BRD/PRD hoặc ticket Jira/Confluence, khi thiết kế kỹ thuật, khi lập kế hoạch, khi hiện thực theo kế hoạch, khi rà soát thay đổi, khi đưa tài liệu từ tool khác vào quy trình, khi cần chốt điểm mù (open questions) hoặc phân xử phát hiện của checker LLM đang chặn phase, hoặc khi được hỏi quy trình làm việc của repo này là gì.\n'
  printf -- '---\n\n'
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
  printf -- '- Luật, mẫu, checker LLM của engine: `%s/`\n' "$DOCS"
  printf -- '- Checker máy: `aw check <tên> %s` — tên: %s\n' "$FD" "$BL_CHECKERS"
} | ghi_file "$OUT/.claude/skills/quy-trinh-agent/SKILL.md"

# ---------- don file cu ----------
don_file_cu "$OUT"/.claude/commands/*.md "$OUT"/.claude/agents/*.md
