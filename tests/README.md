# Testing Guide

## Overview

This project uses [bats-core](https://github.com/bats-core/bats-core) for automated testing.

## Test Structure

```
tests/
├── setup_suite.bash           # Global setup (runs once before all tests)
├── teardown_suite.bash        # Global cleanup (runs once after all tests)
├── helpers/
│   ├── mocks.bash            # Mock functions for external commands
│   └── assertions.bash       # Custom assertion helpers
├── unit/                      # Unit tests for individual modules
│   ├── test_config.bats
│   ├── test_utils.bats
│   ├── test_ui.bats
│   ├── test_projects.bats
│   ├── test_libraries.bats
│   └── test_arduino.bats
└── integration/               # Integration/workflow tests
    └── test_workflow.bats
```

## Installation

### Install bats

**Using npm:**
```bash
npm install -g bats
```

**Using Homebrew (macOS):**
```bash
brew install bats-core
```

**Or use Makefile:**
```bash
make install-test-deps
```

## Running Tests

### Run all tests
```bash
make test
```

### Run unit tests only
```bash
make test-unit
```

### Run integration tests only
```bash
make test-integration
```

### Run with verbose output
```bash
make test-verbose
```

### Run specific test file
```bash
make test-file FILE=tests/unit/test_config.bats
```

### Direct bats command
```bash
bats tests/unit/test_config.bats
```

## Test Coverage

### Config Module (`test_config.bats`)
- ✓ Version variable validation
- ✓ Default values verification
- ✓ Color codes definition
- ✓ Directory paths validation

### Utils Module (`test_utils.bats`)
- ✓ Version comparison logic
- ✓ Config save/load functionality
- ✓ Malicious config rejection
- ✓ Project backup creation
- ✓ Backup rotation (keeps last 5)
- ✓ Operation logging
- ✓ Log rotation

### UI Module (`test_ui.bats`)
- ✓ Logo display
- ✓ Header rendering
- ✓ Version display
- ✓ Update notifications
- ✓ Help menu content

### Projects Module (`test_projects.bats`)
- ✓ Custom path validation
- ✓ .ino file detection
- ✓ Path expansion (~)
- ✓ nvim availability check

### Libraries Module (`test_libraries.bats`)
- ✓ Function existence verification

### Arduino Module (`test_arduino.bats`)
- ✓ Function existence verification
- ✓ Project requirement validation

### Integration Tests (`test_workflow.bats`)
- ✓ Module loading
- ✓ Config save/load workflow
- ✓ Backup and logging workflow
- ✓ Version comparison
- ✓ Function availability

## Writing Tests

### Basic Test Structure

```bash
#!/usr/bin/env bats

load '../helpers/assertions'
load '../helpers/mocks'

setup() {
    # Runs before each test
    source "$PROJECT_ROOT/lib/config.sh"
}

@test "description of test" {
    run some_function
    
    assert_success
    assert_output_contains "expected text"
}
```

### Available Assertions

- `assert_var_set "VAR_NAME"` - Variable is set
- `assert_equals "expected" "actual"` - Values are equal
- `assert_file_exists "path"` - File exists
- `assert_dir_exists "path"` - Directory exists
- `assert_output_contains "text"` - Output contains text
- `assert_function_exists "func"` - Function is defined
- `assert_success` - Command succeeded (status=0)
- `assert_failure` - Command failed (status≠0)
- `assert_output_matches "regex"` - Output matches regex

### Mock Functions

Mock functions are available for:
- `arduino-cli` - Simulates arduino-cli commands
- `fzf` - Returns first line of input
- `nvim` - No-op editor
- `fd` - Directory listing
- `curl` - GitHub API responses
- `jq` - JSON parsing

## CI/CD Integration

Tests can be integrated into CI/CD pipelines:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install bats
        run: npm install -g bats
      - name: Run tests
        run: make test
```

## Troubleshooting

### Tests fail with "command not found"
- Ensure bats is installed: `which bats`
- Install with: `make install-test-deps`

### Mock functions not working
- Check that `mocks.bash` is loaded: `load '../helpers/mocks'`
- Verify functions are exported in mocks.bash

### Tests hang or timeout
- Check for interactive prompts in code
- Ensure mocks are properly simulating user input

## Contributing

When adding new features:
1. Write tests first (TDD approach)
2. Ensure all tests pass: `make test`
3. Add integration tests for workflows
4. Update this documentation

## Resources

- [bats-core documentation](https://bats-core.readthedocs.io/)
- [Bash testing best practices](https://github.com/bats-core/bats-core#writing-tests)
