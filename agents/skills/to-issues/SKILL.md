---
name: to-issues
description: Turn the idea shaped in this conversation (usually right after a grilling session) into a spec, published as a parent GitHub issue, plus vertical-slice tickets as its sub-issues. Reads the code to slice along real layers, settles any gaps that slicing exposes, and shows an outline and then the full text for approval before creating anything.
disable-model-invocation: true
---

# To Issues

This is the planning step of the user's workflow (`explore → shape → to-issues → drive | delegate → review`). By the time it runs, the user has already settled on an idea in this conversation. Your job is to turn that shared understanding into a **spec** and its **tickets** on GitHub. Write them so that whoever picks up a ticket, the user by hand or an agent, never has to guess what was meant.

An unclear ticket counts as a failure of this skill. If `delegate` ever has to stop and ask what a ticket means, this skill should have caught the gap.

## 1. Check you can start

Stop and say why if any of these fail. Each one would otherwise produce something you'd have to undo on GitHub.

- **Something was shaped.** The conversation must contain an idea the user has settled on, from a grilling session or similar. Don't plan from a thin or fresh conversation. You'd be inventing decisions that belong to the user. Tell them to shape the idea first.
- **There's a GitHub repo.** `gh auth status` and `gh repo view --json url,defaultBranchRef` both succeed.
- **The docs you'll link to are on GitHub.** The grilling session may have only just written `GLOSSARY.md` or ADRs in `docs/adr/`. If they have changes that aren't on the remote default branch, the spec's links would 404 and its terms would be undefined for anyone reading it. Ask the user to push first. Don't push yourself. Pushing is outward-facing, so the user does it.

## 2. Gather context

- **The conversation.** Collect the decisions, the alternatives the user rejected, the resolved terms, and anything ruled out or deferred.
- **The glossary and ADRs.** Read `GLOSSARY.md` (or `GLOSSARY-MAP.md` for multi-context repos) and the ADRs that touch this work. Write in the glossary's terms throughout. A missing glossary is fine, because shaping may not have needed new terms. In that case write in plain language and leave the link out.
- **The code the feature touches.** Find which layers the behaviour has to pass through and what already exists. Without this, "vertical slice" is a guess about layers that may not exist.

## 3. Draft the spec, then slice it

Write the spec first (template below), because you cut the tickets from it.

**Vertical slices.** Each ticket delivers a thin piece of working behaviour through every layer it needs (database, API, UI), so you can demo or test it on its own once it's merged. A ticket that covers one layer across the whole feature ("all the migrations") is never done by itself. Nothing works until its siblings land, and that's what makes PRs large and hard to review.

**Prefactor is the only exception.** A prefactor restructures existing code without changing behaviour, so a later slice becomes simple ("make the change easy, then make the easy change"). It blocks the slices that need it, and its acceptance criteria state that behaviour is unchanged.

**Size.** One ticket is roughly one PR. Small is the default because small PRs are fast to review, but there's no size budget. A ticket that needs to be large can be, and its PR will say why. A spec always gets at least one ticket, so `drive` and `delegate` can always find a parent spec.

**Blocking edges.** A ticket is blocked only by tickets it can't start without. Don't add an edge because one ticket feels like it comes first. Every extra edge serialises work that could run in parallel, for example several `delegate` runs alongside the user's own `drive`.

### Gaps

Slicing often exposes a decision nobody made. While drafting ticket 3, you might realise no one decided what happens when a customer has no orders. The grilling couldn't have caught it, because it only appears once you cut the work into tickets. Publish nothing while a gap is open. An open question in a ticket is exactly the ambiguity this skill exists to remove.

- **Small gap.** One answer settles it, and it needs no new glossary term and no ADR. Ask the user directly, then record the answer in the spec's `## Decisions`.
- **Large gap.** It needs a new term or an ADR, or it changes other decisions. Stop and suggest a grilling session, then re-run `to-issues`. Deciding it inline would skip the questioning a grilling session gives it.

Apart from gaps, don't interview the user again. The shaping is done, and your job is to write up what was decided.

## 4. Review: outline

Show the outline first. Granularity and dependencies are cheap to change now and expensive to change once the full text exists.

```
1. Extract order totals into one calculation   (prefactor)
   Blocked by: none
   Order totals come from a single place. Behaviour is unchanged.
2. Show orders grouped by customer
   Blocked by: 1
   The orders page lists orders under their customer's name.
3. Show orders with no customer under "Unassigned"
   Blocked by: 2
   Orders without a customer get their own group instead of disappearing.
```

Ask whether the granularity is right, whether each blocking edge is real, and whether anything should be merged or split. Iterate until the user approves.

## 5. Review: full text

Show the full spec and every ticket body, exactly as you'll publish them. The outline can't show a vague acceptance criterion, and acceptance criteria are where tickets usually go wrong. Say whether you'll create the `spec` label. Iterate until the user approves. Nothing goes to GitHub before this approval, because the user reviews anything outward-facing or created in bulk before it happens.

## 6. Publish

Get `<url>` and `<branch>` from `gh repo view --json url,defaultBranchRef`. Write each body to a temp file and pass it with `--body-file`, which avoids shell-quoting problems with Markdown.

1. If the `spec` label is missing, run `gh label create spec`.
2. Create the spec with `gh issue create --title "<title>" --label spec --body-file <file>`.
3. Create the tickets in dependency order, blockers first, so every blocker already has an issue number to point at:
   `gh issue create --title "<title>" --parent <spec> [--blocked-by <n>,<n>] --body-file <file>`

Keep a running map from outline number to issue number as you go. You need it to resume after a failure.

**If a step fails** (network, permissions, rate limit), stop. Report what you created, with links, and the error. Don't delete anything to "clean up", because you can't undo deleting an issue. When the user says continue, resume from the failed item and reuse the issue numbers you already created. A duplicate leaves the user cleaning up GitHub by hand.

## 7. Report

```
Spec: #41 Customer order history  <link>

1. #42 Extract order totals into one calculation   ← can start now
2. #43 Show orders grouped by customer              (blocked by #42)
3. #44 Show orders with no customer under "Unassigned"   (blocked by #43)
```

List the tickets in dependency order and mark the ones with no open blockers. Don't suggest which to pick. The user chooses the ticket, and whether to `drive` or `delegate` it, on the day.

## Spec template

Title: the feature's name, e.g. "Customer order history". The `spec` label marks it as a spec, so no title prefix is needed.

```markdown
## Problem
What's wrong or missing today, and for whom.

## Goals
What will be true when this is done.

## Non-goals
- Not doing: <deliberately excluded from scope>
- Later: <wanted, but deferred beyond this spec> (<why later>)

## Proposed solution
The behaviour, in glossary terms. Link to the glossary (<url>/blob/<branch>/GLOSSARY.md) instead of repeating definitions.

## Decisions
- <decision>. Considered: <alternatives and why not>. <ADR link, if one exists>
```

Keep **Not doing** and **Later** distinct. A non-goal is a scoping decision. A "Later" item is something the user still wants, and they'll come back to it once this spec's tickets are done. There's no Open questions section. Before you publish anything, every question is either a Decision or a Later item.

## Ticket template

Title: an imperative verb plus the outcome, e.g. "Show orders grouped by customer".

```markdown
## Context
One to three sentences on why. Part of #<spec>.

## What
The behaviour to add or change.

## Acceptance criteria
- [ ] <concrete, observable outcome that passes or fails>

## Notes
Constraints and decisions already made in the spec.
```

- **Acceptance criteria** are a plain checklist of observable outcomes, so a test or a person can check each one. Don't use Given/When/Then, user stories or story points. They add structure without making the criteria any clearer.
- **Leave out the "how".** Constraints and already-made decisions belong ("use the existing import job", "must not break the public API"). Step-by-step implementation and testing approach don't. Working those out is the implementer's job, and when the user implements by hand, it's the skill they're practising.
- **No file paths or code pointers.** The user's `drive` skill starts without hints on purpose, and a ticket saying "look in `src/orders/import.ts`" hands them one up front. Paths also go stale. Name an existing thing only when reusing it is a decision. Notes is optional, so omit it when it would be empty.
- **Record blocking only with GitHub's native dependencies** (`--blocked-by`), never as "Blocked by #12" in the body. The native links stay correct when issues close. Text in the body doesn't.
