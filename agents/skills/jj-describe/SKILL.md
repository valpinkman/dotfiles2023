---
name: jj-describe
description: Update the description of the current jj revision (@)
---

# Update jj description

## Process

1. Get the diff against main:
  - if in jujutsu enabled repo: `jj diff -r 'main..@'`
  - otherwise: `git diff main...HEAD`
2. Compute a message following my standards
3. Use `jj describe` to update the description
