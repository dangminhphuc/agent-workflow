---
id: spec
name: Viết đặc tả
summary: Bước 2/6 · Biến BRD/PRD/ticket thành spec.md kiểm chứng được và liệt kê `open question` cần người chốt
required: true
inputs:
  - intake.md
  - confluence
  - jira
  - file
outputs:
  - spec.md
  - open-questions.md
  - spec-findings.md
implements: require
provides:
  - requirements: spec.md
  - open-questions: open-questions.md
capabilities:
  - CAP-require-01
  - CAP-require-02
  - CAP-require-03
exit_machine:
  - aw check spec
exit_human:
  - Repo owner reviews the requirement list and "Out of scope"
  - Repo owner approves the "Blocking" level of every [OPEN-QUESTION] (blocking | review-blocking | non-blocking)
  - Repo owner approves "Risk" (high → design runs Mode 2, the human drafts DEC-xxx first)
  - Repo owner approves "Design" (skip → no design phase, plan works from the spec)
  - Then the repo owner ticks "Approved by human" — design (no design phase: plan) blocks until then
  - The human arbitrates the LLM checker's findings (confirm, or reject with a reason)
needs_clean_context: true
llm_checker: workflow/checkers/spec.md
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
| `[ISSUE]` | `gh issue view` / `gh pr view` (GitHub), `glab issue view` / `glab mr view` (GitLab) with comments, or MCP | `[ISSUE]` URL (+ comment link) |
| `[FILE]` (incl. incident notes) | Read directly | `[FILE]` path + heading |
| `[HUMAN]` | Verbatim text in `intake.md` | `[FILE] [intake.md § Input](intake.md#input)` |

## Steps

**Shape first, one pass.** Before writing, read `templates/spec.md`, `templates/open-questions.md`, `templates/spec-findings.md` and start every artifact by copying that template's skeleton — never from memory, never retyping a field name. Write the artifacts first and run `aw toc <dir>` **once**, at the end (`rules/general.md` §6) — not after each file.

1. **Read every source fully.** Record exact identifiers and the **version** read (Confluence page version, Jira or `[ISSUE]` `updated`, `[FILE]` commit sha) in `## Sources`.
2. **Active business rules:** `aw knowledge spec <dir>` — `aw knowledge show` every ref it prints (`<file>#BR-…`). A source contradicting an active rule → a `## Source conflicts` row or an `[OPEN-QUESTION]`; never pick a side.
3. **Quote requirement sentences verbatim** into each REQ's `Quote:` before interpreting — separate "what the source says" (`Quote`) from "how we read it" (`Description`). Copy character for character; never paraphrase or add quotation marks.
4. **Write verifiable REQs.** Each `REQ-NNN` has exactly one `Source:` label (`rules/source-tracing.md`), at least one `- [ ] …` **observable from outside** ("under 300ms with 10k records", not "must be fast"), and `Priority: must | should` — `should` **only if the source says so** ("nice to have", "phase 2 if time"); source silent = `must`.
5. **Check NFRs.** For each group: does the work touch it, what does the source say?

   | Group | Questions |
   |---|---|
   | Authorisation | Who may view / edit / approve? Which roles are blocked? |
   | Audit | Must who/when/old value be recorded? |
   | Performance | How many records, concurrent users? |
   | Sensitive data | Personal or financial data? Masking, encryption, retention? |
   | Backward compatibility | Which external API / file / report uses what will change? |
   | Failure & recovery | External system fails → then what? Retry, rollback? |

   Source says → REQ. Touched but source silent → `[OPEN-QUESTION]` (usually `review-blocking`). Not touched → skip. Never invent numbers.
6. **`## Context`:** user roles per the source. Ambiguous domain terms ("kỳ", "hạch toán") → `## Glossary` (optional), each with its source.
7. **Open questions:** unclear in the source → an entry `### Q-NNN — <short question>` in `open-questions.md` (own numbering, not the REQ number) with the temporary assumption, "if wrong, redo what" and a proposed `Blocking`; each REQ standing on it gets `Source: [OPEN-QUESTION] → [open-questions.md § Q-NNN](open-questions.md#q-nnn)`. One question may cover several REQs; a REQ stands on at most one question. Two independent unknowns (different `Ask` or `Blocking`) → split the REQ; never merge them into one question. The assumption lives only in the question — never copy it into the REQ. `open-questions.md` **always exists**; none → "No open questions" (missing file = not reviewed).
8. **`## Source conflicts`:** "Resolution" may **only** point to an open question (`[open-questions.md § Q-NNN](open-questions.md#q-nnn)`) or a settled source (PO's `[JIRA]` or `[ISSUE]` comment, newer `[CONFLUENCE]` page…). None → "Không phát hiện mâu thuẫn."
9. **`## Out of scope`:** what is *not* done — stops later phases overreaching. None → "Không có."
10. **`## Constraints & dependencies`:** external systems, legal/accounting rules, deadlines, other teams' work — with sources. None → "Không có ràng buộc hay phụ thuộc ngoài."
11. **Propose `Risk`:** `high` when touching money/accounting, new integrations, core schema, or hard-to-reverse changes; else `normal`. One-line reason. `high` → design runs Mode 2.
    - **Propose `Design`:** `skip` only for a small `bugfix`/`refactor` with `Risk: normal` and no technical choice (no new API/schema/module boundary, one obvious way to do it); else `required`. `chore`: omit the line.
    - A REQ that stays true after this job (a business invariant, not a screen detail) with a durable source → propose `- Promote: BR-<DOMAIN>-NNN` under it. `[INFERRED]` / `[OPEN-QUESTION]` REQs cannot be promoted.
12. **Leave `- [ ] **Approved by human**` unticked**; any content edit unticks it. Spec edited after the human ticked → the human re-approves: reads the change and deletes `<!-- approval-hash: … -->` (keeps the tick), or re-ticks.
    - The human disagrees with an existing REQ → `/aw-clarify REQ-NNN` records the change as an answered open question; do not silently rewrite the REQ.
13. **Run the LLM checker** → `spec-findings.md`. It compares description and acceptance criteria to `Quote` and `[HUMAN]` text only. Fix what you agree with (`Resolution: fixed`); the human arbitrates the rest via `/aw-clarify` before ticking.
14. **`aw toc <dir>`** — the one run of this phase, now that all three artifacts exist; fix every `[LỖI]` it prints, then **`aw check spec`**.
15. **Record inputs:** `aw based-on <dir> spec.md intake.md`.

## By work type

| Type | Spec must also have |
|---|---|
| `bugfix` | `## Reproduction`: `Steps to reproduce:`, `Actual behavior:`, `Expected behavior:` |
| `refactor` | Every REQ has `Type: preserve \| structural`, **no new behaviour**. Preserve REQs have `Protected by: \`<test file>\`` — the file **already exists on the base branch** |
| `perf` | Like refactor + at least one `Type: performance` with a numeric `Target:` |

Refactoring an area with no protecting test → checker blocks. Write the tests as a separate job first, or narrow the scope.

## Forbidden

- Treating "LLM checker reported nothing" as a pass when it has not run.
- Requirements that do not trace to a source.
- **Choosing a technical solution** (library, tables, modules) — that is `02-design`.
- Picking one reading of an ambiguity without an `[OPEN-QUESTION]`; resolving source conflicts yourself ("pick the safer side").
- `[INFERRED]` on a business decision; lowering `Risk`/`Blocking` to avoid blocks; `should` the source did not say.
- **Ticking "Approved by human"**, editing/deleting the approval hash.
- Writing code, even illustrative.
