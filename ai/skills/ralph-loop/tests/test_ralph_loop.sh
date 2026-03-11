#!/usr/bin/env bash
# Unit tests for ralph-loop.sh
# Run with: ./test_ralph_loop.sh

set -euo pipefail

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_LOOP="$SCRIPT_DIR/../scripts/ralph-loop.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
TMP_DIR=""

# Setup and teardown
setup() {
    TMP_DIR=$(mktemp -d)
    # Copy fixtures to temp dir for modification
    cp -r "$FIXTURES_DIR"/* "$TMP_DIR/" 2>/dev/null || true
}

teardown() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}

# Test helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo -e "${RED}ASSERTION FAILED${NC}: $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_contains() {
    local needle="$1"
    local haystack="$2"
    local message="${3:-}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo -e "${RED}ASSERTION FAILED${NC}: $message"
        echo "  Expected to contain: $needle"
        echo "  Actual: $haystack"
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local haystack="$2"
    local message="${3:-}"

    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        echo -e "${RED}ASSERTION FAILED${NC}: $message"
        echo "  Expected NOT to contain: $needle"
        echo "  Actual: $haystack"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"

    if [[ -f "$file" ]]; then
        return 0
    else
        echo -e "${RED}ASSERTION FAILED${NC}: $message"
        return 1
    fi
}

run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  Testing: $test_name... "

    setup

    if $test_func; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    teardown
}

# Source the script functions (without running main)
# We'll test individual functions by sourcing with a mock
source_functions() {
    # Create a mock that prevents main from running
    PRD_FILE=""

    # Source just the functions we need to test
    # Extract function definitions from the script
    eval "$(sed -n '/^get_git_workflow()/,/^}/p' "$RALPH_LOOP")"
    eval "$(sed -n '/^get_branch_strategy()/,/^}/p' "$RALPH_LOOP")"
    eval "$(sed -n '/^get_parent_branch()/,/^}/p' "$RALPH_LOOP")"
    eval "$(sed -n '/^deps_satisfied()/,/^}/p' "$RALPH_LOOP")"
    eval "$(sed -n '/^get_next_task()/,/^}/p' "$RALPH_LOOP")"
    eval "$(sed -n '/^get_task_field()/,/^}/p' "$RALPH_LOOP")"
    eval "$(sed -n '/^extract_branch_name()/,/^}/p' "$RALPH_LOOP")"
    eval "$(sed -n '/^extract_pr_url()/,/^}/p' "$RALPH_LOOP")"
    eval "$(sed -n '/^get_hook()/,/^}/p' "$RALPH_LOOP")"
    eval "$(sed -n '/^increment_task_attempts()/,/^}/p' "$RALPH_LOOP")"

    # Source log functions (needed by evaluate_condition)
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1"; }
}

# Source build_prompt function (multi-line)
source_build_prompt() {
    source_functions

    local in_function=0
    local brace_count=0
    local func_content=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^build_prompt\(\) ]]; then
            in_function=1
        fi
        if [[ $in_function -eq 1 ]]; then
            func_content+="$line"$'\n'
            local open_braces=$(echo "$line" | tr -cd '{' | wc -c)
            local close_braces=$(echo "$line" | tr -cd '}' | wc -c)
            brace_count=$((brace_count + open_braces - close_braces))
            if [[ $brace_count -eq 0 && ${#func_content} -gt 20 ]]; then
                break
            fi
        fi
    done < "$RALPH_LOOP"

    eval "$func_content"
}

# Source additional functions for hooks and exit conditions testing
source_hook_functions() {
    source_functions

    # Extract evaluate_condition function (multi-line with case statement)
    local in_function=0
    local brace_count=0
    local func_content=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^evaluate_condition\(\) ]]; then
            in_function=1
        fi
        if [[ $in_function -eq 1 ]]; then
            func_content+="$line"$'\n'
            # Count braces
            local open_braces=$(echo "$line" | tr -cd '{' | wc -c)
            local close_braces=$(echo "$line" | tr -cd '}' | wc -c)
            brace_count=$((brace_count + open_braces - close_braces))
            if [[ $brace_count -eq 0 && ${#func_content} -gt 20 ]]; then
                break
            fi
        fi
    done < "$RALPH_LOOP"

    eval "$func_content"

    # Extract evaluate_exit_conditions
    in_function=0
    brace_count=0
    func_content=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^evaluate_exit_conditions\(\) ]]; then
            in_function=1
        fi
        if [[ $in_function -eq 1 ]]; then
            func_content+="$line"$'\n'
            local open_braces=$(echo "$line" | tr -cd '{' | wc -c)
            local close_braces=$(echo "$line" | tr -cd '}' | wc -c)
            brace_count=$((brace_count + open_braces - close_braces))
            if [[ $brace_count -eq 0 && ${#func_content} -gt 20 ]]; then
                break
            fi
        fi
    done < "$RALPH_LOOP"

    eval "$func_content"
}

#
# Test: get_git_workflow
#
test_get_git_workflow_default() {
    source_functions
    local result
    result=$(get_git_workflow "$TMP_DIR/minimal.yaml")
    assert_equals "vanilla" "$result" "Default git_workflow should be vanilla"
}

test_get_git_workflow_graphite() {
    source_functions
    local result
    result=$(get_git_workflow "$TMP_DIR/graphite_stacked.yaml")
    assert_equals "graphite" "$result" "Should read graphite from yaml"
}

test_get_git_workflow_vanilla_explicit() {
    source_functions
    local result
    result=$(get_git_workflow "$TMP_DIR/vanilla_independent.yaml")
    assert_equals "vanilla" "$result" "Should read vanilla from yaml"
}

#
# Test: get_branch_strategy
#
test_get_branch_strategy_default() {
    source_functions
    local result
    result=$(get_branch_strategy "$TMP_DIR/minimal.yaml")
    assert_equals "independent" "$result" "Default branch_strategy should be independent"
}

test_get_branch_strategy_stacked() {
    source_functions
    local result
    result=$(get_branch_strategy "$TMP_DIR/graphite_stacked.yaml")
    assert_equals "stacked" "$result" "Should read stacked from yaml"
}

test_get_branch_strategy_independent() {
    source_functions
    local result
    result=$(get_branch_strategy "$TMP_DIR/vanilla_independent.yaml")
    assert_equals "independent" "$result" "Should read independent from yaml"
}

#
# Test: get_parent_branch (independent strategy)
#
test_get_parent_branch_independent_always_base() {
    source_functions
    local result
    # For independent strategy, should always return base_branch regardless of deps
    result=$(get_parent_branch "$TMP_DIR/vanilla_independent.yaml" "task-2")
    assert_equals "main" "$result" "Independent strategy should always use base_branch"
}

test_get_parent_branch_independent_first_task() {
    source_functions
    local result
    result=$(get_parent_branch "$TMP_DIR/vanilla_independent.yaml" "task-1")
    assert_equals "main" "$result" "First task should use base_branch"
}

#
# Test: get_parent_branch (stacked strategy)
#
test_get_parent_branch_stacked_first_task() {
    source_functions
    local result
    result=$(get_parent_branch "$TMP_DIR/graphite_stacked.yaml" "task-1")
    assert_equals "main" "$result" "First task in stack should use base_branch"
}

test_get_parent_branch_stacked_with_dep() {
    source_functions
    # First, simulate task-1 being done with a branch
    yq -i '(.tasks[] | select(.id == "task-1")).status = "done"' "$TMP_DIR/graphite_stacked.yaml"
    yq -i '(.tasks[] | select(.id == "task-1")).result.branch_name = "feature-task-1"' "$TMP_DIR/graphite_stacked.yaml"

    local result
    result=$(get_parent_branch "$TMP_DIR/graphite_stacked.yaml" "task-2")
    assert_equals "feature-task-1" "$result" "Stacked task should use parent's branch"
}

test_get_parent_branch_stacked_dep_not_done() {
    source_functions
    local result
    # task-2 depends on task-1, but task-1 is not done yet
    result=$(get_parent_branch "$TMP_DIR/graphite_stacked.yaml" "task-2")
    assert_equals "main" "$result" "Should fallback to base_branch if dep not done"
}

#
# Test: deps_satisfied
#
test_deps_satisfied_no_deps() {
    source_functions
    if deps_satisfied "$TMP_DIR/graphite_stacked.yaml" "task-1"; then
        return 0
    else
        echo "Task with no deps should be satisfied"
        return 1
    fi
}

test_deps_satisfied_dep_pending() {
    source_functions
    # task-2 depends on task-1, which is pending
    if deps_satisfied "$TMP_DIR/graphite_stacked.yaml" "task-2"; then
        echo "Task with pending dep should NOT be satisfied"
        return 1
    else
        return 0
    fi
}

test_deps_satisfied_dep_done() {
    source_functions
    # Mark task-1 as done
    yq -i '(.tasks[] | select(.id == "task-1")).status = "done"' "$TMP_DIR/graphite_stacked.yaml"

    if deps_satisfied "$TMP_DIR/graphite_stacked.yaml" "task-2"; then
        return 0
    else
        echo "Task with done dep should be satisfied"
        return 1
    fi
}

#
# Test: get_next_task (independent strategy)
#
test_get_next_task_independent_first() {
    source_functions
    local result
    result=$(get_next_task "$TMP_DIR/vanilla_independent.yaml")
    assert_equals "task-1" "$result" "Should return first pending task"
}

test_get_next_task_independent_second() {
    source_functions
    # Mark first task as done
    yq -i '(.tasks[] | select(.id == "task-1")).status = "done"' "$TMP_DIR/vanilla_independent.yaml"

    local result
    result=$(get_next_task "$TMP_DIR/vanilla_independent.yaml")
    assert_equals "task-2" "$result" "Should return second task after first is done"
}

test_get_next_task_independent_all_done() {
    source_functions
    # Mark all tasks as done
    yq -i '(.tasks[]).status = "done"' "$TMP_DIR/vanilla_independent.yaml"

    local result
    result=$(get_next_task "$TMP_DIR/vanilla_independent.yaml")
    assert_equals "" "$result" "Should return empty when all tasks done"
}

#
# Test: get_next_task (stacked strategy)
#
test_get_next_task_stacked_respects_deps() {
    source_functions
    local result
    # task-2 depends on task-1, so should return task-1 first
    result=$(get_next_task "$TMP_DIR/graphite_stacked.yaml")
    assert_equals "task-1" "$result" "Should return first task (no deps)"
}

test_get_next_task_stacked_blocked() {
    source_functions
    # Mark task-1 as in_progress, task-2 should be blocked
    yq -i '(.tasks[] | select(.id == "task-1")).status = "in_progress"' "$TMP_DIR/graphite_stacked.yaml"

    local result
    result=$(get_next_task "$TMP_DIR/graphite_stacked.yaml")
    assert_equals "" "$result" "Should return empty when all tasks blocked"
}

test_get_next_task_stacked_unblock() {
    source_functions
    # Mark task-1 as done
    yq -i '(.tasks[] | select(.id == "task-1")).status = "done"' "$TMP_DIR/graphite_stacked.yaml"

    local result
    result=$(get_next_task "$TMP_DIR/graphite_stacked.yaml")
    assert_equals "task-2" "$result" "Should return task-2 after task-1 is done"
}

#
# Test: extract_branch_name
#
test_extract_branch_name_gt_create() {
    source_functions
    local output="Some output
Created branch: feature-branch-123
More output"
    local result
    result=$(extract_branch_name "$output")
    assert_equals "feature-branch-123" "$result" "Should extract branch from gt create output"
}

test_extract_branch_name_on_branch() {
    source_functions
    local output="On branch my-feature-branch
nothing to commit"
    local result
    result=$(extract_branch_name "$output")
    assert_equals "my-feature-branch" "$result" "Should extract branch from git status"
}

test_extract_branch_name_checkout_b() {
    source_functions
    local output="Switched to a new branch
git checkout -b new-feature
Branch created"
    local result
    result=$(extract_branch_name "$output")
    assert_equals "new-feature" "$result" "Should extract branch from git checkout -b"
}

test_extract_branch_name_none() {
    source_functions
    local output="No branch info here
Just some random output"
    local result
    result=$(extract_branch_name "$output")
    assert_equals "" "$result" "Should return empty when no branch found"
}

#
# Test: extract_pr_url
#
test_extract_pr_url_found() {
    source_functions
    local output="Created PR: https://github.com/owner/repo/pull/123
Some other output"
    local result
    result=$(extract_pr_url "$output")
    assert_equals "https://github.com/owner/repo/pull/123" "$result" "Should extract PR URL"
}

test_extract_pr_url_none() {
    source_functions
    local output="No PR URL here"
    local result
    result=$(extract_pr_url "$output")
    assert_equals "" "$result" "Should return empty when no PR URL"
}

#
# Test: CLI argument parsing (--status, --stack, --help)
#
test_cli_status_flag() {
    local output
    output=$("$RALPH_LOOP" --status "$TMP_DIR/minimal.yaml" 2>&1) || true
    assert_contains "PRD Status" "$output" "Status flag should show PRD status"
}

test_cli_stack_flag() {
    local output
    output=$("$RALPH_LOOP" --stack "$TMP_DIR/minimal.yaml" 2>&1) || true
    assert_contains "Completed Work" "$output" "Stack flag should show completed work"
}

test_cli_help_flag() {
    local output
    output=$("$RALPH_LOOP" --help 2>&1) || true
    assert_contains "Usage:" "$output" "Help flag should show usage"
    assert_contains "git_workflow" "$output" "Help should mention git_workflow"
    assert_contains "branch_strategy" "$output" "Help should mention branch_strategy"
}

test_cli_missing_file() {
    local output
    local exit_code=0
    output=$("$RALPH_LOOP" "/nonexistent/file.yaml" 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        assert_contains "not found" "$output" "Should error on missing file"
        return 0
    else
        echo "Should exit with error on missing file"
        return 1
    fi
}

test_cli_no_args() {
    local output
    local exit_code=0
    output=$("$RALPH_LOOP" 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        assert_contains "Missing required argument" "$output" "Should error on no args"
        return 0
    else
        echo "Should exit with error on no args"
        return 1
    fi
}

#
# Test: PRD validation
#
test_validate_invalid_yaml() {
    # Create invalid YAML
    echo "invalid: yaml: content:" > "$TMP_DIR/invalid.yaml"

    local output
    local exit_code=0
    output=$("$RALPH_LOOP" --status "$TMP_DIR/invalid.yaml" 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        assert_contains "Invalid YAML" "$output" "Should detect invalid YAML"
        return 0
    else
        echo "Should exit with error on invalid YAML"
        return 1
    fi
}

test_validate_missing_name() {
    # Create YAML without name
    cat > "$TMP_DIR/no_name.yaml" << 'EOF'
description: Missing name field
tasks: []
EOF

    local output
    local exit_code=0
    output=$("$RALPH_LOOP" --status "$TMP_DIR/no_name.yaml" 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        assert_contains "missing required field: name" "$output" "Should detect missing name"
        return 0
    else
        echo "Should exit with error on missing name"
        return 1
    fi
}

#
# Test: Status display with different configurations
#
test_status_shows_workflow() {
    local output
    output=$("$RALPH_LOOP" --status "$TMP_DIR/graphite_stacked.yaml" 2>&1) || true
    assert_contains "graphite" "$output" "Status should show git workflow"
    assert_contains "stacked" "$output" "Status should show branch strategy"
}

test_status_shows_task_list() {
    local output
    output=$("$RALPH_LOOP" --status "$TMP_DIR/vanilla_independent.yaml" 2>&1) || true
    assert_contains "task-1" "$output" "Status should list task-1"
    assert_contains "task-2" "$output" "Status should list task-2"
}

#
# Test: get_hook (global and task-specific)
#
test_get_hook_global() {
    source_functions
    local result
    result=$(get_hook "$TMP_DIR/with_hooks.yaml" "task-without-hooks" "pre_task")
    assert_contains "Global pre-task" "$result" "Should get global hook for task without override"
}

test_get_hook_task_override() {
    source_functions
    local result
    result=$(get_hook "$TMP_DIR/with_hooks.yaml" "task-with-hooks" "pre_task")
    assert_contains "Custom pre-task" "$result" "Should get task-specific hook when defined"
}

test_get_hook_no_hook() {
    source_functions
    local result
    result=$(get_hook "$TMP_DIR/minimal.yaml" "task-1" "pre_task")
    assert_equals "" "$result" "Should return empty when no hook defined"
}

test_get_hook_on_complete() {
    source_functions
    local result
    result=$(get_hook "$TMP_DIR/with_hooks.yaml" "" "on_complete")
    assert_contains "All tasks done" "$result" "Should get on_complete hook"
}

test_get_hook_on_failure() {
    source_functions
    local result
    result=$(get_hook "$TMP_DIR/with_hooks.yaml" "" "on_failure")
    assert_contains "failed" "$result" "Should get on_failure hook"
}

#
# Test: evaluate_condition (command type)
#
test_evaluate_condition_command_success() {
    source_hook_functions
    local condition='{"type": "command", "run": "true", "expect": "success"}'
    if evaluate_condition "$TMP_DIR/minimal.yaml" "task-1" "$condition" >/dev/null 2>&1; then
        return 0
    else
        echo "Command 'true' should succeed"
        return 1
    fi
}

test_evaluate_condition_command_failure_expected() {
    source_hook_functions
    local condition='{"type": "command", "run": "false", "expect": "failure"}'
    if evaluate_condition "$TMP_DIR/minimal.yaml" "task-1" "$condition" >/dev/null 2>&1; then
        return 0
    else
        echo "Command 'false' with expect=failure should pass"
        return 1
    fi
}

test_evaluate_condition_command_fails() {
    source_hook_functions
    local condition='{"type": "command", "run": "false", "expect": "success"}'
    if evaluate_condition "$TMP_DIR/minimal.yaml" "task-1" "$condition" >/dev/null 2>&1; then
        echo "Command 'false' with expect=success should fail"
        return 1
    else
        return 0
    fi
}

#
# Test: evaluate_condition (file_exists type)
#
test_evaluate_condition_file_exists_pass() {
    source_hook_functions
    # Create a test file
    touch "$TMP_DIR/test_file.txt"
    local condition="{\"type\": \"file_exists\", \"path\": \"$TMP_DIR/test_file.txt\"}"
    pushd "$TMP_DIR" > /dev/null
    if evaluate_condition "$TMP_DIR/minimal.yaml" "task-1" "$condition" >/dev/null 2>&1; then
        popd > /dev/null
        return 0
    else
        popd > /dev/null
        echo "File exists condition should pass for existing file"
        return 1
    fi
}

test_evaluate_condition_file_exists_fail() {
    source_hook_functions
    local condition='{"type": "file_exists", "path": "/nonexistent/file.txt"}'
    if evaluate_condition "$TMP_DIR/minimal.yaml" "task-1" "$condition" >/dev/null 2>&1; then
        echo "File exists condition should fail for missing file"
        return 1
    else
        return 0
    fi
}

#
# Test: evaluate_exit_conditions (multiple conditions)
#
test_evaluate_exit_conditions_empty() {
    source_hook_functions
    # Task with no exit conditions should pass
    if evaluate_exit_conditions "$TMP_DIR/with_exit_conditions.yaml" "task-no-conditions" >/dev/null 2>&1; then
        return 0
    else
        echo "Empty exit conditions should pass"
        return 1
    fi
}

test_evaluate_exit_conditions_command_pass() {
    source_hook_functions
    # Create a README.md for the test
    touch "$TMP_DIR/README.md"
    pushd "$TMP_DIR" > /dev/null
    if evaluate_exit_conditions "$TMP_DIR/with_exit_conditions.yaml" "task-command-condition" >/dev/null 2>&1; then
        popd > /dev/null
        return 0
    else
        popd > /dev/null
        echo "Command condition with existing README.md should pass"
        return 1
    fi
}

#
# Test: evaluate_condition error output capture
#
test_evaluate_condition_captures_error_output() {
    source_hook_functions
    local condition='{"type": "command", "run": "echo failure-message && false", "expect": "success"}'
    local output
    output=$(evaluate_condition "$TMP_DIR/minimal.yaml" "task-1" "$condition" 2>&1)
    # Should contain the error details
    assert_contains "Exit condition failed" "$output" "Should output error details"
    assert_contains "failure-message" "$output" "Should include command output"
}

test_evaluate_condition_file_not_found_error() {
    source_hook_functions
    local condition='{"type": "file_exists", "path": "/nonexistent/path/*.txt"}'
    local output
    output=$(evaluate_condition "$TMP_DIR/minimal.yaml" "task-1" "$condition" 2>&1)
    assert_contains "Exit condition failed" "$output" "Should output error details"
    assert_contains "file not found" "$output" "Should mention file not found"
}

#
# Test: increment_task_attempts
#
test_increment_task_attempts() {
    source_functions
    # Get initial attempts
    local initial
    initial=$(yq -r '.tasks[0].attempts' "$TMP_DIR/minimal.yaml")
    assert_equals "0" "$initial" "Initial attempts should be 0"

    # Increment
    increment_task_attempts "$TMP_DIR/minimal.yaml" "task-1"

    local after
    after=$(yq -r '.tasks[0].attempts' "$TMP_DIR/minimal.yaml")
    assert_equals "1" "$after" "Attempts should be 1 after increment"

    # Increment again
    increment_task_attempts "$TMP_DIR/minimal.yaml" "task-1"

    local after2
    after2=$(yq -r '.tasks[0].attempts' "$TMP_DIR/minimal.yaml")
    assert_equals "2" "$after2" "Attempts should be 2 after second increment"
}

#
# Test: build_prompt (new functionality)
#
test_build_prompt_basic() {
    source_build_prompt
    local result
    result=$(build_prompt "$TMP_DIR/minimal.yaml" "task-1")
    # Should contain the task prompt
    assert_contains "TASK:" "$result" "Should contain TASK section"
    assert_contains "COMPLETION REQUIREMENTS:" "$result" "Should contain completion requirements"
    # Should NOT contain hardcoded git instructions (removed in redesign)
    assert_not_contains "git checkout main" "$result" "Should not contain hardcoded checkout instruction"
    assert_not_contains "Git Workflow:" "$result" "Should not contain git workflow instructions"
}

test_build_prompt_no_hardcoded_git_workflow() {
    source_build_prompt
    local result
    result=$(build_prompt "$TMP_DIR/graphite_stacked.yaml" "task-1")
    # Should NOT contain graphite-specific instructions (user prompt controls this now)
    assert_not_contains "gt create" "$result" "Should not contain gt create instruction"
    assert_not_contains "Graphite CLI" "$result" "Should not mention Graphite CLI"
}

test_build_prompt_branch_continuity() {
    source_build_prompt
    # Set up a task with an existing branch from previous attempt
    yq -i '(.tasks[] | select(.id == "task-1")).result.branch_name = "feature-existing-branch"' "$TMP_DIR/minimal.yaml"
    yq -i '(.tasks[] | select(.id == "task-1")).attempts = 1' "$TMP_DIR/minimal.yaml"

    local result
    result=$(build_prompt "$TMP_DIR/minimal.yaml" "task-1")

    assert_contains "CONTINUE ON EXISTING BRANCH: feature-existing-branch" "$result" "Should tell Claude to continue on existing branch"
    assert_contains "git checkout feature-existing-branch" "$result" "Should include checkout command for existing branch"
}

test_build_prompt_retry_with_error() {
    source_build_prompt
    # Set up a retry scenario with last_error
    yq -i '(.tasks[] | select(.id == "task-1")).attempts = 1' "$TMP_DIR/minimal.yaml"
    yq -i '(.tasks[] | select(.id == "task-1")).last_error = "Tests failed: 3 errors found"' "$TMP_DIR/minimal.yaml"

    local result
    result=$(build_prompt "$TMP_DIR/minimal.yaml" "task-1")

    assert_contains "RETRY ATTEMPT 2" "$result" "Should indicate retry attempt number"
    assert_contains "Error details:" "$result" "Should include error details section"
    assert_contains "Tests failed: 3 errors found" "$result" "Should include the actual error message"
}

test_build_prompt_branch_continuity_with_error() {
    source_build_prompt
    # Set up both existing branch AND error
    yq -i '(.tasks[] | select(.id == "task-1")).result.branch_name = "feature-retry-branch"' "$TMP_DIR/minimal.yaml"
    yq -i '(.tasks[] | select(.id == "task-1")).attempts = 2' "$TMP_DIR/minimal.yaml"
    yq -i '(.tasks[] | select(.id == "task-1")).last_error = "Exit condition failed: command failed"' "$TMP_DIR/minimal.yaml"

    local result
    result=$(build_prompt "$TMP_DIR/minimal.yaml" "task-1")

    # Should have both branch continuity AND error context
    assert_contains "CONTINUE ON EXISTING BRANCH: feature-retry-branch" "$result" "Should have branch continuity"
    assert_contains "RETRY ATTEMPT 3" "$result" "Should have retry attempt"
    assert_contains "Exit condition failed" "$result" "Should include error message"
}

test_build_prompt_simplified_completion_requirements() {
    source_build_prompt
    local result
    result=$(build_prompt "$TMP_DIR/minimal.yaml" "task-1")

    # Should have simplified requirements (no hardcoded git workflow mention)
    assert_contains "Follow any git instructions in the task prompt" "$result" "Should reference task prompt for git instructions"
    assert_contains "Ensure all work is committed" "$result" "Should mention committing work"
    # Should NOT have old requirements
    assert_not_contains "following the git workflow above" "$result" "Should not reference 'git workflow above'"
    assert_not_contains "Report the branch name" "$result" "Should not ask to report branch name"
}

#
# Main test runner
#
main() {
    echo ""
    echo "========================================"
    echo "Ralph Loop Unit Tests"
    echo "========================================"
    echo ""

    # Check dependencies
    if ! command -v yq &> /dev/null; then
        echo -e "${RED}ERROR: yq is required for tests${NC}"
        exit 1
    fi

    echo "Testing: get_git_workflow"
    run_test "default workflow" test_get_git_workflow_default
    run_test "graphite workflow" test_get_git_workflow_graphite
    run_test "explicit vanilla workflow" test_get_git_workflow_vanilla_explicit
    echo ""

    echo "Testing: get_branch_strategy"
    run_test "default strategy" test_get_branch_strategy_default
    run_test "stacked strategy" test_get_branch_strategy_stacked
    run_test "independent strategy" test_get_branch_strategy_independent
    echo ""

    echo "Testing: get_parent_branch (independent)"
    run_test "independent always uses base" test_get_parent_branch_independent_always_base
    run_test "independent first task" test_get_parent_branch_independent_first_task
    echo ""

    echo "Testing: get_parent_branch (stacked)"
    run_test "stacked first task" test_get_parent_branch_stacked_first_task
    run_test "stacked with dep done" test_get_parent_branch_stacked_with_dep
    run_test "stacked dep not done" test_get_parent_branch_stacked_dep_not_done
    echo ""

    echo "Testing: deps_satisfied"
    run_test "no dependencies" test_deps_satisfied_no_deps
    run_test "dependency pending" test_deps_satisfied_dep_pending
    run_test "dependency done" test_deps_satisfied_dep_done
    echo ""

    echo "Testing: get_next_task (independent)"
    run_test "first task" test_get_next_task_independent_first
    run_test "second task" test_get_next_task_independent_second
    run_test "all done" test_get_next_task_independent_all_done
    echo ""

    echo "Testing: get_next_task (stacked)"
    run_test "respects dependencies" test_get_next_task_stacked_respects_deps
    run_test "blocked by in_progress" test_get_next_task_stacked_blocked
    run_test "unblocked after done" test_get_next_task_stacked_unblock
    echo ""

    echo "Testing: extract_branch_name"
    run_test "gt create output" test_extract_branch_name_gt_create
    run_test "on branch output" test_extract_branch_name_on_branch
    run_test "checkout -b output" test_extract_branch_name_checkout_b
    run_test "no branch found" test_extract_branch_name_none
    echo ""

    echo "Testing: extract_pr_url"
    run_test "PR URL found" test_extract_pr_url_found
    run_test "no PR URL" test_extract_pr_url_none
    echo ""

    echo "Testing: CLI arguments"
    run_test "--status flag" test_cli_status_flag
    run_test "--stack flag" test_cli_stack_flag
    run_test "--help flag" test_cli_help_flag
    run_test "missing file" test_cli_missing_file
    run_test "no arguments" test_cli_no_args
    echo ""

    echo "Testing: PRD validation"
    run_test "invalid YAML" test_validate_invalid_yaml
    run_test "missing name" test_validate_missing_name
    echo ""

    echo "Testing: Status display"
    run_test "shows workflow config" test_status_shows_workflow
    run_test "shows task list" test_status_shows_task_list
    echo ""

    echo "Testing: get_hook"
    run_test "global hook" test_get_hook_global
    run_test "task override hook" test_get_hook_task_override
    run_test "no hook defined" test_get_hook_no_hook
    run_test "on_complete hook" test_get_hook_on_complete
    run_test "on_failure hook" test_get_hook_on_failure
    echo ""

    echo "Testing: evaluate_condition (command)"
    run_test "command success" test_evaluate_condition_command_success
    run_test "command expect failure" test_evaluate_condition_command_failure_expected
    run_test "command fails" test_evaluate_condition_command_fails
    echo ""

    echo "Testing: evaluate_condition (file_exists)"
    run_test "file exists pass" test_evaluate_condition_file_exists_pass
    run_test "file exists fail" test_evaluate_condition_file_exists_fail
    echo ""

    echo "Testing: evaluate_exit_conditions"
    run_test "empty conditions" test_evaluate_exit_conditions_empty
    run_test "command condition pass" test_evaluate_exit_conditions_command_pass
    echo ""

    echo "Testing: evaluate_condition error capture"
    run_test "captures error output" test_evaluate_condition_captures_error_output
    run_test "file not found error" test_evaluate_condition_file_not_found_error
    echo ""

    echo "Testing: increment_task_attempts"
    run_test "increment attempts" test_increment_task_attempts
    echo ""

    echo "Testing: build_prompt"
    run_test "basic prompt structure" test_build_prompt_basic
    run_test "no hardcoded git workflow" test_build_prompt_no_hardcoded_git_workflow
    run_test "branch continuity" test_build_prompt_branch_continuity
    run_test "retry with error" test_build_prompt_retry_with_error
    run_test "branch continuity with error" test_build_prompt_branch_continuity_with_error
    run_test "simplified completion requirements" test_build_prompt_simplified_completion_requirements
    echo ""

    # Summary
    echo "========================================"
    echo "Test Results"
    echo "========================================"
    echo "Tests run:    $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}SOME TESTS FAILED${NC}"
        exit 1
    else
        echo -e "${GREEN}ALL TESTS PASSED${NC}"
        exit 0
    fi
}

main "$@"
