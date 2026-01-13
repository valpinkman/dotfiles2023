# Agent Guidelines

## Version Control

Use **jj** over git when in a jj-enabled project. Fallback to git otherwise.

| Operation | jj command |
|---|---|
| Status | \`jj status\` |
| Diff | \`jj diff\` |
| Log | \`jj log\` |
| Set commit message | \`jj describe\` |
| New change | \`jj new\` |
| Create bookmark | \`jj bookmark set <name>\` |
| Track remote | \`jj bookmark track <name> --remote=<remote>\` |
| Fetch | \`jj git fetch\` |
| Push | \`jj git push\` |

### Commit Message Format

Gitmoji syntax: \`:intent: (scope): message\`

Examples:
- \`:sparkles: (auth): add login functionality\`
- \`:bug: (api): fix null pointer exception\`
- \`:memo: (readme): update installation instructions\`
- \`:refactor: (database): optimize query performance\`

## Documentation Lookups

Use **Context7 MCP** tools for library documentation:
- \`mcp__plugin_context7_context7__resolve-library-id\` to find the library ID
- \`mcp__plugin_context7_context7__query-docs\` to query docs and examples

Prefer this over web searches for programming library documentation.

## Post-Implementation

After completing implementation work, run the \`deslop\` skill to clean up AI-generated code. Use \`/deslop\` to automatically clean the current branch against main.

## General Principles

- **Match existing patterns** - Read surrounding code before writing. Follow the conventions already in the file and project (naming, structure, error handling).
- **Change only what was asked** - Do not refactor, reorganize, or "improve" code outside the scope of the task. Smaller diffs are easier to review and less risky.
- **Don't repeat yourself** - Extract shared logic into functions or modules. If the same pattern appears three times, it should be abstracted.
- **Keep it simple** - Prefer straightforward solutions over clever ones. Choose the approach that is easiest to read, test, and debug.
- **Test your changes** - Run existing tests after editing. Add tests for new behavior when a test suite exists.
- **Document decisions, not mechanics** - Comments should explain *why*, not *what*. Code should be self-explanatory for the *what*.
