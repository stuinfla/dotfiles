# Test Suite Documentation

## Overview

This directory contains comprehensive test suites for the dotfiles installation system, focusing on validating the installation process, progress visibility, and error handling.

## Test Files

### 1. test-installation.sh

**Purpose**: End-to-end testing of the complete codespace creation process

**Test Categories**:

#### File Presence Tests
- Verifies all expected files exist
- Checks script files, configuration files, and documentation
- Tests: 8 files validated

#### File Permission Tests
- Ensures all scripts are executable
- Validates proper file permissions
- Tests: 8 executable files checked

#### Configuration Validation Tests
- Validates JSON syntax in configuration files
- Checks for required fields in claude.json
- Tests: JSON parsing and field existence

#### Script Functionality Tests
- Tests status-update.sh functionality
- Validates error handling in setup scripts
- Tests: Script execution and error handling

#### Progress Visibility Tests
- Verifies VISIBLE_STATUS_FILE definition
- Checks update_status function exists
- Validates step indicator output
- Tests: 3 progress-related checks

#### Error Handling Tests
- Checks if scripts use `set -e`
- Validates error message format and clarity
- Tests: Error handling mechanisms

#### Documentation Tests
- Verifies existence of all documentation files
- Tests: README.md and docs/ files

#### Mock Environment Tests
- Simulates missing dependencies
- Tests graceful failure scenarios
- Tests: Dependency handling

**Usage**:
```bash
cd /Users/stuartkerr/Code/dotfiles-installer-1
chmod +x tests/test-installation.sh
./tests/test-installation.sh
```

**Expected Output**:
- Colored test results (green = pass, red = fail)
- Test summary with pass/fail counts
- Exit code 0 on success, 1 on failure

---

### 2. test-progress-visibility.sh

**Purpose**: Specialized testing for status file updates and terminal output clarity

**Test Categories**:

#### Status File Updates (Tests 1-5)
- **Test 1**: Status file creation on first update
- **Test 2**: Correct content in status file
- **Test 3**: Multiple update handling
- **Test 4**: Timestamp format validation
- **Test 5**: Step indicator presence

#### Terminal Output (Tests 6-8)
- **Test 6**: Proper output formatting
- **Test 7**: Concise output (no spam)
- **Test 8**: Error message visibility

#### Status File Location (Tests 9-10)
- **Test 9**: Correct directory location
- **Test 10**: Directory writability

#### Install Integration (Tests 11-12)
- **Test 11**: Install script sources status-update.sh
- **Test 12**: Setup scripts use update_status function

#### Progress Tracking (Tests 13-14)
- **Test 13**: Progress step tracking
- **Test 14**: Completion status recording

#### Error Visibility (Tests 15-16)
- **Test 15**: Error state prominence
- **Test 16**: Error message detail

#### Real-time Updates (Tests 17-18)
- **Test 17**: Immediate file writes
- **Test 18**: No buffering issues

**Usage**:
```bash
cd /Users/stuartkerr/Code/dotfiles-installer-1
chmod +x tests/test-progress-visibility.sh
./tests/test-progress-visibility.sh
```

**Expected Output**:
- 18 individual test results
- Real-time status file testing
- Preserved status file on failure for debugging

---

## Running All Tests

To run the complete test suite:

```bash
cd /Users/stuartkerr/Code/dotfiles-installer-1

# Make tests executable
chmod +x tests/*.sh

# Run installation tests
./tests/test-installation.sh

# Run progress visibility tests
./tests/test-progress-visibility.sh
```

## Test Results Interpretation

### Success Indicators
- ✓ Green checkmarks indicate passing tests
- Exit code 0 means all tests passed
- "All tests passed!" summary message

### Failure Indicators
- ✗ Red X marks indicate failing tests
- Exit code 1 means some tests failed
- Failed tests are listed in summary
- Status file preserved for debugging (progress tests)

## Continuous Integration

These tests are designed to be run in CI/CD pipelines:

### GitHub Actions Example
```yaml
name: Test Installation

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Installation Tests
        run: |
          chmod +x tests/test-installation.sh
          ./tests/test-installation.sh
      - name: Run Progress Visibility Tests
        run: |
          chmod +x tests/test-progress-visibility.sh
          ./tests/test-progress-visibility.sh
```

## Test Coverage

### What's Covered
- ✓ File existence and permissions
- ✓ Configuration file validity
- ✓ Script functionality
- ✓ Progress visibility mechanisms
- ✓ Error handling
- ✓ Status file updates
- ✓ Terminal output clarity
- ✓ Integration points

### What's Not Covered (Future Improvements)
- Network isolation testing (requires Docker)
- Full integration test in actual codespace
- Performance benchmarking
- Load testing with multiple concurrent installs
- Regression testing with previous versions

## Debugging Failed Tests

### Status File Location
When progress visibility tests fail, the status file is preserved at:
```
/workspaces/.codespaces/.persistedshare/VISIBLE_STATUS_FILE
```

### Common Issues

1. **File Permission Failures**
   - Ensure all scripts have executable permissions
   - Run: `chmod +x scripts/*.sh tests/*.sh`

2. **Configuration Validation Failures**
   - Check JSON syntax in config/claude.json
   - Validate required fields exist

3. **Status File Update Failures**
   - Verify directory permissions
   - Check that status-update.sh is sourced correctly

4. **Integration Failures**
   - Ensure all scripts source status-update.sh
   - Verify update_status function is called

## Test Development Guidelines

When adding new tests:

1. **Follow the existing pattern**:
   - Use helper functions (print_test, print_pass, print_fail)
   - Increment TESTS_RUN counter
   - Update pass/fail counters

2. **Provide clear test descriptions**:
   ```bash
   print_test "Testing specific functionality"
   ```

3. **Use appropriate assertions**:
   ```bash
   if [ condition ]; then
       print_pass "Description of success"
   else
       print_fail "Description of failure"
   fi
   ```

4. **Clean up after tests**:
   - Use trap for cleanup
   - Remove temporary files
   - Reset state when needed

5. **Document new tests**:
   - Update this README
   - Add comments in test scripts
   - Include usage examples

## Test Maintenance

### Regular Tasks
- Run tests before committing changes
- Update tests when adding new features
- Review failed tests in CI/CD pipeline
- Keep documentation synchronized with tests

### Version Updates
- Update test expectations when changing behavior
- Add new test categories for new features
- Remove obsolete tests
- Maintain backward compatibility when possible

## Contact & Support

For issues or questions about the test suite:
- Review test output for specific failure details
- Check the main README.md for general setup information
- Consult docs/ directory for architectural details
- Open an issue if tests fail unexpectedly

## Future Enhancements

Planned improvements to the test suite:

1. **Docker-based Integration Tests**
   - Full codespace simulation
   - Network isolation testing
   - Dependency testing

2. **Performance Benchmarks**
   - Installation time tracking
   - Resource usage monitoring
   - Comparison with baseline

3. **Automated Testing**
   - GitHub Actions integration
   - Pre-commit hooks
   - Scheduled regression tests

4. **Coverage Reporting**
   - Test coverage metrics
   - Code coverage analysis
   - Coverage trends over time

5. **Visual Regression Testing**
   - Terminal output validation
   - Screenshot comparison
   - UI consistency checks
