---
name: alibaba-code-review
description: AI-assisted code review workflow powered by Alibaba Open Code Review (ocr). Use after writing significant code changes, before git commit, or when requested to audit security and code quality.
---

# Alibaba Open Code Review (OCR) Workflow

When finishing a non-trivial code implementation or before committing git changes:
1. Run `ocr review` or `ocr scan` using your bash execution tool.
2. If `ocr` reports defects (NPE, thread safety, SQL injection, XSS, resource leaks):
   - Analyze the exact file and line locations reported by Alibaba OCR.
   - Automatically apply patches to eliminate the high-precision defects.
   - Re-run `ocr review` to confirm the review passes cleanly.
3. If no defects are found, proceed with git commit or report back to the user with a clean bill of health.
