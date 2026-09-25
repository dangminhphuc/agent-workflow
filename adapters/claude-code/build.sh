#!/usr/bin/env sh
# Adapter Claude Code — bien dich spec trung lap thanh artifact native.
#
#   sh adapters/claude-code/build.sh --out <thu-muc-repo-dich>
#
# Sinh ra trong repo dich:
#   .claude/commands/<id>.md            slash command cho tung phase
#   .claude/agents/ra-soat-doc-lap.md   subagent ra soat (ngu canh sach)
#   .claude/skills/quy-trinh-agent/SKILL.md
#
# KHONG tu ghi .claude/settings.json — xem README.md muc "Hook".
# Ghi de settings cua repo dich la thao tac khong dao nguoc duoc.

set -e
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/tools/lib/md.sh"

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

# Khong ghi de file do NGUOI viet. File do adapter sinh ra deu mang dau
# "SINH TU DONG"; file dich khong co dau do nghia la co nguoi da viet tay.
kiem_tra_ghi_de() {
  [ -f "$1" ] || return 0
  [ "$FORCE" = "1" ] && return 0
  if grep -q 'SINH TỰ ĐỘNG' "$1" 2>/dev/null; then return 0; fi
  echo "LỖI: $1 đã tồn tại và không phải file do adapter sinh ra." >&2
  echo "      Adapter sẽ không ghi đè công sức viết tay. Di chuyển file đó đi," >&2
  echo "      hoặc chạy lại với --force nếu chắc chắn muốn mất nội dung cũ." >&2
  exit 3
}

MANIFEST="$ROOT/workflow.yaml"
ART=$(awk '/^artifact_dir:/ { sub(/^artifact_dir:[ \t]*/, ""); print; exit }' "$MANIFEST")
QT="$ART/.quy-trinh"

mkdir -p "$OUT/.claude/commands" "$OUT/.claude/agents" "$OUT/.claude/skills/quy-trinh-agent"

canh_bao() {
  printf '> **File này được SINH TỰ ĐỘNG** từ `%s` trong repo agent-workflow.\n' "$1"
  printf '> Đừng sửa trực tiếp — sửa file nguồn rồi chạy lại adapter, nếu không thay đổi sẽ mất.\n\n'
}

# Kiem tra exit_machine TRUOC khi sinh file, va o SHELL CHINH.
#
# Dieu kien ra loai MAY phai la LENH CHAY DUOC. Neu no chi la cau chu thi no
# la dieu kien loai NGUOI dang doi lot — agent se "tu danh gia la dat", dung
# cai ma nguyen-tac-chung.md cam.
#
# Luu y ky thuat: khong dat kiem tra nay ben trong `... | while read`, vi
# pipeline chay trong subshell — `exit` o do chi thoat subshell, build van
# tiep tuc va van ghi ra file thieu mat muc dieu kien ra. Doc tu file bang
# redirect thi van o shell chinh.
kiem_tra_exit_machine() {
  _src="$1"; _file="$2"
  _tmp="${TMPDIR:-/tmp}/em.$$"
  fm_list "$_src" exit_machine > "$_tmp"
  _bad=0
  while IFS= read -r _c; do
    [ -n "$_c" ] || continue
    case "$_c" in
      "sh tools/"*)
        _s=${_c#sh tools/}
        if [ ! -f "$ROOT/tools/$_s" ]; then
          echo "LỖI: $_file khai exit_machine \"$_c\" nhưng không có tools/$_s" >&2
          _bad=1
        fi ;;
      *)
        echo "LỖI: $_file khai exit_machine \"$_c\" — đây không phải lệnh chạy được." >&2
        echo "      Điều kiện ra loại MÁY phải là lệnh trả mã thoát 0/1." >&2
        echo "      Nếu chỉ người kiểm được thì chuyển xuống exit_human." >&2
        _bad=1 ;;
    esac
  done < "$_tmp"
  rm -f "$_tmp"
  [ "$_bad" = "0" ]
}

# Chi dinh dang — moi kiem tra da lam o kiem_tra_exit_machine.
dich_lenh() {
  _s=${1#sh tools/}
  printf '  - `sh %s/tools/%s %s` → phải trả mã thoát 0\n' "$QT" "$_s" "$ART"
}

mo_ta_input() {
  case "$1" in
    confluence) printf '  - Confluence qua MCP Atlassian — ghi lại URL page + tên heading\n' ;;
    jira)       printf '  - Jira qua MCP Atlassian — ghi lại mã issue + URL\n' ;;
    file)       printf '  - Tài liệu trong repo — ghi lại đường dẫn + heading\n' ;;
    brief)      printf '  - `%s/brief.md` (nếu đã chạy `/ideation`)\n' "$ART" ;;
    diff)       printf '  - Diff hiện tại của repo (`git diff`, `git status`)\n' ;;
    *.md)       printf '  - `%s/%s`\n' "$ART" "$1" ;;
    *)          printf '  - %s\n' "$1" ;;
  esac
}

mo_ta_output() {
  case "$1" in
    diff) printf '  - Thay đổi code trong repo\n' ;;
    *)    printf '  - `%s/%s`\n' "$ART" "$1" ;;
  esac
}

sinh_command() {
  id="$1"; file="$2"; req="$3"; when="$4"
  src="$ROOT/$file"
  name=$(fm_scalar "$src" name)
  summary=$(fm_scalar "$src" summary)
  clean=$(fm_scalar "$src" needs_clean_context)
  fresh=$(fm_scalar "$src" requires_fresh_agent)

  printf -- '---\n'
  printf 'description: %s — %s\n' "$name" "$summary"
  printf -- '---\n\n'
  canh_bao "$file"

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
          printf -- '- **Mẫu cho `%s`:** `%s/templates/%s` — đọc mẫu trước khi viết\n' "$o" "$QT" "$o"
        fi ;;
    esac
  done

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
    printf -- '- **Bắt buộc:** chạy qua subagent `ra-soat-doc-lap`. KHÔNG rà soát bằng chính phiên vừa viết code.\n'
  fi

  printf '\n### Đọc trước khi làm\n\n'
  printf -- '- `%s/rules/nguyen-tac-chung.md`\n' "$QT"
  printf -- '- `%s/rules/truy-vet-nguon.md`\n\n' "$QT"
  printf -- '---\n'
  md_body "$src"
}

# ---------- slash command ----------
wf_phases "$MANIFEST" > /tmp/.wf_phases.$$
while IFS='|' read -r id file req when; do
  [ -n "$id" ] || continue
  src="$ROOT/$file"
  if [ ! -f "$src" ]; then
    echo "  CẢNH BÁO: bỏ qua /$id — không tìm thấy $file" >&2
    continue
  fi
  if [ "$(fm_scalar "$src" status)" = "chưa hiện thực" ]; then
    echo "  bỏ qua  /$id (status: chưa hiện thực)"
    continue
  fi
  kiem_tra_exit_machine "$src" "$file" || exit 4
  kiem_tra_ghi_de "$OUT/.claude/commands/$id.md"
  # Ghi ra file tam roi moi chuyen vao cho: build that bai giua chung khong duoc
  # de lai mot command file viet do — no trong nhu hop le nhung bi cut.
  tmpf="$OUT/.claude/commands/.$id.md.tmp"
  if sinh_command "$id" "$file" "$req" "$when" > "$tmpf"; then
    mv "$tmpf" "$OUT/.claude/commands/$id.md"
    echo "  sinh    .claude/commands/$id.md"
  else
    rm -f "$tmpf"
    exit 4
  fi
done < /tmp/.wf_phases.$$

# ---------- subagent ra soat ----------
REV="$ROOT/workflow/phases/04-review.md"
kiem_tra_ghi_de "$OUT/.claude/agents/ra-soat-doc-lap.md"
{
  printf -- '---\n'
  printf 'name: ra-soat-doc-lap\n'
  printf 'description: Rà soát độc lập diff theo spec.md và plan.md bằng ngữ cảnh sạch. Dùng cho phase 04-review. Không dùng chính phiên vừa hiện thực để rà soát.\n'
  printf -- '---\n\n'
  canh_bao "workflow/phases/04-review.md"
  printf 'Bạn là người rà soát độc lập. Bạn CHƯA từng nhìn thấy code này và không biết\n'
  printf 'gì về lập luận đã dẫn tới nó — đó chính là giá trị của bạn. Đừng suy đoán ý\n'
  printf 'định của người viết; chỉ đối chiếu code với đặc tả.\n\n'
  printf 'Đọc vào:\n'
  printf -- '- `%s/spec.md`\n' "$ART"
  printf -- '- `%s/plan.md`\n' "$ART"
  printf -- '- Diff hiện tại (`git diff`)\n\n'
  printf 'Ghi ra `%s/review.md` theo mẫu `%s/templates/review.md`.\n\n' "$ART" "$QT"
  printf -- '---\n'
  md_body "$REV"
} > "$OUT/.claude/agents/ra-soat-doc-lap.md"
echo "  sinh    .claude/agents/ra-soat-doc-lap.md"

# ---------- skill tong ----------
kiem_tra_ghi_de "$OUT/.claude/skills/quy-trinh-agent/SKILL.md"
{
  printf -- '---\n'
  printf 'name: quy-trinh-agent\n'
  printf 'description: Quy trình phát triển dựa trên AI agent của repo này. Dùng khi bắt đầu một tính năng mới, khi viết đặc tả từ BRD/PRD hoặc ticket Jira/Confluence, khi lập kế hoạch kỹ thuật, khi hiện thực theo kế hoạch, khi rà soát thay đổi, hoặc khi được hỏi quy trình làm việc của repo này là gì.\n'
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
  done < /tmp/.wf_phases.$$
  printf '\n## Luật không được vi phạm\n\n'
  printf '1. **Bàn giao bằng file.** Phase không được nhận đầu vào từ hội thoại phía trên.\n'
  printf '2. **Không tự tuyên bố đạt** với điều kiện ra loại MÁY — phải chạy lệnh và dán kết quả thật.\n'
  printf '3. **Không vượt phạm vi phase.** Việc thuộc phase khác thì ghi lại, không làm luôn.\n'
  printf '4. **Không xoá artifact của phase trước.** Chạy lại là cập nhật, không viết đè trắng.\n'
  printf '5. **Mọi yêu cầu phải truy được về nguồn.**\n\n'
  printf 'Bản đầy đủ: `%s/rules/nguyen-tac-chung.md` và `%s/rules/truy-vet-nguon.md`.\n\n' "$QT" "$QT"
  printf '## Artifact\n\n'
  printf -- '- Artifact bàn giao: `%s/`\n' "$ART"
  printf -- '- Bộ cài của quy trình (luật, mẫu, công cụ kiểm tra): `%s/`\n' "$QT"
} > "$OUT/.claude/skills/quy-trinh-agent/SKILL.md"
echo "  sinh    .claude/skills/quy-trinh-agent/SKILL.md"

rm -f /tmp/.wf_phases.$$
