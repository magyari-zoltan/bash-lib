---
name: bash-script-writing
description: This file contains instructions for writing 'bash scripts' intended
to be sourcable and reusable in other projects.
---

# Code structure

1. Start with a shebang.
2. After an empty line follows a description comment block.

- Short title like description
- Longer description of the module what it does.
- List of methods intended to be used by other modules.
- Internal methods should no be documented in the description block.
- Global variables which are intended to be used by other modules should also
  be documented in the description block.

3. Comes the guard against multiple sourcing.
4. Global variables with a comment describing their purpose, possible
   values, default value.
5. Methods intended to be used internally only by the module. Mark the
   beginning of the internal methods with the following comment block:

```txt
# ------------------------------------------------------------------------------
# Internal API: Functions intended for use within this library
# ------------------------------------------------------------------------------
```

6. Methods intended to be used by other modules. Mark the beginning of the public
   methods with the following comment block:

```txt
# ------------------------------------------------------------------------------
# Public API: Functions intended for external use
# ------------------------------------------------------------------------------
```

7. Implicit method calls that should happen when the module is sourced if it is
   the case
