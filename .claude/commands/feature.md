---
description: Run the full Planner → Dev → Reviewer → QA pipeline for a feature
---

Feature request: $ARGUMENTS

Run this pipeline. Do not skip stages. Show me each stage's verdict.

1. Slugify the feature name, `mkdir -p .claude/workflow/<slug>/`.
2. @ios-planner — produce plan.md. **Show me the plan and stop for my approval
   before continuing.**
3. @ios-dev — implement from plan.md.
4. @ios-reviewer — review the diff.
   - CHANGES_REQUESTED → send review.md back to @ios-dev, then re-review.
   - Max 2 fix cycles. On a third, stop and escalate to me.
5. @ios-qa — verify.
   - FAIL → send qa.md to @ios-dev, then re-run QA. Max 2 cycles.
6. Summarize: what shipped, what's UNVERIFIABLE, what needs my attention.
