---
name: cibuildwheel
description: Wheel build automation with cibuildwheel — multi-platform Python wheel builds, CI-friendly packaging, and artifact generation.
---

# Cibuildwheel

## Core rules

- Configure the list of supported platforms and Python versions explicitly (`[tool.cibuildwheel]` in `pyproject.toml`, or `--platform`/`--output-dir` flags), rather than leaving it to the tool's defaults.
- Run cibuildwheel in CI or a dedicated build job — a full multi-platform build is not meant to run as part of a local dev loop.

## Typical workflow

```bash
cibuildwheel --platform linux
```
