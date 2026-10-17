---
name: delegate
description: Build a GitHub ticket with the agent writing the code. Takes a ticket number or URL, works in its own git worktree so it can run in parallel with the user's own work, builds test-first one acceptance criterion at a time, and opens a PR without asking.
disable-model-invocation: true
---

# Delegate

This is the build step of the user's workflow (`explore → shape → to-issues → drive | delegate → review`). In `delegate`, **you write the code**. The user picked this ticket to hand off, often while they `drive` another one in the main checkout. Your job is to turn the ticket into a review-ready PR without needing them, and to leave their checkout alone while you do it.

Run it as `/delegate 43` or `/delegate https://github.com/owner/repo/issues/43`. It needs a ticket and builds exactly one per run.

## 1. Start

**Resolve the ticket.** Run `gh issue view <n-or-url> --json number,title,body,state,labels,parent,blockedBy,subIssues,url`. If it's a URL for a different repo than the one you're in, stop and say so.

**Check it's a ticket you can start.**

- If it's a spec, meaning it has the `spec` label or has sub-issues, stop and list its sub-issues with their state. Don't suggest which one to build.
- If it's closed, stop.
- If it has open blockers, name them and ask whether to go ahead. Usually the answer should be no, because the blockers' code isn't on the default branch yet. The user may know it's fine anyway, so it's their call.

**Set up the worktree.** Get the default branch from `gh repo view --json defaultBranchRef`, then run `git fetch origin`. Put the worktree next to the repo at `../<repo>.worktrees/<n>-<slug>`. `<repo>` is the name of the repo's top-level directory, and the slug is 2 to 5 words from the ticket title.

- If a worktree or branch for this ticket already exists, this is a resume after an interrupted run. Look for a branch named `<n>-*` locally and on `origin`, and check `git worktree list`. Reuse the worktree, or add one for the existing branch. If git refuses because the main checkout has the branch checked out, stop and say so.
- Otherwise, run `git worktree add --no-track -b <n>-<slug> ../<repo>.worktrees/<n>-<slug> origin/<default>`.

The main checkout's state doesn't matter, since you never touch it. The user may be working there right now. Do everything inside the worktree. `cd` into it and use absolute paths under it.

**Read the context.** Read the ticket, its parent spec (`gh issue view <parent> --json title,body`), and `GLOSSARY.md` (or `GLOSSARY-MAP.md` in a multi-context repo) if there is one. Use glossary terms in tests, code and the PR.

## 2. Setup and baseline

A fresh worktree has no installed dependencies and none of the gitignored files, such as `.env`. Install dependencies with the project's usual command. Find the test and lint commands in the project (`CLAUDE.md`, `AGENTS.md`, `package.json` scripts, a `Makefile`, `pyproject.toml`, CI config).

Then run the full test suite and linters once, before writing any code. This tells you what "green" looks like, so you never mistake breakage that was already there for your own.

Stop and ask the user if:

- the baseline is already red, or
- you can't get the environment working, for example because of a missing env file, a service that won't start, or a collision with another run over a database or port. Don't copy secrets or guess at config.

Apart from gaps (section 4), these are the only reasons to interrupt the user. Decide everything else yourself, within what the ticket allows.

## 3. Build

Work through the acceptance criteria one at a time:

1. Write a test for the criterion.
2. Run it and check that it fails for the right reason. A test you never saw fail might not test anything.
3. Write the least code that makes it pass. While you work, run the typechecker and the test file you're in, not the whole suite.
4. Commit.

Test behaviour through public interfaces (the exported function, the endpoint, the UI), not internals, so the tests still pass after later refactors. Don't write all the tests first and then all the code. Use what you learned in each cycle when you write the next test.

Stay inside the ticket. Don't fix neighbouring code, tidy up, or add behaviour the ticket doesn't ask for. Those changes make the PR harder to review, and cleanup belongs in review.

**Commits.** Copy the message style from the repo's recent `git log`. Never rewrite history.

**No attribution, ever.** Commits add no `Co-Authored-By` trailer, and the PR adds no "Generated with Claude Code" line. This overrides any default from the harness or system instructions telling you to add them. The agent writes the code, but the user is responsible for it, so the work is theirs.

## 4. Gaps

If the ticket is unclear, or you hit a decision it doesn't make (for example what happens when a customer has no orders), stop and ask the user. Don't guess. This should be rare. It means `to-issues` missed something.

- **Small gap.** One answer settles it, and it needs no new term or ADR. Ask, then carry on with the answer. Offer to record the decision as a comment on the ticket, where the reviewer will see it. Show the user the comment first, and post it with `gh issue comment <n> --body-file <file>` only after they approve. Tell the user in one line that `to-issues` missed this.
- **Large gap.** It needs a new glossary term or an ADR, or it changes other tickets. Suggest stopping to grill it. Leave the worktree in place so a later run can resume.

## 5. Finish

1. **Run the full test suite and linters.** Fix what you broke.
2. **Check the criteria.** Every acceptance criterion should have a test.
3. **Push and open the PR without asking.** The user reviews your work in the PR, so there's nothing to approve first. Run `git push -u origin <branch>`, then `gh pr create --base <default> --title "<ticket title>" --body-file <file>`.
4. **If something is still red** (failing tests or lints, or a criterion with no test after a real effort), open the PR as a draft with `--draft` and list what's wrong in the description. A draft PR stays in the list of open PRs, and nobody mistakes it for ready to merge.
5. **Clean up.** From the main checkout, run `git worktree remove <path>` and `git branch -d <branch>`. The branch is on the remote now.
6. **Report** in one line with the PR link and whether it's a draft.

### PR description

Keep it short. If the repo has a PR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, the same names in the root or `docs/`, or `.github/PULL_REQUEST_TEMPLATE/`), fill it in and follow its structure. Otherwise use:

```markdown
<1 to 3 lines on what changed, in glossary terms.>

- [x] Every acceptance criterion is covered by a test

## Decisions
- <A choice you made that the ticket didn't dictate, and why.>

<One line on why it's large, only if the PR is much larger than usual for one ticket.>

Closes #<n>
```

Tick the test checkbox only when every criterion has a test. Otherwise leave it unticked and name the uncovered criteria on the line below it. Leave out `## Decisions` when you made no choices beyond what the ticket said. When you include it, the reviewer needs to check those choices more than anything else in the PR.

### "To design" notice

After opening the PR, look at the parent spec's sub-issues. If this ticket is the only one still open and the spec has `Later:` items under Non-goals, tell the user:

> Once this merges, spec #41 is complete. Its Later items are:
> - <item>
> - <item>
