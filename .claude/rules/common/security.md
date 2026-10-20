# Security Guidelines

## Mandatory Security Checks

Before ANY commit:
- [ ] No hardcoded secrets (API keys, passwords, tokens, private keys)
- [ ] All user inputs validated at the boundary
- [ ] SQL injection prevention (parameterized queries or the ORM's query builder)
- [ ] XSS prevention (no unescaped HTML from users)
- [ ] CSRF protection and authentication/authorization verified where the change touches them
- [ ] Error messages do not leak sensitive data

## Secret Management

- NEVER hardcode secrets in source code.
- NEVER read, print, copy, or commit `.env*` files, credentials, or key files. `.env.example` is only a template.
- Read configuration from environment variables; fail fast at startup when a required variable is missing.
- If a secret may have been exposed, stop and tell the user so it can be rotated.

## Security Response Protocol

If a security issue is found:
1. STOP the current change.
2. Review the affected code path by hand.
3. Fix CRITICAL issues before continuing.
4. Report exposed secrets to the user for rotation.
5. Check the rest of the codebase for the same pattern.
