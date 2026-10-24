---
id: implement
purpose: Build the change task by task, in plan order, each task done only when its tests pass
requires:
  - requirements
  - design
  - task-plan
provides:
  - change
  - test-evidence
  - task-evidence
  - security-evidence
exit: machine
skippable: false
invariants:
  - INV-003
---

# Stage: implement

- `change`: the code change.
- `test-evidence`: test results recorded by the machine, bound to the code they ran on.
- `task-evidence`: per task, the result of its verification step, recorded by the machine.
- `security-evidence`: security scan results recorded by the machine, bound to the code they ran on.
- Exit: machine checks only — this stage executes the approved task plan.

## Capabilities

### CAP-implement-02 — Tests are run by the machine; results are bound to the code they ran on
- Rule: test results are recorded by the machine, not reported by the agent, and name the code version they ran on.
- Judged by: machine
- Artifact: test-evidence

### CAP-implement-03 — The change is scanned for security issues before it leaves the stage
- Rule: the machine scans the change for security issues and the stage cannot exit while the scan fails.
- Judged by: machine
- Artifact: security-evidence

### CAP-implement-04 — Every changed file is planned or declared as unplanned
- Rule: each file the change touches is listed in some task's files or declared unplanned with a reason; the implement stage warns, the verify stage blocks.
- Judged by: machine
- Artifact: change

### CAP-implement-05 — Each task changes only its own files, and file patterns are narrow enough to mean something
- Rule: the files changed while a task is in progress match that task's own list or are declared unplanned for it; a file pattern that matches far more files than the task needs is flagged.
- Judged by: machine
- Artifact: change

### CAP-implement-06 — A task is done only when its verification passes, recorded by the machine
- Rule: a task is marked done only by the machine, after its verification step passes or a record of manual verification is given.
- Judged by: machine
- Artifact: task-evidence

### CAP-implement-07 — Durable knowledge in scope of the planned files is retrieved before building
- Rule: the set of durable-knowledge documents is computed by the machine from the task plan's files, not chosen by the agent, and is read before the first task starts.
- Judged by: agent
- Artifact: change
