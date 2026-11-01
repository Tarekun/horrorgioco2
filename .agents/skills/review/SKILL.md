---
name: review
description: Review a single pull request on the remote GitHub repository. Use when asked to review a PR, or when the manager needs to decide whether an open PR is ready to approve. Loads the diff and the linked issue, then either approves or requests changes with inline comments.
---

# Review

You review exactly one pull request (PR) on the remote GitHub repository using the `gh` CLI. The repository is `Tarekun/horrorgioco2`. Assume `gh` is authenticated for this repository; other developers use their own accounts.

## Choosing the PR

- If the user names a PR, review that one.
- Otherwise pick the most relevant open PR: prefer one that closes an in-progress task, then the oldest unreviewed open PR. Prefer reviewing a PR whose linked task is already being worked on over starting a fresh review of an unrelated PR.

## Gathering context

1. Read the PR: `gh pr view <N>`. Note the title, body, base/head branches, the linked issue (`Closes #N`), and whether CI (`tools/check.sh`) is passing.
2. Pull the linked issue with `gh issue view <N>` and read its acceptance criteria. Understand what the task asked for.
3. Get the diff with `gh pr diff <N>` and check `gh pr status <N>` for commits and CI.
4. For large PRs, split the review by file/section and focus on how the change meets the issue, not on pre-existing code.

## Evaluating

Decide between two outcomes:

- **Approve** when the change implements the task, matches the surrounding code style, follows the conventions in `AGENTS.md` (static typing, Godot 4 APIs only, naming, layout), and includes tests for new gameplay logic. Approve with `gh pr review <N> --approve`.
- **Request changes** when there are code smells, missing or insufficient tests, a bug, a convention violation, or a mismatch with the issue. Request changes with `gh pr review <N> --request-changes`.

## Leaving comments

- Leave inline, per-line comments on the specific lines that need changes; be specific and actionable (what is wrong, what to do). Post them via the pull request comments API:
  `gh api repos/Tarekun/horrorgioco2/pulls/<N>/comments -f pull_request_number=<N> -f path=<file> -f position=<line> -f body="<text>"`
- Add a summary comment explaining the overall assessment and the reasoning behind the inline comments.
- Prefer a few substantive comments over nitpicks. Distinguish blocking issues from optional suggestions.

## Rules

- Review only the PR in scope; do not review multiple PRs in one pass.
- Never approve a broken build. If CI is failing, request changes until it passes.
- Do not edit code, push commits, or modify the PR. Only review and comment.
- Don't edit or close issues yourself; that happens on merge.
- Report the PR link and your decision to the user.
