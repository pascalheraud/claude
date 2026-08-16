---
name: pyarmor
description: Code protection with PyArmor — obfuscation and distribution safeguards for Python application artifacts.
---

# PyArmor

## Core rules

- Apply PyArmor selectively to distribution-sensitive code, not as a substitute for good security boundaries.
- Apply it to the build artifacts that require protection, not to every local development run.
- Keep the protection workflow explicit and documented in the build pipeline.

## Typical workflow

```bash
pyarmor gen -r src/
```
