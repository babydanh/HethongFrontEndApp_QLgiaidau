# Code Review Standards

## When to Review

- After writing or modifying code, before committing
- When auth, payments, user data, file system, or database queries change
- Before merge: checks pass and the branch is up to date with `origin/main`

## Review Checklist

- [ ] Code is readable and well-named
- [ ] Functions are focused (<50 lines); files stay under the 800-line soft ceiling or the exception is justified
- [ ] No deep nesting (>4 levels); errors are handled explicitly
- [ ] No hardcoded secrets or credentials; no `console.log` or debug output left behind
- [ ] New behaviour has tests; the related tests pass
- [ ] Input validation, response envelope, and pagination follow the repo's AGENTS.md

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| CRITICAL | Security vulnerability or data-loss risk | BLOCK: fix before merge |
| HIGH | Bug or significant quality issue | WARN: fix before merge |
| MEDIUM | Maintainability concern | Consider fixing |
| LOW | Style or minor suggestion | Optional |

## Security Review Triggers

Review by hand before committing when changing: authentication or authorization, user input handling, database queries, file system operations, external API calls, cryptography, or payment code.

## Common Issues to Catch

- Security: hardcoded credentials, SQL built by string concatenation, unescaped user input, unsanitized file paths, missing CSRF protection, authentication bypass
- Quality: functions over 50 lines, large files, missing error handling, mutation where an immutable update is equally simple
- Performance: N+1 queries, list endpoints without pagination or limits, expensive work without caching
