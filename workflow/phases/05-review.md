---
id: review
name: Rà soát độc lập
summary: Bước 6/6 · Subagent ngữ cảnh sạch đối chiếu diff với spec, thiết kế, kế hoạch; ghi review.md
required: true
inputs:
  - intake.md
  - spec.md
  - open-questions.md
  - tdd.md
  - plan.md
  - task-results.md
  - test-results.md
  - security-results.md
  - repro.md (bugfix)
  - perf.md (perf)
  - diff
outputs:
  - review.md
exit_machine:
  - aw check review
exit_human:
  - The human confirms the review verdict and decides how to handle Blocker findings
  - The human confirms the base is intended if the checker warns about an unusual (stacked) base
  - Diff touches sensitive code (sensitive_code) — a human security reviewer reads Lens 4 and the diff, and writes their own name in "Security reviewer"
needs_clean_context: true
requires_fresh_agent: true
---

# Phase 05 — Review

## Goal

Verify **independently** that the diff does what `spec.md` asks, follows the approved `tdd.md`, and stays within `plan.md`. Not a syntax review (linters do that). This is the **final gate**: every warning from earlier phases blocks here.

## Clean context — mandatory

Never run by the agent that just implemented.

| Agent | How |
|---|---|
| Has subagents | Run in a blank-context subagent |
| Has none | Open a new session, load only the input files + diff |

If the adapter cannot enforce this, it must tell the human to open a new session.

## Four lenses — separate, never mixed

### 1. Spec conformance (`## Lens 1 — Spec conformance`)
Go through **every** `YC-NNN`: which code satisfies it, verdict `pass` / `fail` / `partial`. Skip none. A YC with `[OPEN-QUESTION]` whose assumption is unconfirmed → `pending`, never `pass`.

### 2. Design and scope (`## Lens 2 — Design and scope`)
- Does the code follow the approved D-xx, contract and data model of `tdd.md`?
- Changes belonging to no task? Tasks `[x]` with no trace in the diff?
- "Unplanned" items handled silently instead of reported?
- Manually verified tasks (`task-results.md`): does the evidence really prove the task is done?

**Repo rules** (`aw rules review` — every `rules_*` file plus every `uses_*` skill / subagent file, all phases combined): one row per file in `## Repo rules`: `pass` / `violation` (+ `file:line`, add a Lens 3 finding) / `not applicable` (+ reason). Code following an approved D-xx that breaks a rule → `not applicable`, name the D.

**Durable knowledge**: for each module doc / ADR / rule file whose scope the diff touches (`aw check review` lists them), one row in `## Durable knowledge`: `pass` (read it, still true) / `updated` (changed in this diff) / `not applicable` (+ reason). A doc the change makes wrong and nobody updated → `Should fix` in Lens 3.

### 3. Quality (`## Lens 3 — Quality`)
Correctness bugs, reuse of what exists, needless complexity. Each finding `### [Blocker|Should fix|Nit] <title>`:
- `Blocker`, `Should fix`: `- Location: \`file:line\`` (real line) and `- Category: <kebab-case>` (e.g. `missing-null-check`). Run `aw journal` to **reuse existing names**.
- `Blocker`: also `- Failure scenario:` — concrete input → wrong result.
- No findings → exactly one line `- None`.

### 4. Security (`## Lens 4 — Security`)
Scanners catch known patterns; this lens reads the diff for **intent**: missing authorisation, leaking logs, paths built from input… Table with **all seven rows**, none added or renamed:

| Item | Question |
|---|---|
| `Input validation / injection` | Does external input (request, file, message, env) reach SQL/shell/template/query/regex parameterised / escaped / validated? |
| `Authn / authz` | Do new endpoints/actions check login and permission **as the spec's authorisation YC says**? Ids taken from the request without an ownership check (IDOR)? |
| `Sensitive data / PII in logs` | Personal/financial data or tokens logged, over-returned, written to temp files, sent out? |
| `Secrets / config` | Hard-coded secrets in code/test/config? Safe defaults (debug off, narrow CORS, TLS)? |
| `Crypto` | Standard algorithm, key length, randomness? Home-made crypto, non-constant-time token compare? |
| `SSRF / path traversal / deserialization` | URLs, paths, deserialised data from untrusted input without limits? |
| `New dependencies` | Needed, maintained, present in SCA results, valid licence? |

Verdict: `pass` / `finding` (+ `file:line`, **and** a Lens 3 finding) / `not applicable` (+ reason, after reading the diff).

**Sensitive code** (`sensitive_code`): diff touches it → a **human** security reviewer reads Lens 4 and the diff and writes `- Security reviewer: <name>` at the top of `review.md`. Leave it empty, list the sensitive files (`aw check review` prints them), stop and wait.

## Finding levels

| Level | Meaning |
|---|---|
| `Blocker` | Spec violation, deviation from an approved decision, breaking bug, exploitable vulnerability, data loss/leak, undeclared breaking change (API/payload/schema/event changed but not in `tdd.md`/MR). Must not merge |
| `Should fix` | Correct but a real quality problem |
| `Nit` | Author decides |

## By work type — reviewer's judgement

| Type | Do |
|---|---|
| `bugfix` | Read `repro.md`: the test is red **because of the bug** (not a compile error/missing function). Write `Repro test fails because: <quoted output>` (missing → block) |
| `refactor`/`perf` | For each file in "Modified existing tests": the diff only changes imports/structure, **no assertion changes** |
| `perf` | Read `perf.md`, judge the performance YC by the numbers, allowing for noise |
| `chore` | The `patch \| minor` level in "Dependency upgrades" is right (major = separate refactor) |

## Output

`review.md` per `templates/review.md`. `- Reviewed tree:` = the `Tree` line of `test-results.md`; code changed after review → machine blocks, review again.

## Forbidden

- "Looks fine" reviews — not going through every `YC-NNN` = not run.
- **Editing code.** Fixes go back to `04-implement` as new tasks.
- Raising a style remark to `Blocker`.
- `pass` for a YC on an unconfirmed assumption.
- Filling in `Security reviewer` — not even with the name of the person chatting with you.
- `not applicable` for the whole Lens 4 table without reading the diff; downgrading an exploitable vulnerability to `Should fix` as "unlikely".

## Exit conditions

**Machine:** `aw check review` → `[x] ĐẠT`:
- every `YC-NNN` has a valid verdict, no `[OPEN-QUESTION]` is `pass`; input passes `aw check plan`;
- `test-results.md` and `security-results.md` say `Kết quả: XANH` with `Tree` matching current code (code changed → rerun `aw check implement` or `aw check security`; recommitting the same code is not a change); chore touching dependencies has a green `sca` command;
- **no implement warning left**; every task `[x]` with evidence matching `Verify`; no merge conflict markers; work-type rules;
- `## Repo rules` has a valid verdict for **each** rule file (declared file exists, committed);
- each `Promote: adr` D has an ADR matching the approved D; the ADR directory passes `aw adr check`;
- each `Promote: BR-…` YC has a rule block matching the approved YC;
- `## Durable knowledge` has a valid verdict for each doc whose scope the diff touches;
- Lens 4 has seven valid rows; any `finding` → Lens 3 has at least one finding;
- Lens 3 has findings **or** exactly `- None` (not both), no template placeholders; `Location`, `Category`, `Failure scenario` well-formed;
- `## Conclusion` has `- Blocker findings: <n>` equal to the number of `[Blocker]` items; `- Reviewed tree:` matches the code;
- diff touches `sensitive_code` → `- Security reviewer: <human name>` (not empty, not placeholder, not an agent name).

Diff is against the **base in `intake.md`**. Unusual base (e.g. stacked on another branch) → warning only, tell the human. On pass, `[Blocker]`/`[Should fix]` findings go to `aw journal` by `Category`; a category seen in other jobs → checker prints `[GỢI Ý]` to turn it into a machine rule.

**Human:** confirms the verdict, decides on `Blocker`s; decides on `[GỢI Ý]` rule suggestions; confirms an unusual base is intended.
