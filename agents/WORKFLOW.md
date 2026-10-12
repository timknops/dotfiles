# Workflow

How I build software with AI. I'm a student heading into a junior role, so the goal is to write most of the code myself: real skill comes from writing code by hand. AI helps me shape ideas, plan work, and review, and writes code when I explicitly choose to delegate.

## Principles

1. **My workflow, not someone else's.** Borrow from existing skills (e.g. Matt Pocock's), but every stage should fit how I work, not drive me blind through someone else's process.
2. **Confirm before outward-facing or bulk actions.** Anything on GitHub (creating issues, opening PRs, posting comments, pushing) or anything that creates many things at once is shown to me first. Local, reversible actions (branches, worktrees, edits inside `delegate`, running tests) just happen. Exception: `delegate` opens its PR without asking, since that PR is where I review its work.
3. **Small PRs are the default, not a law.** A ticket that truly grows large has a reason; the PR description states it in one line. No size budgets on tickets.
4. **Tests are part of done.** A ticket isn't finished until its behaviour is tested. Acceptance criteria map onto test cases.

## Pipeline

```
explore ──► shape ──► to-issues ──► drive | delegate ──► review
```

### 1. Explore

Diverge before there's an idea: generate angles, related problems, what already exists. The opposite mode of grilling, which converges.

- **Skill:** source an existing one rather than writing my own. Look when I get to this stage.

### 2. Shape

Converge on one idea until there's a shared understanding.

- **`grill-with-docs`**: `grilling` + `domain-modeling`. Terms land in `GLOSSARY.md` and decisions in ADRs (`docs/adr/`) as they crystallise.
- **`grill-blind`** (experiment): a copy of `grilling` that keeps its recommendations hidden, so I have to reason each answer out myself. It still pushes back on weak answers. After I commit to an answer, it always reveals its own pick: a one-line confirmation when we match, or "I'd have picked B because X. Want to reconsider?" when we don't. Paired with `domain-modeling`. The original `grilling` stays untouched so upstream updates remain easy to pull in.

### 3. Plan: `to-issues`

One skill turns the shared understanding in the current conversation into a spec plus tickets on GitHub. It stops if nothing was shaped in this session.

- **Reads the code** the feature touches, so slices follow the real layers.
- **Gaps found while slicing:** small ones it asks me directly and records under Decisions; large ones (a new term, an ADR) send me back to grilling. Nothing is published with an open question.
- **Two review steps** before anything is created: an outline (titles, blocking edges, one line each), then the full text.
- **Partial failure:** stops, reports what was created, and resumes on request without duplicating.
- **Afterwards:** lists the tickets in dependency order, marking the ones that can start now. Which one to pick is my call.

**Spec** = parent GitHub issue with the `spec` label. A lightweight design doc:

```
## Problem
## Goals
## Non-goals           (each marked "Not doing:" or "Later:")
## Proposed solution   (behaviour, in GLOSSARY.md terms)
## Decisions           (with alternatives considered; ADR links where relevant)
```

Uses `GLOSSARY.md` terms and links to it rather than repeating definitions.

**Tickets** = sub-issues of the spec (`gh issue create --parent <spec>`).

- **Vertical slices:** each ticket is a thin piece of working behaviour through every layer it needs (DB → API → UI), never a horizontal layer ("all migrations"). The only exception is a **prefactor**: restructuring with no behaviour change, so a later slice becomes simple.
- **Blocking:** GitHub's native dependencies only (`--blocked-by` / `--blocking`), not "Blocked by #12" in the body.
- **Format:** conventional, no ceremony (no user stories, no story points):

```
Title: imperative + outcome, e.g. "Show orders grouped by customer"

## Context
1–3 sentences on why. Part of #<spec>.

## What
The behaviour to add or change.

## Acceptance criteria
- [ ] Concrete, checkable outcomes

## Notes (optional)
Constraints, existing things to reuse (when reusing them is a decision), already-made decisions from the spec.
```

- **"How" in tickets:** constraints and already-made decisions belong ("use the existing import job", "must not break the public API"). Step-by-step implementation does not: working out the approach is the implementer's job, and it's the skill `drive` exists to build. Same for file paths and testing approach.
- **Acceptance criteria:** a plain checklist of observable, pass/fail outcomes.
- **One ticket ≈ one PR** by default.

### 4. Build: `drive` | `delegate`

I pick a ticket from GitHub, then decide the mode on the day. Mode is never stored on the ticket.

**Shared start and finish:**

- Start: take an issue number or URL, read the ticket, its parent spec, and `GLOSSARY.md`; create a branch.
- Finish: open a PR with `Closes #<n>`. Add a one-line justification if the PR is notably large.
- **To design:** when a PR closes a spec's last open ticket and the spec still has `Later:` non-goals, tell me. (Possibly a GitHub Action instead.)

**`drive`**: I write the code.

| Level | Name | What it gives |
|---|---|---|
| 0 | Silent | Answers direct questions and checks my work when asked. Volunteers nothing. |
| 1 | Nudge | A guiding question ("what happens when the list is empty?"). |
| 2 | Pointer | The concept to look up, or the file and docs to read. |
| 3 | Shape | The approach or pseudocode, without real code. |
| 4 | Snippet | Actual code, shown in chat for me to type. |

- Starts at **level 0** every session. Only I change it ("more", "level 3", "back to 0"); it never escalates on its own. The level is sticky until I change it.
- General-knowledge questions (an API, syntax, a concept) always get a full answer. Questions about this ticket's solution are capped at the current level.
- "Check my work" says what's wrong and where, never the fix. Fix help follows the level. Level 4 covers only the piece I'm stuck on.
- **One exception to silence:** a one-line warning for security problems or irreversible data loss (committing a secret, a destructive command). Never for bugs.
- When I explicitly tell it to write something, it edits the files directly, scoped to exactly what I named, then hands control back.
- **I commit**, not the skill (unless I tell it to). It never rewrites history. From level 1 up it comments in one line on weak commit messages.
- **No attribution** in commits or PRs: the work is mine.
- The PR is opened only when I say I'm done. First it runs tests and linters and maps each acceptance criterion to a test, reporting failures and gaps without fixing them (I can override explicitly). Then it shows me the PR description.
- Test-first is neither enforced nor encouraged for now (see Open experiments). Tests must exist by PR time.
- **Ticketless mode:** `/drive` with no ticket uses the current conversation as the brief, for work too small for a ticket. Same coaching; "done" just runs tests and linters, and a PR opens only if I ask.

**`delegate`**: the agent writes the code.

- Works in its own **git worktree**, so several `delegate` runs can go in parallel while I `drive` in the main checkout. The worktree is removed when it's done.
- Writes tests first (tentative).
- Runs the tests and linters before opening the PR.
- If the ticket is unclear, it stops and asks rather than guessing. That should never happen: an unclear ticket means `to-issues` fell short, so I fix the process upstream.
- Opens its PR without asking (Principle 2).
- **Known issue:** parallel runs may share stateful resources (test database, ports, caches) and collide. Solve this per project when building `delegate` (e.g. a test database per worktree).

### 5. Review

One review skill for every PR, whoever wrote it (me, `delegate`, anyone else).

- **Output depends on context:** to the terminal when I run it, as PR comments when it runs automatically (e.g. a future GitHub Action on every new PR). The review logic is the same either way.
- **Explain-it-back** (experiment, opt-in, manual runs only): before merging, it asks me 2–3 questions about the PR to check that I actually understand what's going in. Most valuable on `delegate` PRs.

## Skills

My own skills live in `~/dotfiles/agents/skills` and are symlinked into `~/.claude/skills`. Third-party skills (installed via the skills CLI) live in `~/.agents/skills`.

| Skill | Status |
|---|---|
| `grilling`, `grill-with-docs`, `domain-modeling` | Installed (Matt Pocock) |
| `grill-blind` | To build (1) |
| `to-issues` | To build (2) |
| `drive` | Built, untested (3) |
| review | To build (4) (name TBD) |
| `delegate` | To build (5) |
| explore | To source (6) |

Build one at a time, testing each on real work before moving on.

## Open experiments

- **`grill-blind`:** does reasoning without seeing recommendations make me sharper, or just slower?
- **Test-first in `drive`:** try TDD versus tests-after and see which helps me learn testing.
- **Test-first in `delegate`:** the tentative default; keep or drop.
- **Large-PR justification line:** drop it if it adds no value.
- **Explain-it-back:** does it actually catch gaps in my understanding?

## Parked ideas

- **Learning log:** after each ticket, note what tripped me up, so `drive` adapts its help over time.
- **PR split skill:** help break up a PR that has grown too large. Only if large PRs keep happening.
