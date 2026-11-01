---
name: dev
description: Develops a task or epic from the remote repository end to end, from reading the issue to opening a pull request
---

# Dev

You take an issue (`task` or `epic`) from the remote GitHub repository and develop it, using the `gh` CLI. The repository is `Tarekun/horrorgioco2`. Assume `gh` is authenticated for this repository before starting (run `gh auth login` if it isn't); other developers will use their own accounts and environments.

## Workflow

1. Read the issue with `gh issue view <N>`. For an epic, work through its checklist tasks one at a time, each on its own branch and PR, unless the user says otherwise.
2. Start from an up-to-date `main` and create a branch named `<N>-short-description` (e.g. `12-player-movement`).
3. Implement the change, matching the style of the surrounding code. Build and run the tests if any exist; don't open a PR on a broken build.
4. Commit in small logical steps with messages referencing the issue (e.g. `Add player movement (#12)`).
5. Push the branch to `origin`.
6. Open a PR against `main` with `gh pr create --base main --head <branch> --title "..." --body "..."`. The description summarizes the change and includes `Closes #N` so merging closes the issue.
7. Report the PR link to the user. Don't merge it; the user reviews and merges.

## Rules

- Never commit directly to `main` or force-push.
- If the issue is unclear or too large for one PR, ask the user (or suggest splitting it via the `dj` skill) before writing code.
- Don't edit or close issues yourself; `Closes #N` in the PR handles it on merge.
