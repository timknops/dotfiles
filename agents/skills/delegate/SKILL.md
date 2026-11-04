---
name: delegate
description: Build a GitHub ticket with the agent writing the code. Takes a ticket number or URL, works in its own git worktree with its own databases and a Preview on its own ports so it can run in parallel with other sessions, tests the risky behaviour test-first and checks the UI in a headless browser, pushes the branch, then stays open for Iteration and opens a PR only when the user asks.
disable-model-invocation: true
---

# Delegate

This is the build step of the user's workflow (`explore → shape → to-issues → drive | delegate → review`). In `delegate`, **you write the code**. The user picked this ticket to hand off, often while they `drive` another one in the main checkout, or while several other `delegate` sessions run beside this one. Your job is to build the ticket on a pushed branch without needing them, give them a running Preview to try it in, build the changes they ask for until they're satisfied, and open the PR when they say so. Leave their checkout alone the whole time.

Run it as `/delegate 43` or `/delegate https://github.com/owner/repo/issues/43`. It needs a ticket and builds exactly one per run.

## 1. Start

**Resolve the ticket.** Run `gh issue view <n-or-url> --json number,title,body,state,labels,parent,blockedBy,subIssues,url`. If it's a URL for a different repo than the one you're in, stop and say so.

**Check it's a ticket you can start.**

- If it's a spec, meaning it has the `spec` label or has sub-issues, stop and list its sub-issues with their state. Don't suggest which one to build.
- If it's closed, stop.
- If it has open blockers, name them and ask whether to go ahead. Usually the answer should be no, because the blockers' code isn't on the default branch yet. The user may know it's fine anyway, so it's their call.

**Set up the worktree.** Get the default branch from `gh repo view --json defaultBranchRef`, then run `git fetch origin`. Put the worktree next to the repo at `../<repo>.worktrees/<n>-<slug>`. `<repo>` is the name of the repo's top-level directory, and the slug is 2 to 5 words from the ticket title.

- If a worktree or branch for this ticket already exists, this is a **resume**. Look for a branch named `<n>-*` locally and on `origin`, and check `git worktree list`. Reuse the worktree, or add one for the existing branch. If git refuses because the main checkout has the branch checked out, stop and say so. Read the state file (section 2) to find the databases and ports this ticket already has. Then run setup (section 2) without creating anything twice, and restart the Preview on the same ports. Then work out where the run left off:
  - If the branch has an open PR (`gh pr list --head <branch> --state open`), the user is reviewing it. Go to Iteration (section 6).
  - Otherwise, sort the criteria (section 3) and compare them with the branch's commits and tests. Build what's missing. If nothing is, go to Iteration.
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

Apart from these and the cases in sections 3 and 4, don't interrupt the user. Decide everything else yourself, within what the ticket allows.

### Running commands

- **Keep browsers out of sight.** The user is working in their own browser while you run, so nothing you launch should open a window. Run browser tests headless and never pass headed or debug flags (`--headed`, `--debug`, `--browse`, `cypress open`). Where a runner is headed locally by default, as Vitest browser mode is, pass its headless flag. Launch test and dev-server commands with `BROWSER=none PLAYWRIGHT_HTML_OPEN=never`, so dev servers and test reports don't open a browser on their own.
- **Leave shared services alone.** Redis, queues and object storage are shared with the user's checkout and other sessions. Never run anything destructive on them (`FLUSHALL`, purging a queue, emptying a bucket), and never touch the user's own databases.
- **Keep your context small.** Send long test or server output to a file and read the failures and the tail. Use an Explore subagent for wide searches through the codebase.

## 3. Build

**Sort the criteria first.** Before writing code, decide how each acceptance criterion will be checked:

- **Test first:** behaviour where a bug would matter and could slip by unnoticed. That means business rules, validation, permissions, state changes, data integrity, API contracts and bug fixes. Test at the highest boundary that's still fast, usually an endpoint or integration test against the worktree's test database. One test can cover several criteria.
- **Browser check:** UI rendering and flows. Add an end-to-end test only when a flow carries real logic.
- **Nothing:** copy, styling, layout, wiring that a test above already exercises, and framework or config behaviour.

If the only test you could write would restate the code (asserting a constant string, asserting that a mock was called, snapshotting markup), don't write it. Tests like that cost time and catch nothing.

**Test-first behaviour**, one at a time:

1. Write the test. Take the expected values from the ticket or a worked example, never by computing them the way the code will, or the test agrees with whatever the code does.
2. Run it and check that it fails for the right reason. A test you never saw fail might not test anything. One that passes straight away usually means the test is wrong.
3. Write the least code that makes it pass. While you work, run the typechecker and the test file you're in, not the whole suite.
4. Commit.

Test behaviour through public interfaces (the exported function, the endpoint, the UI), not internals, so the tests still pass after later refactors. Don't write all the tests first and then all the code. Use what you learned in each cycle when you write the next test.

**Browser checks.** Once the UI for a criterion is built, open the Preview with the Playwright MCP tools, which run headless. Walk through the criterion, and check the console for errors. Don't use Claude in Chrome: it opens a new window in the user's Chrome for every session. If the Playwright tools aren't available, list those criteria under "Not checked" in the report.

**Changing tests.** Change an existing test only when the ticket changes the behaviour it checks, or for a mechanical update that keeps the same assertion, such as a renamed function or a moved route. Never loosen, skip or delete an assertion to get to green. That hides the bug from the reviewer instead of fixing it. If a test looks wrong for any other reason, stop and ask. Note every existing test you changed in the report.

**When something won't pass.** Rerun a failure once on its own. If it also fails on the baseline, or it's flaky, it isn't yours: note it under "Still red" and leave it. Never add sleeps or retries to make a test pass. Wait on a condition instead. After three failed attempts at the same failure, stop patching. Get a failure you can reproduce reliably, form one hypothesis, and test it. If you're still stuck, record it under "Still red" with what you tried, or ask the user if it blocks a criterion.

Stay inside the ticket. Don't fix neighbouring code, tidy up, or add behaviour the ticket doesn't ask for. Those changes make the PR harder to review, and cleanup belongs in review.

**Commits.** A test and the code that passes it go in one commit, so the type is usually `feat` or `fix`, not `test`. A prefactor ticket is `refactor`. Never rewrite history.

## 4. Gaps

If the ticket is unclear, or you hit a decision it doesn't make (for example what happens when a customer has no orders), stop and ask the user. Don't guess. This should be rare. It means `to-issues` missed something.

- **Small gap.** One answer settles it, and it needs no new term or ADR. Ask, then carry on with the answer. Offer to record the decision as a comment on the ticket, where the reviewer will see it. Show the user the comment first, and post it with `gh issue comment <n> --body-file <file>` only after they approve. Tell the user in one line that `to-issues` missed this.
- **Large gap.** It needs a new glossary term or an ADR, or it changes other tickets. Suggest stopping to grill it. Leave the worktree in place so a later run can resume.

## 5. Finish

1. **Self-check.** Spawn a read-only subagent and give it the ticket, the parent spec and `git diff origin/<default>...HEAD`. Ask it only whether the diff does what the ticket says: missing or partial criteria, criteria that look done but are wrong, scope creep, and failures that would go unnoticed. Leave style and quality out, because those belong to the review step. Fix the findings you agree with that are inside the ticket, the same way as in Build. A finding that's really a decision the ticket doesn't make is a gap (section 4). Keep a one-line reason for each finding you leave.
2. **Run the full test suite and linters** after your last edit, and fix what you broke. Read the output. A report built on an earlier run, or on "should pass", isn't worth anything.
3. **Push** with `git push -u origin <branch>`. Don't open a PR. The user iterates first and asks for the PR when they're happy (section 7).
4. **Open the Preview** for the user once, as a background tab in their browser: `open -g <url>` on macOS, `xdg-open <url>` on Linux. Don't open it again on Iterations or resumes.
5. **Report.** The user reads these between other sessions, so keep it fast to scan:

   ```markdown
   <1 to 3 lines on what changed, in glossary terms.>
   Preview: <url(s)>
   Tests: <n> passed, lint clean

   Decisions:
   - <A choice the ticket didn't dictate, and why.>
   Still red:
   - <A failing test or lint, with what you tried.>
   Not checked:
   - <criterion> (<why>)
   Tests changed:
   - <existing test>: <why>
   Self-check, left:
   - <finding>: <why you left it>
   ```

   Leave out every section with nothing in it. Usually only the first three lines remain. Don't add explanations around it.

Don't remove the worktree, branch, databases or Preview. They stay until the PR merges, so the user can keep iterating. After that, `delegate-prune` cleans them up.

## 6. Iteration

The session doesn't end at Finish. The user tries the Preview, looks at the branch or the PR, and gives feedback in this chat, often while running several sessions side by side. Each round of feedback is an Iteration.

- **Build it the same way.** Sort the change as in Build: risky behaviour gets a test first, and UI gets a browser check. Comments and commits follow the same rules.
- **Check, then push without asking.** Before each push, run the typechecker, the linters and the tests the change affects. Then commit and push. The branch should always match what the user sees in the Preview.
- **Beyond the ticket.** If the user asks for something the ticket doesn't cover, build it, since they asked, and keep it as a Decision for the PR.
- **Review comments.** When the PR exists and the user asks you to address its comments, read them with `gh pr view <n> --comments` and `gh api repos/{owner}/{repo}/pulls/<n>/comments`, and treat each as feedback. Don't reply on GitHub unless the user asks.
- **Unclear feedback.** Ask, since the user is right there. A request that changes other tickets or needs a new term is a large gap (section 4).
- **Once the PR exists,** keep its description true: update "Decisions", "Still red" and "Not checked" as things change with `gh pr edit <n> --body-file <file>`.

Keep the Preview running between Iterations. End each one with a line saying what changed, the test counts, and that it's pushed.

## 7. Opening the PR

Open the PR only when the user asks ("open the PR", or similar). That request is the confirmation, so don't show the description first.

1. **Run the full test suite and linters.** If anything is red, say what, and ask whether to open it anyway.
2. **Open it** with `gh pr create --base <default> --title "<title>" --body-file <file>`. It's a normal PR, not a draft.
3. **Title.** Use the commit format with the ticket's title as the description. "Show orders grouped by customer" becomes `feat: show orders grouped by customer`. Leave the ticket number out. `Closes #<n>` already links them, and a squash merge adds the PR number.
4. **Report** the PR link in one line.

### PR description

Keep it short. If the repo has a PR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, the same names in the root or `docs/`, or `.github/PULL_REQUEST_TEMPLATE/`), fill it in and follow its structure. Otherwise use:

```markdown
<1 to 3 lines on what changed, in glossary terms.>

## Decisions

- <A choice the ticket didn't dictate, including anything built beyond the ticket in Iteration, and why.>

## Still red

- <A failing test or lint.>

## Not checked

- <A criterion with no test and no browser check, and why.>

<One line on why it's large, only if the PR is much larger than usual for one ticket.>

Closes #<n>
```

Leave out every section with nothing in it. When you include Decisions, the reviewer needs to check those choices more than anything else in the PR.

### "To design" notice

After opening the PR, look at the parent spec's sub-issues. If this ticket is the only one still open and the spec has `Later:` items under Non-goals, tell the user:

> Once this merges, spec #41 is complete. Its Later items are:
>
> - <item>
> - <item>
