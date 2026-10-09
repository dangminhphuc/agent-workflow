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
choice_ui: true
---

# Phase 00 — Intake

## Goal

Answer exactly three questions in `intake.md`, and only **point to** sources — never summarise them:
1. **Work type** — `feature`, `bugfix`, `refactor`, `perf` or `chore`. It changes the rules of every later phase.
2. **Input** — documents with identifiers, or the user's own words. Every later `YC-xxx` traces back here.
3. **Goal** — one sentence.

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

## Arguments = input

`/aw-intake JIRA-123 https://confluence/…` — arguments are the input list, not the feature name (that comes from the branch). **The machine assigns labels** (`aw input`, Step 0b): copy stdout **exactly** into `## Input`. One unrecognised token makes the **whole string** one verbatim `[HUMAN]` entry; a source inside the sentence (e.g. `ABC-123` in "sửa phí hoàn tiền ABC-123") is only a **split suggestion** — ask the human, add a separate line only if they agree. `[HUMAN]` words go **verbatim** on the `>` line; `01-spec` cites them as `[FILE] intake.md § Input`.

## Create the worktree (on the main checkout)

The main checkout stays on `base_branch` and only runs `/aw-intake`. The agent **never decides** location or base:

1. Read the input and classify the work type (tree above) — a proposal; the human confirms it in step 4.
2. Pick a short description: lowercase ASCII, digits, `-` (e.g. `phi-hoan-tien`).
3. `aw worktree new <type> <description>` — **only prints a proposal**: name (branch = worktree dir = artifact dir), path, candidate **bases** with facts. ★ is the machine's suggestion, not yours.
4. Show the proposal **verbatim**, then ask the **confirmation turn** below. Changed type or name → rerun step 3 with it, ask again.
5. `aw worktree new <type> <description> --create --base <ref>` with **exactly the human's ref**. Copy the printed `Base:` and `Engine:` lines into `intake.md`.
6. Write `<worktree>/.agent-workflow/<name>/intake.md`, run `aw check intake` on that dir, then **stop**: the human runs the printed prepare command (`WORKTREE_SETUP_CMD`) and opens a **new** session in the worktree for `/aw-spec`.

`ĐÃ CÓ WORKTREE`: create nothing — tell the human to open a session at the printed path and rerun `/aw-intake` there to add input.

`Base:` is what checkers diff against (stacking on another job's branch is allowed; review warns). `Engine:` is the exact engine version every checker of this job runs.

## Confirmation turn

All human decisions in **one choice question turn**, one question each, in this order (skip one already settled):

| header | Question | Options |
|---|---|---|
| `Loại việc` | the work type | your classification (recommended), then the other plausible types — two types at once → option `Tách hai việc` (one worktree each) |
| `Tên` | the name | the proposed name (recommended), then at most one shorter alternative |
| `Base` | the base | each candidate base, ★ first (recommended, no ★ = none recommended); description = its commit, age, subject from the proposal |
| `Input` | whether `[HUMAN]` is verbatim | `Đúng nguyên văn` — its description **quotes the `[HUMAN]` words exactly** as they will go in `## Input` |

- Only one real option → add `Dừng — chưa tạo gì` as the last option.
- `Input` has no "needs fixing" option: the free-text answer **is** the fix — replace the `>` line with exactly the typed text, character for character.
- Free text on another question = the human's own value (type, name, ref); use it exactly. Unclear → ask again.
- No answer, question dismissed or `Dừng — chưa tạo gì` → create nothing, stop.

## Inside the worktree

- Suggest the type from the branch prefix (`type_by_prefix`), check it against the input, ask the human to confirm (confirmation turn: `Loại việc`, `Input`). Confirmed type ≠ prefix → fix the type, or `aw rename` (the human then opens a new session at the new path).
- **Rerun with an existing `intake.md` = append input:** keep `Type` and `Goal`; run `aw input --skip <dir>/intake.md -` (skips inputs already present) and **append** stdout to `## Input`. New input suggests another type → tell the human. Run the checker, confirm the **new inputs** (confirmation turn: `Input`, one question per new `[HUMAN]` entry), then stop.
- No command removes input — the human edits by hand. A changed `intake.md` makes `spec.md` stale: rerun `/aw-spec`.

## Forbidden

- **Summarising, paraphrasing or quoting requirements** from sources.
- Labelling input yourself, editing `aw input` lines, `[INFERRED]` in input, non-verbatim human words.
- Rewriting `intake.md` from scratch on rerun; changing `Type` yourself.
- Deciding the work type; choosing the base; creating the worktree before the human chooses.
- Switching your session into the new worktree.
- Fixing scope or technical solution.

## Common failures

- `[JIRA]` key not matching `jira_key_regex` (conventions).
- Type ≠ branch prefix: only a warning here, but `/aw-review` blocks.
