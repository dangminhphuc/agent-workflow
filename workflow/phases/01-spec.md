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

Turn business requirements into a **verifiable** spec, and expose where sources are unclear or contradict each other. **Never create requirements** — only translate and sharpen existing ones. Source-label rule: `rules/truy-vet-nguon.md`.

## Input

- `intake.md` — must pass `aw check intake`. Missing → stop, run `/aw-intake`.
- Every input listed in `intake.md`. Read nothing outside that list (to add a source, add it to `intake.md` first).
- `aw rules spec` — read every file it prints.
- `aw knowledge spec <thư-mục-feature>` — read every file it prints: the repo's **active business rules** (`### BR-…`). A source that contradicts an active rule → a row in `## Source conflicts` or an `[OPEN-QUESTION]`; never pick a side yourself.

| Input | How to read | Source label in spec |
|---|---|---|
| `[CONFLUENCE]` | MCP Atlassian | `[CONFLUENCE]` URL + heading |
| `[JIRA]` | MCP Atlassian | `[JIRA]` key + URL |
| `[FILE]` (incl. incident notes) | Read directly | `[FILE]` path + heading |
| `[HUMAN]` | Verbatim text in `intake.md` | `[FILE] intake.md § Input` |

## By work type

| Type | Spec must also have |
|---|---|
| `bugfix` | `## Reproduction`: `Steps to reproduce:`, `Actual behavior:`, `Expected behavior:` |
| `refactor` | Every YC has `Type: preserve \| structural`, **no new behaviour**. Preserve YCs have `Protected by: \`<test file>\`` — the file **already exists on the base branch** |
| `perf` | Like refactor + at least one `Type: performance` with a numeric `Target:` |

Refactoring an area with no protecting test → checker blocks. Write the tests as a separate job first, or narrow the scope.

## Steps

1. **Read every source fully.** Record exact identifiers and the **version** read (Confluence: page version; Jira: `updated`; `[FILE]`: commit sha) in `## Sources`. Do not skim and summarise.
2. **Quote requirement sentences verbatim** before interpreting — separate "what the source says" from "how we read it".
3. **Write verifiable YCs.** Each `YC-NNN`:
   - at least one `- [ ] …` **observable from outside** ("under 300ms with 10k records", not "must be fast");
   - `Priority: must | should` — `should` **only if the source says so** ("nice to have", "phase 2 if time"); source silent = `must`.
4. **Check NFRs.** For each group: does the work touch it, what does the source say?

   | Group | Questions |
   |---|---|
   | Authorisation | Who may view / edit / approve? Which roles are blocked? |
   | Audit | Must who/when/old value be recorded? |
   | Performance | How many records, concurrent users? |
   | Sensitive data | Personal or financial data? Masking, encryption, retention? |
   | Backward compatibility | Which external API / file / report uses what will change? |
   | Failure & recovery | External system fails → then what? Retry, rollback? |

   Source says → YC. Touched but source silent → `[OPEN-QUESTION]` (usually `review-blocking`). Not touched → skip. Never invent numbers.
5. **Context:** user roles per the source in `## Context`. Ambiguous domain terms ("kỳ", "hạch toán") → `## Glossary` (optional), each with its source.
6. **Label the source** of every YC.
7. **Split out open questions:** unclear in the source → `[OPEN-QUESTION]` + entry in `open-questions.md` with the temporary assumption, "if wrong, redo what", and a proposed `Blocking` (levels table in `rules/truy-vet-nguon.md`). Only `blocking` stops the flow now; the `clarify` command walks the human through answers.
8. **Check conflicts** between sources in `## Source conflicts`. The "Resolution" column may **only** point to an open question (`open-questions.md § YC-NNN`) or a settled source (PO's `[JIRA]` comment, newer `[CONFLUENCE]` page…). None → "Không phát hiện mâu thuẫn."
9. **`## Out of scope`:** list plainly what is *not* done — stops later phases overreaching. None → "Không có."
10. **`## Constraints & dependencies`:** external systems, legal/accounting rules, deadlines, other teams' work — with sources. None → "Không có ràng buộc hay phụ thuộc ngoài."
11. **Propose `Risk`:** `high` when touching money/accounting, new integrations, core schema, or hard-to-reverse changes; otherwise `normal`. One-line reason. `high` → design runs Mode 2.
   - A YC that stays true after this job (a business invariant, not a screen detail) with a durable source → propose `- Promote: BR-<MIỀN>-NNN` under it. The human decides by approving the spec; `[INFERRED]` / `[OPEN-QUESTION]` YCs cannot be promoted.
12. **Leave `- [ ] **Approved by human**` unticked.** Every content edit of the spec (rerun, `clarify` included) **unticks** it. Ticked + content changed → `aw check` blocks (the `aw guard` hook, if installed, unticks).
13. **Record inputs:** `aw based-on <thư-mục-feature> spec.md intake.md`.

## Output

- `spec.md` per `templates/spec.md`.
- `open-questions.md` per `templates/open-questions.md` — **always exists**; no open questions → write "No open questions" (empty file = reviewed; missing file = not reviewed).

## Forbidden

- Requirements that do not trace to a source.
- **Choosing a technical solution** (library, tables, modules) — that is `02-design`.
- Picking one reading of an ambiguity without an `[OPEN-QUESTION]`.
- `[INFERRED]` on a business decision; lowering `Risk`/`Blocking` to avoid blocks; `should` the source did not say.
- Resolving source conflicts yourself ("pick the safer side").
- **Ticking "Approved by human"**, editing/deleting the approval hash.
- Writing code, even illustrative.

## Exit conditions

**Machine:** `aw check spec` → `[x] ĐẠT` (checklist: `rules/truy-vet-nguon.md`).

**Human:**
- Reviews YCs and "Out of scope"; approves `Blocking` and `Risk`.
- Ticks "Approved by human". `02-design` (chore: `03-plan`) blocks until then. Spec edited after the tick → re-approve: read the change and delete `<!-- approval-hash: … -->` (keep the tick), or re-tick if it was removed.

Open questions still open: review may not mark that YC `pass`; `blocking`/`review-blocking` still open → review blocks.
