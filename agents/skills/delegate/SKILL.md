---
name: delegate
description: Build a GitHub ticket with the agent writing the code. Takes a ticket number or URL, works in its own git worktree with its own databases and a Preview on its own ports so it can run in parallel with other sessions, builds test-first one acceptance criterion at a time, opens a draft PR without asking, then stays open for Iteration on the user's feedback.
disable-model-invocation: true
---

# Delegate

This is the build step of the user's workflow (`explore → shape → to-issues → drive | delegate → review`). In `delegate`, **you write the code**. The user picked this ticket to hand off, often while they `drive` another one in the main checkout, or while several other `delegate` sessions run beside this one. Your job is to turn the ticket into a draft PR without needing them, give them a running Preview to try it in, and then build the changes they ask for until they're satisfied. Leave their checkout alone the whole time.

Run it as `/delegate 43` or `/delegate https://github.com/owner/repo/issues/43`. It needs a ticket and builds exactly one per run.

## 1. Start

**Resolve the ticket.** Run `gh issue view <n-or-url> --json number,title,body,state,labels,parent,blockedBy,subIssues,url`. If it's a URL for a different repo than the one you're in, stop and say so.

**Check it's a ticket you can start.**

- If it's a spec, meaning it has the `spec` label or has sub-issues, stop and list its sub-issues with their state. Don't suggest which one to build.
- If it's closed, stop.
- If it has open blockers, name them and ask whether to go ahead. Usually the answer should be no, because the blockers' code isn't on the default branch yet. The user may know it's fine anyway, so it's their call.

**Set up the worktree.** Get the default branch from `gh repo view --json defaultBranchRef`, then run `git fetch origin`. Put the worktree next to the repo at `../<repo>.worktrees/<n>-<slug>`. `<repo>` is the name of the repo's top-level directory, and the slug is 2 to 5 words from the ticket title.

- If a worktree or branch for this ticket already exists, this is a **resume**. Look for a branch named `<n>-*` locally and on `origin`, and check `git worktree list`. Reuse the worktree, or add one for the existing branch. If git refuses because the main checkout has the branch checked out, stop and say so. Read the state file (section 2) to find the databases and ports this ticket already has. Then run setup (section 2) without creating anything twice, and restart the Preview on the same ports. Carry on where the run left off. That means the remaining criteria, or Iteration (section 6) if the PR already exists (`gh pr list --head <branch> --state open`).
- Otherwise, run `git worktree add --no-track -b <n>-<slug> ../<repo>.worktrees/<n>-<slug> origin/<default>`.

The main checkout's state doesn't matter, since you never touch it. The user may be working there right now. Do everything inside the worktree. `cd` into it and use absolute paths under it.

**Read the context.** Read the ticket, its parent spec (`gh issue view <parent> --json title,body`), and `GLOSSARY.md` (or `GLOSSARY-MAP.md` in a multi-context repo) if there is one. Use glossary terms in tests, code and the PR.

## 2. Setup and baseline

A fresh worktree has no installed dependencies, none of the gitignored files, and nothing of its own to run against. Several sessions may be set up at the same time, so everything stateful this worktree uses must be its own. Otherwise two branches' migrations, test runs or servers collide.

Work out how the project runs from the code. Look at `CLAUDE.md`, `AGENTS.md`, `package.json` scripts, a `Makefile`, `pyproject.toml`, `docker-compose.yml`, framework config and CI config. If `CLAUDE.md` or `AGENTS.md` has a "Worktree setup" section, follow it.

1. **Dependencies.** Install them with the project's usual command.
2. **Env files.** Copy the main checkout's gitignored env files (`.env`, `.env.local` and similar, but not `.env.example`) into the worktree. Copy them and don't symlink, so nothing you do can change the user's file. First check with `git check-ignore` that each one is ignored in the worktree. If one isn't, don't copy it, and ask. Never edit the copies. Pass anything this worktree needs differently (ports, database names, service URLs) as environment variables or flags when you launch a command.
3. **Databases.** If the project uses a database, give the worktree its own dev and test databases on the same server, named after the user's with `_<n>` appended (`app_dev_43`, `app_test_43`). Fill the dev database with a copy of the user's dev data using dump and restore, so the Preview has realistic data to show. Don't use `createdb -T`, because Postgres refuses to copy a database that still has connections, and the user's own app is probably connected to it. For SQLite, copy the file. Then run the branch's migrations on the copies. On a resume, reuse what's there and never copy again, because a new copy would wipe migrations and data from earlier Iterations. Point every test, migration and Preview command at these databases. Running even one of them against the user's own database by mistake can break their work.
4. **State file.** As soon as you create anything outside git, record it in `~/.local/state/delegate/<repo>/<n>.json`, and update the file as you add more. The user runs `delegate-prune` after their PRs merge. It reads these files to stop the Preview and remove what you made, and it can only remove what's written down here.

   ```json
   {
     "repo": "<absolute path of the main checkout>",
     "worktree": "<absolute path of this worktree>",
     "branch": "43-orders-by-customer",
     "ports": [3043, 8043],
     "teardown": [
       "dropdb --if-exists --force app_dev_43",
       "dropdb --if-exists --force app_test_43"
     ]
   }
   ```

   Paths are absolute, as they are on this machine. `ports` are the Preview's. Each `teardown` entry is a one-line shell command that removes one thing you created, and does nothing if it's run twice. `delegate-prune` runs each one from the worktree with `bash -c`, so name Docker containers or Compose projects explicitly rather than relying on the current directory.

5. **Baseline.** Run the full test suite and linters once, before writing any code. This tells you what "green" looks like, so you never mistake breakage that was already there for your own.
6. **Preview.** If the project has a dev server, start a Preview. A Preview is the whole stack in this repo (frontend, backend, workers) running from the worktree, so the user can try this ticket in the browser beside other sessions' Previews.
   - Each service runs on its usual port plus `n mod 1000`. For #43, web 3000 becomes 3043 and the API 8000 becomes 8043. If a port is taken, or lands on the usual port itself (#1000), use the next free one. The user's main checkout keeps the usual ports.
   - Connect the services to each other's new ports with the env vars or flags they already read, such as an API URL or a proxy target.
   - Leave other stateful services (Redis, queues, local object storage) shared, unless the project's Worktree setup section says how to separate them.
   - Run it in the background and check that it responds before moving on. Keep it running for the rest of the session. If it dies, restart it on the same ports.
   - Skip this step without comment for projects with no dev server, such as libraries and CLIs.

Stop and ask the user if:

- the baseline is already red,
- an env file isn't gitignored,
- a port is hardcoded with no env var or flag to change it, since making it configurable would mean changing code outside the ticket, or
- you can't get the environment working, for example because of a missing env file or a service that won't start. Don't guess at config.

Apart from gaps (section 4), these are the only reasons to interrupt the user. Decide everything else yourself, within what the ticket allows.

## 3. Build

Work through the acceptance criteria one at a time:

1. Write a test for the criterion.
2. Run it and check that it fails for the right reason. A test you never saw fail might not test anything.
3. Write the least code that makes it pass. While you work, run the typechecker and the test file you're in, not the whole suite.
4. Commit.

Test behaviour through public interfaces (the exported function, the endpoint, the UI), not internals, so the tests still pass after later refactors. Don't write all the tests first and then all the code. Use what you learned in each cycle when you write the next test.

Stay inside the ticket. Don't fix neighbouring code, tidy up, or add behaviour the ticket doesn't ask for. Those changes make the PR harder to review, and cleanup belongs in review.

**Commits.** A test and the code that passes it go in one commit, so the type is usually `feat` or `fix`, not `test`. A prefactor ticket is `refactor`. Never rewrite history.

## 4. Gaps

If the ticket is unclear, or you hit a decision it doesn't make (for example what happens when a customer has no orders), stop and ask the user. Don't guess. This should be rare. It means `to-issues` missed something.

- **Small gap.** One answer settles it, and it needs no new term or ADR. Ask, then carry on with the answer. Offer to record the decision as a comment on the ticket, where the reviewer will see it. Show the user the comment first, and post it with `gh issue comment <n> --body-file <file>` only after they approve. Tell the user in one line that `to-issues` missed this.
- **Large gap.** It needs a new glossary term or an ADR, or it changes other tickets. Suggest stopping to grill it. Leave the worktree in place so a later run can resume.

## 5. Finish

1. **Run the full test suite and linters.** Fix what you broke.
2. **Check the criteria.** Every acceptance criterion should have a test.
3. **Push and open a draft PR without asking.** The user reviews your work in the PR and the Preview, so there's nothing to approve first. Run `git push -u origin <branch>`, then `gh pr create --draft --base <default> --title "<title>" --body-file <file>`. The PR is always a draft, because Iteration usually follows and the PR is ready only when the user says so.
4. **Title.** Use the commit format with the ticket's title as the description. "Show orders grouped by customer" becomes `feat: show orders grouped by customer`. Leave the ticket number out. `Closes #<n>` already links them, and a squash merge adds the PR number.
5. **Report** in one line with the PR link and the Preview URL(s), then say you're ready for feedback.

Don't remove the worktree, branch, databases or Preview. They stay until the PR merges, so the user can keep iterating. After that, `delegate-prune` cleans them up.

### PR description

Keep it short. If the repo has a PR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, the same names in the root or `docs/`, or `.github/PULL_REQUEST_TEMPLATE/`), fill it in and follow its structure. Otherwise use:

```markdown
<1 to 3 lines on what changed, in glossary terms.>

- [x] Every acceptance criterion has a test

## Still red

- <A failing test or lint, or a criterion with no test after a real effort.>

## Decisions

- <A choice you made that the ticket didn't dictate, and why.>

<One line on why it's large, only if the PR is much larger than usual for one ticket.>

Closes #<n>
```

Tick the test checkbox only when every criterion has a test. Otherwise leave it unticked and name the uncovered criteria on the line below it. Leave out `## Still red` when everything is green, and `## Decisions` when you made no choices beyond what the ticket said. When you include Decisions, the reviewer needs to check those choices more than anything else in the PR.

### "To design" notice

After opening the PR, look at the parent spec's sub-issues. If this ticket is the only one still open and the spec has `Later:` items under Non-goals, tell the user:

> Once this merges, spec #41 is complete. Its Later items are:
>
> - <item>
> - <item>

## 6. Iteration

The session doesn't end with the PR. The user tries the Preview, looks at the PR, and gives feedback in this chat, often while running several sessions side by side. Each round of feedback is an Iteration. Build it, then push it to the same PR.

- **Build it the same way.** A change in behaviour gets a test first, as in Build. A visual or copy tweak doesn't need a new test. Comments and commits follow the same rules.
- **Check, then push without asking.** Before each push, run the typechecker, the linters and the tests the change affects. Then commit and push. The PR should always match what the user sees in the Preview.
- **Keep the description true.** If the user asks for something beyond the ticket, build it, since they asked, and add a line under `## Decisions`. Update the checkbox and `## Still red` as things change. Use `gh pr edit <n> --body-file <file>`.
- **Stay a draft.** Run `gh pr ready` only when the user tells you to. They may also mark it ready on GitHub themselves.
- **Review comments.** When the user asks you to address the PR's comments, read them with `gh pr view <n> --comments` and `gh api repos/{owner}/{repo}/pulls/<n>/comments`, and treat each as feedback. Don't reply on GitHub unless the user asks.
- **Unclear feedback.** Ask, since the user is right there. A request that changes other tickets or needs a new term is a large gap (section 4).

Keep the Preview running between Iterations. End each one with a line saying what changed and that it's pushed.
