# Bash helper functions

The **bash-lib** is a collection of reusable Bash helper functions and scripts.
Its purpose is to simplify shell-based tasks and provide a consistent
foundation for command-line automation.

A collection of reusable functions that are well-written and thoroughly tested.
They eliminate the need to invest time and effort in rewriting the same
functionality for each new use case or worrying about its correctness.

## Usage

The intended method of use is as a **Git submodule**. The reason for separating it
into a dedicated repository is to enable the centralized development and
maintenance of reusable components, while allowing any desired version of the
library to be used across multiple projects.

## Directory Structure

- doc: Documentation related to the scripts, including system designs and other project documentation.
- lib: The reusable library code. This is the part intended to be used by other projects.
- res: Test resources and sample data used by the test suite.
- test: Tests written for the library code.
