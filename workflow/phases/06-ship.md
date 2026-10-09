---
id: ship
name: Gửi MR và dọn việc
summary: Bước 7 (tuỳ chọn) · Tạo MR/PR vào nhánh đích, theo dõi tới khi merge rồi dọn worktree và branch
required: false
when: the job passed /aw-review and needs an MR/PR (create it, follow until merged, clean up the worktree)
runs_on_main_checkout: true
inputs:
  - intake.md
  - spec.md
  - open-questions.md
  - tdd.md
  - review.md
  - test-results.md
  - security-results.md
  - repro.md (bugfix)
  - perf.md (perf)
  - diff
outputs:
  - merge-request.md
  - ship.md (written by aw ship create — never edit by hand)
  - mr-description.md (written by aw ship create when the description could not be sent — for the human to paste)
exit_machine:
  - aw check ship
exit_human:
  - The human picks the target branch (develop, uat/…, main…) from aw ship targets
  - The human confirms title, description and target before the MR is created
  - The human reviews and merges the MR on GitHub/GitLab — the agent never merges
needs_clean_context: false
---

# Phase 06 — Send MR and clean up *(optional)*

## Goal

Turn the reviewed work into **one MR/PR** to the target branch the human picks, follow it until merged, then **clean up** the worktree and branch.

| Run where | Does |
|---|---|
| The job's worktree | Write MR description → human picks target → create MR → report status |
| Main checkout | Clean up every merged job (section below) |

## On the main checkout

Step 0 says **ĐANG Ở CHECKOUT CHÍNH** → do only this section.

1. `aw ship sweep` (print only). It sorts each worktree with a `ship.md` into: **dọn được** (all MRs merged), **chờ merge**, **✗ người quyết** (MR closed, unknown, local branch has commits not in the MR).
2. Print it verbatim. Anything cleanable → ask: clean all, clean one (`<branch>`), or later. Cleaning removes the worktree (artifacts archived) and deletes the local and origin branch — irreversible, so **always ask**.
3. Human agrees → `aw ship sweep [<branch>] --apply`, print the result.
4. **✗** items: state the machine's reason, leave it to the human.

Periodic follow-up: rerun on a schedule (the agent's loop/schedule feature if any; otherwise the human reruns).

## In the job's worktree

### 1. Write `merge-request.md`

Per the template and the "Merge request" section of conventions (team convention wins). The source table at the top of the template says which artifact feeds which section.
- First line `# <MR title>` following the team's title convention.
- Only state what is in artifacts or the diff. Unsure → `Open Questions`. Not applicable → `None`, never delete a section.
- Content in Vietnamese unless the team convention says otherwise.

Run `aw check ship <dir>` until `[x] ĐẠT`. It also blocks when `aw check review` fails or a `[Blocker]` remains → back to `/aw-implement` + `/aw-review`.

### 2. Human picks the target branch

`aw ship targets <dir>` → give the list to the **human** (`⚠` = would pull in commits outside this job). Never pick yourself, even with one option. Several targets: one MR each, repeat steps 2–3.

### 3. Human confirms, then create the MR

Creating an MR is **outward-facing**. Show the human: source → target, title, description to send. When they agree:

```sh
aw ship create <dir> --target <human-chosen-branch> [--draft]
```

The engine holds no token; it uses the first route that works: logged-in `gh`/`glab` (sends everything); GitLab without `glab` (push options, title only, description saved to `<dir>/mr-description.md` for the human to paste); a prefilled MR link. Never install `gh`/`glab`, ask for tokens, or log in for the human.

| Result `[x]` | Do |
|---|---|
| `ĐÃ TẠO MR` | Give the URL (stdout). "Mô tả CHƯA gửi" → give the content of `mr-description.md` |
| `ĐÃ CÓ MR ĐANG MỞ` | New commits pushed to the existing MR (description untouched). Give its URL |
| `CHƯA ĐỦ ĐIỀU KIỆN` | `aw check ship` fails or uncommitted changes remain. Never commit unknown changes (that is `/aw-implement`'s job) |
| `KÉO THEO COMMIT NGOÀI VIỆC` | Print the commit list. Human decides: other target, new branch + cherry-pick, or accept — `--allow-extra-commits` only when the human says accept |
| `KHÔNG TẠO ĐƯỢC MR` | Branch pushed. Give the prefilled link; once the human gives the MR link → `aw ship create <dir> --target <branch> --url <link>` |

### 4. Follow up

`aw ship status <dir>` updates `ship.md`. Without `gh`/`glab` it infers from git (normal and clean squash merges; closed MRs or squash with conflict fixes → human checks on the web).

- `CÒN MR ĐANG MỞ`: waiting for review. Review asks for changes → `/aw-implement` (new task) → `/aw-review` → `aw ship create … --target <same branch>`.
- `ĐÃ MERGE HẾT`: tell the human to run this command in a session on the **main checkout** to clean up.
- `CÓ MR BỊ ĐÓNG KHÔNG MERGE`, `CHƯA RÕ`: report; the human decides.

## Forbidden

- **Merging**, approving MRs, enabling auto-merge.
- Picking the target branch; adding `--allow-extra-commits` yourself.
- Force-pushing or rebasing a branch that has an MR.
- Editing `ship.md` by hand.
- Cleaning up without the human's consent, or by anything other than `aw ship sweep --apply` (never `git branch -D`, `git push --delete`, `git worktree remove --force`).
