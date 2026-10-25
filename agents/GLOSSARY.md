# Workflow

The language of my AI-assisted development workflow (see `WORKFLOW.md`): how an idea becomes planned, built, and reviewed work.

## Language

### Planning

**Spec**:
The parent GitHub issue holding a lightweight design doc for one piece of work: problem, goals, non-goals, proposed solution, decisions.
_Avoid_: PRD, epic, design doc

**Ticket**:
A sub-issue of a spec describing one unit of work, sized to roughly one PR.
_Avoid_: Task, story, card

**Vertical slice**:
A ticket that delivers a thin piece of working behaviour through every layer it needs, as opposed to one layer across many features.
_Avoid_: Tracer bullet, horizontal slice

**Prefactor**:
A ticket that restructures existing code without changing behaviour, so that a later vertical slice becomes simple. The only allowed exception to vertical slicing.
_Avoid_: Refactor ticket, cleanup

**Non-goal**:
Something a spec explicitly leaves out, marked either **Not doing** (excluded from scope) or **Later** (wanted, but deferred beyond this spec).
_Avoid_: Out of scope, open question

### Building

**Preview**:
The running app a `delegate` session serves from its worktree on its own port, so its work can be tried in a browser alongside other sessions' previews.
_Avoid_: Dev server, server, staging

**Iteration**:
A round of feedback the user gives a `delegate` session after its PR is open, which the session builds and pushes to the same PR.
_Avoid_: Revision, follow-up, review round
