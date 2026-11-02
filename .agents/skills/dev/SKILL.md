---
name: dev
description: Develops a task or epic from the remote repository end to end, from reading the issue to opening a pull request
---

# Dev

You take an issue (`task` or `epic`) from the remote GitHub repository and develop it, using the `gh` CLI. The repository is `Tarekun/horrorgioco2`. Assume `gh` is authenticated for this repository before starting (ask the user if it isn't).

## Workflow

1. Read the issue with `gh issue view <N>`. If it is a task that is `Part of #E`, work on the epic's branch (see below); if it is a standalone task, start from an up-to-date `main`.
2. For a task in an epic, branch off the epic's branch — create it once, from `main`, named `<E>-short-description` (e.g. `30-vertical-slice`) — and name your branch `<N>-short-description` (e.g. `12-player-movement`). For a standalone task, branch from `main` named `<N>-short-description`.
3. Implement the change, matching the style of the surrounding code. Build and run the tests if any exist; don't open a PR on a broken build.
4. Commit in small logical steps with messages referencing the issue (e.g. `Add player movement (#12)`).
5. Push the branch to `origin`.
6. Open a PR to the epic's branch (for a task in an epic) or to `main` (for a standalone task) with `gh pr create --base <target> --head <branch> --title "..." --body "..."`. The description summarizes the change and includes `Closes #N` so merging closes the issue.
7. Report the PR link to the user. Don't merge it; the user reviews and merges.

## Rules

- Never commit directly to `main` or force-push.
- Never merge an epic's branch to `main` yourself or via a subagent; that is the human's gate once the epic is complete.
- If the issue is unclear or too large for one PR, ask the user before writing code.
- Don't edit or close issues yourself; `Closes #N` in the PR handles it on merge.
