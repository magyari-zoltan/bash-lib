---
description: This file contains instructions for writing bash scripts.
applyTo: lib/*.sh
---

## Conventions

- Every source file is guarded against multiple sourcing and returns early
  if already loaded.
- After creating a new script file, make it executable before finishing the
  change.
- Update script dependencies in `.github/copilot-instructions.md` whenever
  a new dependency is added into a script.
