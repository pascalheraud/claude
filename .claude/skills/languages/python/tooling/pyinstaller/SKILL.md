---
name: pyinstaller
description: Application packaging with PyInstaller — building standalone Python executables and desktop or service artifacts.
---

# PyInstaller

## Core rules

- Reserve PyInstaller for standalone app builds, not as the default project dependency installation method.
- Keep the entry point and packaging configuration explicit and reviewable.
- Separate development environment from packaged distribution configuration.

## Typical workflow

```bash
pyinstaller --onefile app/main.py
```
