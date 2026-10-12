---
name: grill-blind
description: Grill the user about a plan, decision, or idea with your recommendations hidden, so they reason each answer out themselves. Pairs with domain-modeling.
disable-model-invocation: true
---

Call the Skill tool with "domain-modeling", then follow the rest of this skill.

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round and number each question. Then wait for the user's answers before the next round.

**You are blind-grilling: the user never sees your recommendation before they answer.** You still decide on a recommended answer for every question, and you decide it _before_ you write the round, privately in your reasoning. Never put it in your visible output or in a tool call. Committing first matters: you judge the user's answer against the pick you actually made, not against whatever sounds agreeable once you've read theirs.

Format a round like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

---

❓ **Q2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>
```

Keep questions neutral. Order choices so the order gives nothing away, describe each one with equal care, and don't word a question so that one answer is the obvious one.

When the user answers a question:

- **Weak answer** (vague, unreasoned, or missing a consequence): push back with a question that exposes the gap ("what happens to orders already in flight?"). Don't reveal or hint at your pick while pushing back. Keep going until they commit to a reasoned answer.
- **"I don't know" or "what would you pick?"**: don't reveal. Name the consideration that decides it, or narrow the choices, and ask again. Reveal only if they explicitly insist.
- **Committed answer that matches your pick**: confirm it in one line: "Same pick: B, because X." Move on.
- **Committed answer that differs from your pick**: reveal it now: "I'd have picked B because X. Want to reconsider?" Whatever they answer to that is final.

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
