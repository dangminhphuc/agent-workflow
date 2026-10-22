---
id: plan
purpose: Decide which work enters the pipeline and record it as one work item
requires: []
provides:
  - work-item
exit: both
skippable: false
invariants: []
---

# Stage: plan

- Input: a request from outside the pipeline (ticket, document, human).
- Output `work-item`: what to do, its type, its sources, where the work starts from.
- Exit: the human confirms the work item.

## Capabilities

### CAP-plan-01 — Work item recorded with type, sources and start point
- Rule: every work item states its type, the sources it comes from and the base it starts from, in a form the machine checks.
- Judged by: machine
- Artifact: work-item

### CAP-plan-02 — Human confirms work type, sources and base
- Rule: the human confirms the work type, the source list and the base before any requirement is written.
- Judged by: human
- Artifact: work-item

### CAP-plan-03 — Work items are prioritised against each other
- Rule: a work item enters the pipeline with its priority relative to the other open work items.
- Judged by: human
- Artifact: work-item

### CAP-plan-04 — Work item carries an effort estimate
- Rule: a work item records an effort estimate before work starts, so it can be compared with the actual effort.
- Judged by: human
- Artifact: work-item
