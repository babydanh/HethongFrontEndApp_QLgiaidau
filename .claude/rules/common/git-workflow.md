# Git Workflow

## Commit Message Format

```
<type>(<scope>): <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci.
Descriptions in this project are Vietnamese (history example: `chore(livestream): log lý do bỏ qua ...`); follow that.

## Project Rules

- NEVER add a `Co-Authored-By` trailer.
- Stage exact files only: `git add <file>`. Never `git add -A` or `git add .`.
- Work in a dedicated worktree: `git-wt switch -c <task> --base origin/main --no-cd -y` (skill `git-worktree-lanes`). Never `checkout`/`switch` in the main repo directory.
- Never run destructive git: `stash`, `reset --hard`, `clean`, `checkout -- <file>`, `restore` (except `--staged`), `branch -D`, `worktree remove --force`, `push`.
- Land work with `python C:/Users/GIGABYTE/.omp/scripts/merge-lane.py <worktree> --check "<check>"`. Never pass `--push` without explicit user approval (push to `main` deploys production).
