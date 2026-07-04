---
description: This file contains instructions for testing the code.
applyTo: test/*.test.sh
---

## Conventions

- Match test paths to library paths exactly, including nested directories if new modules are added.
- Tests should source the library file under test plus `lib/unit_test.sh`,
- Tests should cover all the use cases of the library file under test, including edge cases and error handling.
- After creating a new test file, make it executable before finishing the change.

## Run the full test suite

```bash
chmod +x test/*.test.sh
for test_file in test/*.test.sh; do
  bash "$test_file"
done
```

## Run a single test

```bash
bash test/logger.test.sh
```
