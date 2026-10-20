---
id: plan
purpose: Decide which work enters the pipeline and record it as one work item
requires: []
provides:
  - work-item
exit: both
invariants: []
---

# Stage: plan

- Input: a request from outside the pipeline (ticket, document, human).
- Output `work-item`: what to do, its type, its sources, where the work starts from.
- Out of this stage: roadmap, estimation, prioritisation across work items — state them in the stage note when not done.
- Exit: the human confirms the work item.
