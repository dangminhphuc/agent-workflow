# AGENTS.md — agent-workflow engine

This repo is the **engine** (wrapper `aw`, checkers, phase definitions, adapters), not a project
that runs the workflow — artifacts (`.agent-workflow/`) exist only in target repos.
Usage: `README.md`, `docs/huong-dan.md`. Design rationale: `docs/kien-truc.md`. Terms: `docs/thuat-ngu.md`.
Open work: `docs/superpowers/2026-10-22-roadmap-cai-thien.md` (the only todo list; specs/plans beside it in `docs/superpowers/`).

**Never change `main` directly.** Every change — code, docs, typo, CHANGELOG — starts with
`git fetch origin && git worktree add <path> -b <branch> origin/main` and ends with a PR into
`main`; the human merges. In Claude Code `.claude/hooks/block-main.sh` blocks edit/commit/push on
`main`; other agents follow this line unenforced.

## Map

- `workflow.yaml` — source of truth: phases, utility commands, rules, adapters (with status),
  `sdlc:` (a note per stage the engine implements only partly or not at all; status is derived).
- `workflow/phases/*.md` — frontmatter = contract (adapters build I/O from it), body = agent
  instructions. Field list: `docs/kien-truc.md` § Định dạng file phase.
- `workflow/checkers/` LLM checkers (block only) · `workflow/rules/` runtime rules ·
  `workflow/templates/` artifact templates (`target-repo/` is for target repos, not this one).
- `bin/aw` global wrapper (picks version, downloads, checks sha256); `bin/aw-engine` dispatches to `tools/*.sh`.
- `tools/check-*.sh` machine checkers, registered in `tools/lib/commands.sh` — except
  `check-release.sh` and `check-sdlc.sh`, which check this repo, not a job dir.
- `sdlc/` SDLC interface — the source of every engine change: `stages/NN-<stage>.md` (contract
  per stage + capabilities `CAP-<stage>-NN`: the target state, done or not), `profiles/<job-type>.md`
  (what each job type skips or adds), `invariants.md` (cross-stage rules, each pointing to a checker
  + test). Phases declare `implements:` + `provides:` + `capabilities:`; `tools/check-sdlc.sh` checks
  the mapping, derives each stage's status and prints the missing capabilities. How to read and
  change it: `docs/interface-sdlc.md`; rationale: `docs/kien-truc.md` § Interface SDLC.
- `adapters/lib/common.sh` (`ad_sinh`) generates everything; `adapters/<id>/build.sh` only declares
  hooks + format spec (`adapters/README.md`).
- `.claude/` dev setup for this repo only (hook above; test `tools/tests/19-block-main-hook.sh`).

## Language

- Read by agents at runtime (phases, `workflow/*.md`, rules, checkers, adapter-generated text):
  English, terse, directives only.
- Read by humans (README, docs, CHANGELOG, frontmatter `name`/`summary`, `aw` output, `Kết quả`
  labels): Vietnamese.
- Templates and artifacts: headings, field names, keywords, enum values are English — new ones
  too. Vietnamese only for body text and placeholders. Checkers match exact strings: renaming one
  means changing checker + tests in the same commit. Runtime rule: `workflow/rules/general.md` §5.
- Identifiers (files, `config.sh` keys, env vars, artifacts, subagents): English; renaming a
  user-facing one keeps the old name readable (`tools/lib/config.sh`). Shell functions/vars:
  unaccented Vietnamese (`kq_khai`, `ghi_file`), like surrounding code.

## Code

- POSIX sh + awk + sed + git only: no bashisms, Node, Python, jq. ERE without `{n}` (mawk).
  Multi-file awk: `FILENAME == ARGV[i]`, never `FNR==1`.
- YAML: only the subset `tools/lib/md.sh` parses (`k: v`, `k:` + `  - item`, `k: []`).
- Every script declares result labels via `kq_khai` (`tools/lib/result.sh`); prompts/docs refer to
  labels, not exit codes.
- Repo/config paths come only from `AW_REPO`, `AW_CONFIG` (`tools/lib/env.sh`).
- Adapter builds run `set -e`: a trailing `[ … ] && printf` in a block/loop kills it — use `if`.
- Agent-specific text lives only in adapter hooks; the compare test (`AW_COMPARE=1`) requires
  byte-identical output across adapters.
- One rule, one place. Phase files never restate the I/O contract or what the checker checks.
  Rationale goes in `docs/kien-truc.md`.
- New rule: precise → block; cross-phase or false-positive-prone → warn in implement, block in review.
- A new block/warn rule gets a comment `# giữ: CAP-…[, INV-…]` above it naming what it keeps; `sh tools/check-sdlc.sh`
  blocks a claimed `machine` capability no rule names, and unknown ids (older rules are tagged gradually).

## Change together

- Phase: `workflow/phases/NN-<id>.md` + `phases:` in `workflow.yaml`; `exit_machine` →
  `tools/check-<id>.sh` + `tools/lib/commands.sh`; new artifact → template; tests;
  `implements:` + `provides:` + `capabilities:` in frontmatter; `sh tools/check-sdlc.sh` passes.
- SDLC stage or invariant: `sdlc/stages/` or `sdlc/invariants.md` + `tools/tests/20-sdlc-conformance.sh` (mapping),
  `24-sdlc-stage-status.sh` (derived status, `out_of_scope`), `22-sdlc-stage-files.sh` (stage file, invariant),
  `25-sdlc-capabilities.sh` (capability)
  or `23-sdlc-syntax.sh` (YAML subset, abstract `Rule:`, named test cases, `# giữ:` tags);
  a new stage declares ≥1 capability under `## Capabilities`.
- Implement a missing capability: its id in the phase's `capabilities:` + fix or drop the stage's
  `note` in `sdlc:` of `workflow.yaml` + tests of the behaviour; `sh tools/check-sdlc.sh` passes.
- Add a capability: `sdlc/stages/NN-<stage>.md`; the stage may become partial → add its `note`.
- Weaken the interface (drop or relax a capability or invariant): ids + reason under `### Bỏ` /
  `### Thay đổi` in `changes/<branch>.md`, so the reviewer sees it.
- Job type (`LOAI_HOP_LE`): `sdlc/profiles/<job-type>.md` (stages it skips, artifacts and invariants it
  adds) + `tools/tests/21-sdlc-profiles.sh`; `sh tools/check-sdlc.sh` passes.
- Utility command: `workflow/<id>.md` + `commands:` in `workflow.yaml`; never `implements:` (not an SDLC stage).
- Adapter: follow `adapters/README.md`; declare hooks only, never reimplement generation.
- `conventions.md` key: `workflow/templates/conventions.md` + `conventions-reference.md`.
- Every change, see § Human docs.

## Human docs

Every change ships human-readable docs in the same PR — no exceptions for internal, refactor, test
or tooling changes. Vietnamese, for a reader who does not read the diff.

- **Summary**: a new file `changes/<branch>.md` (`/` → `-`), never an edit to `CHANGELOG.md` —
  what changed, why, who is affected / what to do. Only `### <section>` headings + entries:
  `Thêm`, `Thay đổi`, `Sửa`, `Bỏ`; changes invisible to users of `aw` go under `Nội bộ`. Format:
  `changes/README.md`; `tools/prepare-release.sh` gathers fragments into `CHANGELOG.md`.
- **Living docs**: update every doc the change makes wrong or incomplete — usage: README /
  `docs/huong-dan.md`; rationale: `docs/kien-truc.md`; new term: `docs/thuat-ngu.md`; open work:
  roadmap (`docs/superpowers/2026-10-22-roadmap-cai-thien.md`). Nothing to update → say so in the PR description.

## Making a change

- **Locate in the interface first** (`docs/interface-sdlc.md`): name the `CAP-…` / `INV-…` the change
  serves. None fits → change the interface (capability or invariant) in the same PR. Changes outside
  any stage (wrapper, adapters, test infra, docs) say "no interface change: <reason>".
- Restate the request in your own words; ask before editing if scope, strictness
  (block/warn), or user-visible behavior is unclear. Check `docs/kien-truc.md` for
  prior decisions first.
- Behavior or rule changes: propose the approach (`CAP-…` / `INV-…` ids, files touched, block vs warn,
  what the test proves) and wait for the human's OK before coding.
- Worktree from fresh `origin/main` first (top of this file). Tests first, then code (§ Verify).
- Stay in scope. Related ideas → propose; if accepted, add a sub-project to the roadmap
  (its § Cách dùng), don't implement.
- Before every push to a PR branch: `git fetch origin && git merge origin/main`, resolve, rerun
  `sh tools/run-tests.sh`. Never rebase or force-push a pushed branch.
- Finish with a PR into `main`: what changed, why, which tests cover it, and a line
  "Interface: CAP-…, INV-…" or "no interface change: <reason>" (convention; not machine-checked).
- After a PR merges, check the other open PRs for conflicts with the new `main`; resolve each by
  merging `origin/main` into its branch (same rules as above).

## Verify

- `sh tools/run-tests.sh` must end with label `MỌI CA ĐẠT`.
- Tests live in `tools/tests/NN-<topic>.sh` (helpers + fixture: `tools/tests/lib.sh`), run in parallel.
  Add a case to the part of the same topic; a part must not depend on another part. While
  iterating: `sh tools/run-tests.sh <part-name>` or `sh tools/tests/<part>.sh`.
- Output ends with per-part timing. A part your change makes slow (`CẢNH BÁO … nên tách`) → split it
  at a fixture boundary in the same PR (`docs/kien-truc.md` § Cách thêm một phase).
- Tests: `ky_vong <code> "<name>" <cmd>`, `dung "<name>" <test>`. Test every checker both ways
  (blocks when it should, passes when it should). Changed text a test greps → fix the test in the same commit.
- Inspect generated commands: `sh adapters/claude-code/build.sh --out <tmp-git-dir>`.

## Release

Follow README § Chạy test và phát hành. Never tag by hand — merging to `main` creates the tag + Release.
