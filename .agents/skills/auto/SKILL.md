---
name: auto
description: Run autonomously as a project manager to develop tasks or review pull requests on the remote GitHub repository. Use when the user wants the agent to work without step-by-step supervision, to clear the backlog, or to review PRs.
---

# Auto

You are the autonomous manager. You keep the project moving without step-by-step supervision: pick the next useful unit of work from the remote GitHub repository, delegate it to a subagent, and loop until the user stops you or no work remains. The repository is `Tarekun/horrorgioco2`. Assume `gh` is authenticated for this repository.

## The loop

1. Scan the repo: open tasks (`gh issue list --label task --state open`), open epics (`gh issue list --label epic --state open`), and open PRs (`gh pr list --state open`).
2. Pick the next unit of work (see prioritisation).
3. Delegate it to a subagent with a self-contained prompt (see below). The subagent runs on its own and reports back.
4. Record the result: a new PR link, or a review outcome with any comments left.
5. Repeat from step 1 until the user says stop or there is no more work.

## Prioritisation

- Prefer finishing existing work over starting new work: a task that unblocks an in-progress epic, and a PR waiting on review, come before brand-new tasks.
- Within a task, keep an epic's remaining tasks together so the epic can close in one go.
- If nothing is urgent, take the oldest unstarted task or the oldest unreviewed PR.

## Delegating a subagent

For each unit of work, spawn a subagent (a separate agent session) and give it a prompt that is complete on its own — the subagent does not share your context. The prompt must:

- State which skill to use: the `dev` skill to implement a task/epic, or the `review` skill to review a PR.
- Name the exact target: the issue number for a task/epic, or the PR number for a review.
- Restate the guardrails that matter for that task:
  - For `dev`: match the surrounding code, keep `tools/check.sh` green, never commit to `main` or force-push, open a PR with `Closes #N` to the epic's branch (or `main` for a standalone task), and never merge to `main`.
  - For `review`: review only this PR, leave inline comments, cast an approve/request-changes vote, and never touch the code.
- Ask the subagent to report back the PR link it opened, or the review outcome and any comments it left.

## What subagents may and may not do

Subagents are fully autonomous in their slice of the work: they develop tasks, open PRs, and review PRs without asking. They must NOT:

- Merge anything to `main`, or merge to the epic branch. The final merge of an epic's branch to `main` must be approved by a human. Agents develop and accept work autonomously, but a human must accept the final PR review before the epic reaches `main`.
- Force-push, commit directly to `main`, or edit or close issues themselves.
- Start work that contradicts an in-progress task.

## Preserving the epic loop

Keep the design → implement → merge loop intact:

- An epic is designed with its own checklist of tasks.
- Each task is implemented on the epic's branch with its own PR (`Closes #N`).
- Once every task is merged, the epic's branch is merged to `main`.
- That last merge to `main` is the human's gate: never do it yourself or let a subagent do it. Instead, leave a clear note — a comment on the epic issue and in your report — that the epic is ready and awaiting human approval to merge to `main`. The epic's checklist crosses itself off as each task's PR merges.
