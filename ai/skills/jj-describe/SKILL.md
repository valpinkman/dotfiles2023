---
name: jj-describe
description: Update the description of the current jj revision (@)
---

# Update jj description

## Process

1. Get the diff for the current change: `jj diff -r @`
2. Compute a message following my standards
3. Use `jj describe` to update the description

## Message Format

Use a **gitmoji-style summary line**:

- `<gitmoji> (<scope>): <short, imperative summary>`

Where:

- **`<gitmoji>`**: expresses the intent (feature, fix, refactor, docs, chore, etc.).
- **`<scope>`**: the main area touched (e.g. `fish`, `jj`, `dotfiles`, `aerospace`, `brew`).
- **`<short, imperative summary>`**: what you did, in imperative mood.

Examples:

- `:sparkles: (jj): Add fuzzy finder to project switcher`
- `:bug: (fish): Fix config path on macOS`
- `:wrench: (aerospace): Update default workspace bindings`

Guidelines:

- Start with a **single gitmoji code** (e.g. `:sparkles:`, `:bug:`, `:recycle:`).
- Put the **scope immediately after the gitmoji/intent** wrapped in `()`, followed by a colon.
- Follow with a **concise, imperative summary** (no trailing period).
- Keep the summary under ~72 characters when possible.
- If you need more detail, add paragraphs after the first line, wrapped at a reasonable width.
