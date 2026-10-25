# Memory

Never add, change or delete memory (files in `~/.claude/projects/*/memory/`) without asking me first. Show me the exact text you want to save or remove, and wait for my yes. This includes writes through shell commands, not just the Write/Edit tools.

# Code comments

Write no comments by default. Let good naming explain the code. Add a comment only when it tells the reader something the code can't, such as why a non-obvious workaround exists or a constraint from outside the code. Never write comments that restate the code, narrate the change ("added for #43") or label sections.

# Commits

Use [Conventional Commits](https://www.conventionalcommits.org/) in the form `<type>: <description>`, with the description in lowercase imperative. The type comes from what the change does: `feat` for new behaviour, `fix` for a bug, `refactor` for a change that keeps behaviour the same. Add a scope only if the repo's log already uses scopes, and mark a breaking change with `!` only when it really breaks something. If the project's `CLAUDE.md` or `AGENTS.md` asks for a different commit format, follow that instead.
