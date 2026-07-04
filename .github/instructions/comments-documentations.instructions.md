---
description: This file contains instructions regarding commenting in bash scripts.
applyTo: **/*.sh
---

- Document complicated steps. Don't comment every single line.
  Groupd more instructions / lines by their common intention
  and add a comment above the group.
- All documentation, comments, and code should be written in
  English.
- All tests in `test/` uses the shared `lib/unit_test.sh`
  harness, and CI runs every `test/*.test.sh` script on both
  Debian and Arch containers.
