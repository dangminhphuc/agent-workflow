---
id: spec
name: Viết đặc tả
summary: Bước 2/6 · Biến BRD/PRD/ticket thành spec.md kiểm chứng được và liệt kê điểm mù cần người chốt
required: true
inputs:
  - intake.md
  - confluence
  - jira
  - file
outputs:
  - spec.md
  - open-questions.md
exit_machine:
  - aw check spec
exit_human:
  - Repo owner reviews the requirement list and "Out of scope"
  - Repo owner approves the "Blocking" level of every [OPEN-QUESTION] (blocking | review-blocking | non-blocking)
  - Repo owner approves "Risk" (high → design runs Mode 2, the human drafts D-xx first)
  - Then the repo owner ticks "Approved by human" — design (chore: plan) blocks until then
needs_clean_context: true
trace_rule: true
---

# Phase 01 — Spec

## Goal

Turn business requirements into a **verifiable** spec, and expose where sources are unclear or contradict each other. **Never create requirements** — only translate and sharpen existing ones.

Read **only** the inputs listed in `intake.md` (to add a source, add it there first). `intake.md` must pass `aw check intake`; missing → `/aw-intake`.

| Input | How to read | `Source:` label |
|---|---|---|
| `[CONFLUENCE]` | MCP Atlassian | `[CONFLUENCE]` URL + heading |
| `[JIRA]` | MCP Atlassian | `[JIRA]` key + URL |
| `[FILE]` (incl. incident notes) | Read directly | `[FILE]` path + heading |
| `[HUMAN]` | Verbatim text in `intake.md` | `[FILE] intake.md § Input` |

## Steps

1. **Read every source fully.** Record exact identifiers and the **version** read (Confluence page version, Jira `updated`, `[FILE]` commit sha) in `## Sources`.
2. **Active business rules:** `aw knowledge spec <dir>` — read every file it prints (`### BR-…`). A source contradicting an active rule → a `## Source conflicts` row or an `[OPEN-QUESTION]`; never pick a side.
3. **Quote requirement sentences verbatim** before interpreting — separate "what the source says" from "how we read it".
4. **Write verifiable YCs.** Each `YC-NNN` has exactly one `Source:` label (`rules/source-tracing.md`), at least one `- [ ] …` **observable from outside** ("under 300ms with 10k records", not "must be fast"), and `Priority: must | should` — `should` **only if the source says so** ("nice to have", "phase 2 if time"); source silent = `must`.
5. **Check NFRs.** For each group: does the work touch it, what does the source say?

   | Group | Questions |
   |---|---|
   | Authorisation | Who may view / edit / approve? Which roles are blocked? |
   | Audit | Must who/when/old value be recorded? |
   | Performance | How many records, concurrent users? |
   | Sensitive data | Personal or financial data? Masking, encryption, retention? |
   | Backward compatibility | Which external API / file / report uses what will change? |
   | Failure & recovery | External system fails → then what? Retry, rollback? |

   Source says → YC. Touched but source silent → `[OPEN-QUESTION]` (usually `review-blocking`). Not touched → skip. Never invent numbers.
6. **`## Context`:** user roles per the source. Ambiguous domain terms ("kỳ", "hạch toán") → `## Glossary` (optional), each with its source.
7. **Open questions:** unclear in the source → `[OPEN-QUESTION]` + an entry in `open-questions.md` with the temporary assumption, "if wrong, redo what" and a proposed `Blocking`. `open-questions.md` **always exists**; none → "No open questions" (missing file = not reviewed).
8. **`## Source conflicts`:** "Resolution" may **only** point to an open question (`open-questions.md § YC-NNN`) or a settled source (PO's `[JIRA]` comment, newer `[CONFLUENCE]` page…). None → "Không phát hiện mâu thuẫn."
9. **`## Out of scope`:** what is *not* done — stops later phases overreaching. None → "Không có."
10. **`## Constraints & dependencies`:** external systems, legal/accounting rules, deadlines, other teams' work — with sources. None → "Không có ràng buộc hay phụ thuộc ngoài."
11. **Propose `Risk`:** `high` when touching money/accounting, new integrations, core schema, or hard-to-reverse changes; else `normal`. One-line reason. `high` → design runs Mode 2.
    - A YC that stays true after this job (a business invariant, not a screen detail) with a durable source → propose `- Promote: BR-<DOMAIN>-NNN` under it. `[INFERRED]` / `[OPEN-QUESTION]` YCs cannot be promoted.
12. **Leave `- [ ] **Approved by human**` unticked**; any content edit unticks it. Spec edited after the human ticked → the human re-approves: reads the change and deletes `<!-- approval-hash: … -->` (keeps the tick), or re-ticks.
    - The human disagrees with an existing YC → `/aw-clarify YC-NNN` records the change as an answered open question; do not silently rewrite the YC.
13. **Record inputs:** `aw based-on <dir> spec.md intake.md`.

## By work type

| Type | Spec must also have |
|---|---|
| `bugfix` | `## Reproduction`: `Steps to reproduce:`, `Actual behavior:`, `Expected behavior:` |
| `refactor` | Every YC has `Type: preserve \| structural`, **no new behaviour**. Preserve YCs have `Protected by: \`<test file>\`` — the file **already exists on the base branch** |
| `perf` | Like refactor + at least one `Type: performance` with a numeric `Target:` |

Refactoring an area with no protecting test → checker blocks. Write the tests as a separate job first, or narrow the scope.

## Forbidden

- Requirements that do not trace to a source.
- **Choosing a technical solution** (library, tables, modules) — that is `02-design`.
- Picking one reading of an ambiguity without an `[OPEN-QUESTION]`; resolving source conflicts yourself ("pick the safer side").
- `[INFERRED]` on a business decision; lowering `Risk`/`Blocking` to avoid blocks; `should` the source did not say.
- **Ticking "Approved by human"**, editing/deleting the approval hash.
- Writing code, even illustrative.
