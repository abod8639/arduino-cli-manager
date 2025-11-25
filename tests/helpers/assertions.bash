#!/usr/bin/env bash

# Custom assertion helpers for tests

# Assert that a variable is set
assert_var_set() {
    local var_name="$1"
    local var_value="${!var_name}"
    
    if [[ -z "$var_value" ]]; then
        echo "FAIL: Variable '$var_name' is not set"
        return 1
    fi
    return 0
}

# Assert that a variable equals expected value
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$expected" != "$actual" ]]; then
        echo "FAIL: Expected '$expected' but got '$actual'"
        [[ -n "$message" ]] && echo "  $message"
        return 1
    fi
    return 0
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "FAIL: File does not exist: $file"
        return 1
    fi
    return 0
}

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        echo "FAIL: Directory does not exist: $dir"
        return 1
    fi
    return 0
}

# Assert that output contains string
assert_output_contains() {
    local expected="$1"
    
    if [[ ! "$output" =~ $expected ]]; then
        echo "FAIL: Output does not contain '$expected'"
        echo "  Output was: $output"
        return 1
    fi
    return 0
}

# Assert that a function exists
assert_function_exists() {
    local func_name="$1"
    
    if ! declare -F "$func_name" > /dev/null; then
        echo "FAIL: Function '$func_name' does not exist"
        return 1
    fi
    return 0
}

# Assert that command succeeds
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "FAIL: Command failed with status $status"
        echo "  Output: $output"
        return 1
    fi
    return 0
}

# Assert that command fails
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "FAIL: Command succeeded but was expected to fail"
        return 1
    fi
    return 0
}

# Assert line count
assert_line_count() {
    local expected="$1"
    local actual="${#lines[@]}"
    
    if [[ "$expected" -ne "$actual" ]]; then
        echo "FAIL: Expected $expected lines but got $actual"
        return 1
    fi
    return 0
}

# Assert that output matches regex
assert_output_matches() {
    local pattern="$1"
    
    if [[ ! "$output" =~ $pattern ]]; then
        echo "FAIL: Output does not match pattern '$pattern'"
        echo "  Output was: $output"
        return 1
    fi
    return 0
}
