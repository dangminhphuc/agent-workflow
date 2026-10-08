---
id: import
name: Nhập artifact ngoài
summary: Đưa spec/tdd/plan viết bằng tool khác vào quy trình: chỉ sắp lại theo mẫu, không thêm nội dung
arguments: mixed
argument_hint: <file-nguồn> <spec.md|tdd.md|plan.md> [tên-feature]
trace_rule: true
---

# Import an external artifact

**Not a phase.** Bring a document made with another tool (other AI, Confluence, by hand…) into the middle of the workflow — **only rearrange it to the template**, add no content.

## Arguments

Source file (or Confluence/Jira URL) and target artifact (`spec.md` | `tdd.md` | `plan.md`). Either missing → stop and ask.

## Steps

1. Read the whole source; record its exact identifier (path / URL).
2. Read `templates/<target>` and the exit conditions of the phase that produces it.
3. Rearrange the source into the template:
   - every item carries a source label pointing to the original (`[FILE] <path> § <heading>`, `[CONFLUENCE] <URL> § <heading>`…);
   - something the template requires but the source lacks → **do not fill it**: in `spec.md` write `[OPEN-QUESTION]` + an `open-questions.md` entry; elsewhere in `tdd.md`/`plan.md` write `<THIẾU TRONG NGUỒN: …>` so the checker blocks;
   - D-xx from a human-written document: `Author: human`, box unticked.
4. Run the checker of the producing phase (`aw check spec` / `design` / `plan`), report the real result.
5. Stop for the **human to confirm the conversion** — then the phase's normal human gate applies.

## Forbidden

- **Adding content** not in the source, even "obvious" content.
- Ticking D-xx or spec boxes, even if the source says approved — approval in another tool is not approval here.
- Skipping the checker because "it was approved elsewhere".
