# Copilot instructions

- The communication language for the project is **Hungarian**.

## Description

The repository is a small library of reusable Bash modules with no
application entry point.

## Project shape

- `doc/` contains documentation files.
- `res/` contains test resources and sample data used by the test suite.
- `lib/` contains sourceable helper modules only.
- `test/` contains Bash tests for the matching `lib/` modules and mirrors the
  same directory structure and filenames, with a `.test.sh` suffix.

## Dependency hierarchy

- Standalone helpers: `debug.sh`, `distro.sh`, `error_handler.sh`, `logger.sh`, `stack.sh`, `type.sh`, `unit_test.sh`.
- `lib/require.sh` -> `lib/distro.sh`, `lib/yaml_parser.sh`.
- `lib/yaml_parser.sh` -> `lib/type.sh`, `lib/stack.sh`.
- `lib/unit_test.sh` -> all test files.

## Key conventions

- Keep reusable code in `lib/` and put only corresponding tests in `test/`.
- Use `#!/bin/bash` as the shebang.
- Write POSIX-compliant code
- Document modules, methods, with comments to make code more undestandable.
- Cover each library module with tests, including edge cases and error handling.
- Do not propose new copilot instruction modifications only when you are
  explicitly are told to do so.
