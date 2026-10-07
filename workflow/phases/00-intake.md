---
id: intake
name: Tiếp nhận việc
summary: Bước 1/6 · Bắt đầu việc mới từ ticket, URL hoặc file: chốt loại việc, tạo worktree, ghi intake.md
required: true
inputs:
  - confluence
  - jira
  - file
outputs:
  - intake.md
exit_machine:
  - aw check intake
exit_human:
  - The HUMAN CHOOSES THE BASE for the worktree (the agent only relays the aw worktree new proposal)
  - The human confirms the WORK TYPE (wrong type = wrong rules for every later phase)
  - The human confirms the input list, and that their own words were copied verbatim
needs_clean_context: true
arguments: input
---

# Phase 00 — Intake

## Goal

Answer exactly three questions in `intake.md`:
1. **Work type** — `feature`, `bugfix`, `refactor`, `perf` or `chore`. It changes the rules of later phases.
2. **Input** — documents with identifiers, or the user's own words. Every later `YC-xxx` traces back here.
3. **Goal** in one sentence.

## Work type

Classify by **what changes in behaviour**:

```
Does it change code that runs in production?
├─ No → chore
└─ Yes → Does externally observable behaviour change?
        ├─ No → faster / fewer resources? → yes: perf / no: refactor
        └─ Yes → Is the current behaviour WRONG vs docs / intent?
                ├─ Yes → bugfix
                └─ No  → feature
```

| Type | Extra rules |
|---|---|
| `feature` | Standard flow |
| `bugfix` | Spec has "Reproduction"; repro test must be **red on unfixed code** (`aw check repro`) |
| `refactor` | YCs only `preserve`/`structural`; preserve YCs have a protecting test already on the base branch; never delete old tests, declare edited ones |
| `perf` | Like refactor + `performance` YC with numbers, before/after measured by the machine (`aw check perf`) |
| `chore` | No design phase; no production code; declare dependency bumps (major = refactor) |

- Not separate types: `utils` (new shared helper = feature, dedupe = refactor), `hotfix` (= urgent bugfix), `security` (= bugfix/feature + high risk).
- `spike` is outside the workflow (its output is a conclusion, not mergeable code).
- Work that is two types at once → **split into two jobs** (two worktrees).

## Command arguments = input

`/aw-intake JIRA-123 https://confluence/…` — arguments are the input list, not the feature name (feature name comes from the branch).

**Labels are assigned by the machine** (`aw input`, see Step 0b): copy **stdout exactly** into `## Input`; never label or edit yourself. A single unrecognised token makes the **whole string** one verbatim `[HUMAN]` entry; a source inside the sentence (e.g. `ABC-123` in "sửa phí hoàn tiền ABC-123") is only a **split suggestion** — ask the human, add a separate line only if they agree.

## Create the worktree (on the main checkout)

Worktrees are mandatory. The main checkout stays on `base_branch` and only runs `/aw-intake`. `ĐANG Ở CHECKOUT CHÍNH` means "create a worktree" for `/aw-intake`, "stop" for any other command.

The agent **never decides** worktree location or base. In order:

1. Read the input, **agree the work type with the human** (tree above).
2. Pick a short description: lowercase ASCII, digits, `-` (e.g. `phi-hoan-tien`).
3. `aw worktree new <type> <description>` — **only prints a proposal**: name from `type_by_prefix` (branch, worktree dir and artifact dir share one name), path from `worktree_dir`, candidate **bases** with facts. ★ is the machine's suggestion, not yours.
4. Show the proposal **verbatim**; the human **chooses the base** and confirms the name (other name → change `<description>`, rerun step 3).
5. `aw worktree new <type> <description> --create --base <ref>` with **exactly the human's ref**. Copy the `Base:` and `Engine:` lines it prints into `intake.md`.
6. Write `intake.md` to `<worktree>/.agent-workflow/<name>/`, run `aw check intake` on that dir, then **stop**: the human runs the prepare command (`LENH_CHUAN_BI_WT`, printed) and opens a **new** agent session in the worktree for `/aw-spec`. In the new session `aw ready <thư-mục-feature>` reports whether the environment is ready and the next step.

`ĐÃ CÓ WORKTREE`: create nothing — tell the human to open a session at the printed path and rerun `/aw-intake` there if input must be added.

- **Base:** checkers diff against the fork point from this base. Stacking on another job's branch is allowed; review will warn.
- **Engine:** every checker of this job runs exactly this version (`YYYY.M.N`, exact match). Not available → checker reports KHÔNG HỢP LỆ. Upgrading the engine mid-job does not change this job's rules.

## Inside the worktree

- Suggest the type from the branch prefix (`type_by_prefix`), check against the input, ask the human to confirm.
- Type confirmed by the human differs from the branch prefix → **no exceptions**: fix the type, or `aw rename` (renames branch, artifact dir, worktree; human opens a new session at the new path).

**Re-running with an existing `intake.md` = append input:**
1. Do not recreate from the template. Keep `Type` and `Goal`.
2. `aw input --skip <thư-mục-feature>/intake.md -` — skips inputs already present (by identifier: `ABC-1` and `…/browse/ABC-1` are the same). **Append** stdout to the end of `## Input`.
3. New input suggests a different type → **tell the human**, do not edit `Type`. If the human changes it, confirm as the first time (`aw rename` if the prefix no longer matches).
4. Run the checker, stop for the human to confirm the **new inputs**.

No command removes input — the human edits by hand. A changed `intake.md` makes `spec.md` stale: rerun `/aw-spec` (later phases warn, review blocks).

## Output

`intake.md` per `templates/intake.md`:
- `Type`, `Goal` (one sentence), `Base`, `Engine` (exactly as `aw worktree new` printed).
- `## Input`: documents `[CONFLUENCE]`/`[JIRA]`/`[FILE]` + identifier; human words `[HUMAN]` **verbatim** on the `>` line below.

`01-spec` cites human words as `[FILE] intake.md § Input`.

## Forbidden

- **Summarising, paraphrasing or quoting requirements** from sources — only point to them.
- Labelling input yourself, editing `aw input` lines, `[INFERRED]` in input, non-verbatim human words.
- Rewriting `intake.md` from scratch on rerun, or changing `Type` yourself.
- Deciding the work type; choosing the base / filling `--base`; creating the worktree before the human chooses.
- Editing the `Engine:` line.
- Switching your session into the new worktree.
- Fixing scope or technical solution.

## Exit conditions

**Machine:** `aw check intake` → `[x] ĐẠT` — valid `Type`, has `Goal`, ≥ 1 validly labelled input, no `[INFERRED]`, `[HUMAN]` has verbatim text, `[JIRA]` key matches `jira_key_regex`, `Base:` sha is an ancestor of HEAD, `Engine:` is `YYYY.M.N` and matches the running engine. Type vs branch prefix mismatch: warning (review blocks).

**Human:** chooses the base, confirms work type and input.
