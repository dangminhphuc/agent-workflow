# AGENTS.md — agent-workflow engine

This repo is the **engine** (wrapper `aw`, checkers, phase definitions, adapters), not a project
that runs the workflow — artifacts (`.agent-workflow/`) exist only in target repos.
Usage: `README.md`, `docs/huong-dan.md`. Design rationale: `docs/kien-truc.md`. Terms: `docs/thuat-ngu.md`.

## Map

- `workflow.yaml` — source of truth: phases, utility commands, rules, adapters (with status).
- `workflow/phases/*.md` — frontmatter = contract (adapters build I/O from it), body = agent
  instructions. Field list: `docs/kien-truc.md` § Định dạng file phase.
- `workflow/checkers/` LLM checkers (block only) · `workflow/rules/` runtime rules ·
  `workflow/templates/` artifact templates (`target-repo/` is for target repos, not this one).
- `bin/aw` global wrapper (picks version, downloads, checks sha256); `bin/aw-engine` dispatches to `tools/*.sh`.
- `tools/check-*.sh` machine checkers, registered in `tools/lib/commands.sh`.
- `adapters/lib/common.sh` (`ad_sinh`) generates everything; `adapters/<id>/build.sh` only declares
  hooks + format spec (`adapters/README.md`).

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

## Change together

- Phase: `workflow/phases/NN-<id>.md` + `phases:` in `workflow.yaml`; `exit_machine` →
  `tools/check-<id>.sh` + `tools/lib/commands.sh`; new artifact → template; tests.
- Utility command: `workflow/<id>.md` + `commands:` in `workflow.yaml`.
- Adapter: follow `adapters/README.md`; declare hooks only, never reimplement generation.
- `conventions.md` key: `workflow/templates/conventions.md` + `conventions-reference.md`.
- Every change, see § Human docs.

## Human docs

Every change ships human-readable docs in the same PR — no exceptions for internal, refactor, test
or tooling changes. Vietnamese, for a reader who does not read the diff.

- **Summary**: an entry under `## [Chưa phát hành]` in `CHANGELOG.md` — what changed, why, who is
  affected / what to do. Sections: `Thêm`, `Thay đổi`, `Sửa`, `Bỏ`; changes invisible to users of
  `aw` go under `Nội bộ`.
- **Living docs**: update every doc the change makes wrong or incomplete — usage: README /
  `docs/huong-dan.md`; rationale: `docs/kien-truc.md`; new term: `docs/thuat-ngu.md`; open work:
  `docs/viec-can-lam.md`. Nothing to update → say so in the PR description.

## Making a change

- Restate the request in your own words; ask before editing if scope, strictness
  (block/warn), or user-visible behavior is unclear. Check `docs/kien-truc.md` for
  prior decisions first.
- Behavior or rule changes: propose the approach (files touched, block vs warn,
  what the test proves) and wait for the human's OK before coding.
- Work in a git worktree on a new branch based on fresh `origin/main`; never edit
  `main` directly. Tests first, then code (§ Verify).
- Stay in scope. Related ideas → propose; if accepted, add to `docs/viec-can-lam.md`,
  don't implement.
- Finish with a PR: what changed, why, which tests cover it. The human merges.

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
