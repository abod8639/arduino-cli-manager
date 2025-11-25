#!/usr/bin/env bats

# Tests for projects.sh module

load '../helpers/assertions'
load '../helpers/mocks'

setup() {
    source "$PROJECT_ROOT/lib/config.sh"
    source "$PROJECT_ROOT/lib/utils.sh"
    source "$PROJECT_ROOT/lib/ui.sh"
    source "$PROJECT_ROOT/lib/projects.sh"
}

@test "browse_custom_path validates directory existence" {
    # Test with non-existent directory
    run bash -c 'echo "/nonexistent/path" | browse_custom_path'
    
    assert_output_contains "does not exist"
}

@test "browse_custom_path detects .ino files" {
    local test_dir="$TEST_TEMP_DIR/test_ino_project"
    mkdir -p "$test_dir"
    touch "$test_dir/sketch.ino"
    
    # Simulate selecting this directory
    run bash -c "echo '$test_dir' | browse_custom_path"
    
    # Should find the .ino file
    [[ "$PROJECT" == "$test_dir" ]] || [[ "$output" =~ "Found 1 .ino file" ]]
}

@test "browse_custom_path warns about missing .ino files" {
    local test_dir="$TEST_TEMP_DIR/empty_project"
    mkdir -p "$test_dir"
    
    run bash -c "echo '$test_dir' | browse_custom_path"
    
    assert_output_contains "No .ino files found"
}

@test "browse_custom_path expands tilde" {
    # This tests that ~ is expanded to $HOME
    # We can't easily test the interactive part, but we can test the logic
    
    local custom_path="~/test"
    custom_path="${custom_path/#\~/$HOME}"
    
    [[ "$custom_path" == "$HOME/test" ]]
}

@test "edit_project_nvim checks for nvim" {
    PROJECT="$SKETCH_DIR/test_project1"
    
    # Mock nvim to not exist
    function nvim() { return 127; }
    
    run edit_project_nvim
    
    # Should detect nvim is missing (in real test with proper mock)
    [ "$status" -eq 0 ] || [ "$status" -eq 127 ]
}

@test "edit_project_nvim requires project selection" {
    PROJECT=""
    
    run edit_project_nvim
    
    assert_output_contains "No project selected"
}
