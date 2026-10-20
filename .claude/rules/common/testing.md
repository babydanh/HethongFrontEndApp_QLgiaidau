# Testing Requirements

## Test Types

1. **Unit tests**: pure functions, utilities, components
2. **Integration tests**: API endpoints, database operations
3. **E2E tests**: critical user flows run on the cloud (`cloud-test-runner.py`). NEVER run Playwright or E2E locally on this machine.

## Project Rules

- New behaviour gets a test; a bug fix gets a regression test.
- Locally run only the tests related to the changed files (exact commands are in the repo AGENTS.md). Heavy suites go to the cloud.
- Structure tests as Arrange-Act-Assert, with names that state the behaviour: `returns empty array when no tournament matches query`.
- When a test fails, check isolation and mocks first. Fix the implementation, not the test, unless the test is wrong.
- No coverage percentage target. Do not add tests only to raise a number.
