---
name: create-pull-request
description: Create a GitHub pull request following project conventions. Use when the user asks to create a PR, submit changes for review, or open a pull request. Supports Jujutsu (jj) and Git workflows, preferring jj when available. Uses the gh CLI tool for PR creation.
---

# Create Pull Request

This skill guides you through creating a well-structured GitHub pull request that follows project conventions and best practices.

## Prerequisites Check

Before proceeding, verify the following:

### 1. Detect VCS — Jujutsu or Git

```bash
jj root 2>/dev/null && echo "VCS=jj" || echo "VCS=git"
```

If `jj root` succeeds, use **Jujutsu** commands throughout. Otherwise fall back to **Git**.

> Throughout this document, commands are shown as **jj** first, then **git** fallback.

### 2. Check if `gh` CLI is installed

```bash
gh --version
```

If not installed, inform the user:
> The GitHub CLI (`gh`) is required but not installed. Please install it:
> - macOS: `brew install gh`
> - Other: https://cli.github.com/

### 3. Check if authenticated with GitHub

```bash
gh auth status
```

If not authenticated, guide the user to run `gh auth login`.

### 4. Verify clean working directory

**jj:**
```bash
jj st
```

If there are uncommitted changes in the working copy, they are automatically part of the current change in jj. Ask the user whether to:
- Include them in the current change (default — jj tracks them automatically)
- Move them to a new change with `jj new`

**git fallback:**
```bash
git status
```

If there are uncommitted changes, ask the user whether to:
- Commit them as part of this PR
- Stash them temporarily
- Discard them (with caution)

## Gather Context

### 1. Identify the current branch / bookmark

**jj:**
```bash
jj log -r @ --no-graph -T 'bookmarks'
```

If no bookmark is set on `@`, create one before pushing:
```bash
jj bookmark create <branch-name> -r @
```

Ensure the bookmark is not `main`. If the user is working directly on main, ask them to create a new change and bookmark.

**git fallback:**
```bash
git branch --show-current
```

Ensure you're not on `main` or `master`. If so, ask the user to create or switch to a feature branch.

### 2. Find the base branch

**jj:**
```bash
jj log -r 'heads(remote_bookmarks())' --no-graph -T 'bookmarks ++ "\n"'
```

The base is typically `main@origin`.

**git fallback:**
```bash
git remote show origin | grep "HEAD branch"
```

This is typically `main` or `master`.

### 3. Analyze recent changes relevant to this PR

**jj:**
```bash
jj log -r 'main..@'
```

Review these changes to understand:
- What changes are being introduced
- The scope of the PR (single feature/fix or multiple changes)
- Whether changes should be squashed or reorganized

**git fallback:**
```bash
git log origin/main..HEAD --oneline --no-decorate
```

### 4. Review the diff

**jj:**
```bash
jj diff -r 'main..@' --stat
```

**git fallback:**
```bash
git diff origin/main..HEAD --stat
```

This shows which files changed and helps identify the type of change.

## Information Gathering

Before creating the PR, you need the following information. Check if it can be inferred from:
- Change descriptions / commit messages
- Bookmark / branch name (e.g., `fix/issue-123`, `feature/new-login`)
- Changed files and their content

If any critical information is missing, use `ask_followup_question` to ask the user:

### Required Information

1. **Related Issue Number**: Look for patterns like `#123`, `fixes #123`, or `closes #123` in change descriptions / commit messages
2. **Description**: What problem does this solve? Why were these changes made?
3. **Type of Change**: Bug fix, new feature, breaking change, refactor, cosmetic, documentation, or workflow
4. **Test Procedure**: How was this tested? What could break?

### Example clarifying question

If the issue number is not found:
> I couldn't find a related issue number in the change descriptions or bookmark name. What GitHub issue does this PR address? (Enter the issue number, e.g., "123" or "N/A" for small fixes)

## VCS Best Practices

Before creating the PR, consider these best practices:

### Change / Commit Hygiene

1. **Atomic changes**: Each change/commit should represent a single logical change
2. **Clear descriptions**: Follow conventional commit format when possible
3. **Clean history**: Prefer rebasing over merging to keep history clean

### History Cleanup

**jj:**

1. **Squash if appropriate**: If there are many small WIP changes:
   ```bash
   jj squash
   ```
   This moves the current change into its parent. For squashing specific changes:
   ```bash
   jj squash --from <change-id> --into <target-id>
   ```

2. **Rebase on latest main** (if needed):
   ```bash
   jj git fetch
   jj rebase -d main
   ```

3. **Use absorb** to automatically distribute fixup changes into the right commits in your stack:
   ```bash
   jj absorb
   ```

**git fallback:**

1. **Rebase on latest main** (if needed):
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Squash if appropriate**: If there are many small "WIP" commits, consider interactive rebase:
   ```bash
   git rebase -i origin/main
   ```
   Only suggest this if commits appear messy and the user is comfortable with rebasing.

### Push Changes

**jj:**

Ensure a bookmark exists and push it:
```bash
jj git push --bookmark <branch-name>
```

If the bookmark doesn't exist yet:
```bash
jj bookmark create <branch-name> -r @
jj git push --bookmark <branch-name>
```

If pushing after a rebase, jj handles force-push automatically when the bookmark has moved.

**git fallback:**

Ensure all commits are pushed:
```bash
git push origin HEAD
```

If the branch was rebased, you may need:
```bash
git push origin HEAD --force-with-lease
```

## Create the Pull Request

### 1. Determine the PR body format

Check whether the repository provides a PR template:

```bash
# Common template locations, in priority order
cat .github/pull_request_template.md 2>/dev/null \
  || cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null \
  || cat docs/pull_request_template.md 2>/dev/null \
  || cat PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

**If a template exists:** use it as-is. The PR body must **strictly match** the template structure — do not add, remove, or reorder sections. Fill every section with information gathered from the changes/commits and context. Replace placeholders (e.g. `#XXXX`) with actual values when available.

**If no template exists:** write the PR body following these best practices:

```markdown
## What

<!-- One-paragraph summary of the change. -->

## Why

<!-- Motivation: issue link, bug report, product requirement. -->
<!-- Use "Closes #123" or "Fixes #123" to auto-link issues. -->

## How

<!-- Key implementation details, trade-offs, anything a reviewer should know. -->

## Testing

<!-- How was this validated? Manual steps, automated tests, screenshots. -->
```

Keep sections concise. Omit "Testing" only if the change is pure documentation or config.

### 2. Create PR with gh CLI

**Use a temporary file for the PR body** to avoid shell escaping issues, newline problems, and other command-line flakiness:

1. Write the PR body to a temporary file:
   ```
   /tmp/pr-body.md
   ```

2. Create the PR using the file:
   ```bash
   gh pr create --title "PR_TITLE" --body-file /tmp/pr-body.md --base main
   ```

3. Clean up the temporary file:
   ```bash
   rm /tmp/pr-body.md
   ```

For draft PRs:
```bash
gh pr create --title "PR_TITLE" --body-file /tmp/pr-body.md --base main --draft
```

**Why use a file?** Passing complex markdown with newlines, special characters, and checkboxes directly via `--body` is error-prone. The `--body-file` flag handles all content reliably.

## Post-Creation

After creating the PR:

1. **Display the PR URL** so the user can review it
2. **Remind about CI checks**: Tests and linting will run automatically
3. **Suggest next steps**:
   - Add reviewers if needed: `gh pr edit --add-reviewer USERNAME`
   - Add labels if needed: `gh pr edit --add-label "bug"`

## Error Handling

### Common Issues

1. **No changes ahead of main**: The branch/bookmark has no changes to submit
   - Ask if the user meant to work on a different change/branch

2. **Branch/bookmark not pushed**: Remote doesn't have the branch
   - **jj:** `jj bookmark create <name> -r @ && jj git push --bookmark <name>`
   - **git:** `git push -u origin HEAD`

3. **PR already exists**: A PR for this branch already exists
   - Show the existing PR: `gh pr view`
   - Ask if they want to update it instead

4. **Merge conflicts**: Branch conflicts with base
   - **jj:** `jj rebase -d main` then `jj resolve` for conflicts
   - **git:** Guide user through resolving conflicts or rebasing

5. **No bookmark set (jj only)**: Working copy has no bookmark
   - Create one: `jj bookmark create <branch-name> -r @`

## Summary Checklist

Before finalizing, ensure:
- [ ] VCS detected (jj preferred, git fallback)
- [ ] `gh` CLI is installed and authenticated
- [ ] Working directory is clean
- [ ] All changes/commits are pushed
- [ ] Bookmark/branch is up-to-date with base branch
- [ ] Related issue number is identified, or placeholder is used
- [ ] PR description follows the repo template if one exists, otherwise uses What/Why/How/Testing format
