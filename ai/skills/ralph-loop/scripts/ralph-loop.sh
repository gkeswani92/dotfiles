#!/usr/bin/env bash
set -euo pipefail

# Configuration
MAX_GLOBAL_RETRIES="${MAX_GLOBAL_RETRIES:-10}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }
log_task() { echo -e "${CYAN}[TASK]${NC} $1"; }

# Show warning and get user confirmation
confirm_execution() {
    echo ""
    echo -e "${YELLOW}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│                        WARNING                               │${NC}"
    echo -e "${YELLOW}├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${YELLOW}│${NC} This script will run Claude autonomously with full          ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} permissions.                                                ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}                                                             ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} Claude will be able to:                                     ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}   - Read, write, and modify files                           ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}   - Execute shell commands                                  ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}   - Create git branches and commits                         ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}   - Push to remote repositories                             ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}                                                             ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} Review your PRD file carefully before proceeding.           ${YELLOW}│${NC}"
    echo -e "${YELLOW}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    read -p "Do you want to continue? (yes/no): " response
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            log_info "Proceeding with execution..."
            return 0
            ;;
        *)
            log_info "Execution cancelled by user."
            exit 0
            ;;
    esac
}

# Cleanup on exit
cleanup() {
    local exit_code=$?

    # Reset any in_progress tasks back to pending (in case of interrupt)
    if [[ -n "${PRD_FILE:-}" && -f "${PRD_FILE:-}" ]]; then
        yq -i '(.tasks[] | select(.status == "in_progress")).status = "pending"' "$PRD_FILE" 2>/dev/null || true
    fi

    if [[ $exit_code -eq 0 ]]; then
        log_info "Ralph Loop complete."
    elif [[ $exit_code -eq 130 ]]; then
        log_warn "Ralph Loop interrupted."
    fi
}

# Handle interrupt signals
handle_interrupt() {
    echo ""
    log_warn "Caught interrupt signal. Cleaning up..."
    exit 130
}

trap cleanup EXIT
trap handle_interrupt INT TERM

# Check dependencies
check_dependencies() {
    local missing=()

    command -v yq >/dev/null 2>&1 || missing+=("yq")
    command -v claude >/dev/null 2>&1 || missing+=("claude")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_error "Install with: brew install ${missing[*]}"
        exit 1
    fi
}

# Validate PRD file exists and is valid YAML
validate_prd() {
    local prd="$1"

    if [[ ! -f "$prd" ]]; then
        log_error "PRD file not found: $prd"
        exit 1
    fi

    if ! yq '.' "$prd" >/dev/null 2>&1; then
        log_error "Invalid YAML in PRD file: $prd"
        exit 1
    fi

    # Check required fields
    local name
    name=$(yq -r '.name // ""' "$prd")
    if [[ -z "$name" ]]; then
        log_error "PRD file missing required field: name"
        exit 1
    fi
}

# Get git workflow setting (vanilla or graphite)
get_git_workflow() {
    local prd="$1"
    yq -r '.git_workflow // "vanilla"' "$prd"
}

# Get branch strategy (independent or stacked)
get_branch_strategy() {
    local prd="$1"
    yq -r '.branch_strategy // "independent"' "$prd"
}

# Check if all dependencies for a task are done (only relevant for stacked strategy)
deps_satisfied() {
    local prd="$1"
    local task_id="$2"

    # Get dependencies as space-separated list
    local deps
    deps=$(yq -r ".tasks[] | select(.id == \"$task_id\") | .depends_on // [] | .[]" "$prd" 2>/dev/null || echo "")

    if [[ -z "$deps" ]]; then
        return 0  # No dependencies
    fi

    # Check each dependency
    for dep in $deps; do
        local dep_status
        dep_status=$(yq -r ".tasks[] | select(.id == \"$dep\") | .status" "$prd")
        if [[ "$dep_status" != "done" ]]; then
            return 1  # Dependency not satisfied
        fi
    done

    return 0  # All dependencies satisfied
}

# Get the parent branch to checkout based on strategy
get_parent_branch() {
    local prd="$1"
    local task_id="$2"

    local strategy
    strategy=$(get_branch_strategy "$prd")
    local base_branch
    base_branch=$(yq -r '.base_branch // "main"' "$prd")

    if [[ "$strategy" == "independent" ]]; then
        # Independent strategy: always branch from base
        echo "$base_branch"
        return
    fi

    # Stacked strategy: branch from last dependency
    local deps
    deps=$(yq -r ".tasks[] | select(.id == \"$task_id\") | .depends_on // [] | .[]" "$prd" 2>/dev/null || echo "")

    if [[ -z "$deps" ]]; then
        # No dependencies, use base_branch
        echo "$base_branch"
        return
    fi

    # Get the last dependency's branch (for linear chains, this is the immediate parent)
    local last_dep=""
    for dep in $deps; do
        last_dep="$dep"
    done

    if [[ -n "$last_dep" ]]; then
        local parent_branch
        parent_branch=$(yq -r ".tasks[] | select(.id == \"$last_dep\") | .result.branch_name // \"\"" "$prd")
        if [[ -n "$parent_branch" && "$parent_branch" != "null" ]]; then
            echo "$parent_branch"
            return
        fi
    fi

    # Fallback to base_branch
    echo "$base_branch"
}

# Get next pending task (sequential execution)
get_next_task() {
    local prd="$1"
    local strategy
    strategy=$(get_branch_strategy "$prd")

    # Get all pending task IDs
    local pending_tasks
    pending_tasks=$(yq -r '.tasks[] | select(.status == "pending") | .id' "$prd")

    if [[ "$strategy" == "stacked" ]]; then
        # For stacked strategy, respect dependencies
        for task_id in $pending_tasks; do
            if deps_satisfied "$prd" "$task_id"; then
                echo "$task_id"
                return 0
            fi
        done
    else
        # For independent strategy, just return first pending (sequential execution)
        for task_id in $pending_tasks; do
            echo "$task_id"
            return 0
        done
    fi

    echo ""
}

# Update task status in PRD
update_task_status() {
    local prd="$1"
    local task_id="$2"
    local status="$3"
    local error="${4:-}"

    # Update status
    yq -i "(.tasks[] | select(.id == \"$task_id\")).status = \"$status\"" "$prd"

    # Update last_error if provided
    if [[ -n "$error" ]]; then
        # Escape the error for YAML (replace newlines, quotes)
        local escaped_error
        escaped_error=$(echo "$error" | head -50 | sed 's/"/\\"/g' | tr '\n' ' ')
        yq -i "(.tasks[] | select(.id == \"$task_id\")).last_error = \"$escaped_error\"" "$prd"
    else
        yq -i "(.tasks[] | select(.id == \"$task_id\")).last_error = null" "$prd"
    fi
}

# Increment task attempts counter
increment_task_attempts() {
    local prd="$1"
    local task_id="$2"
    yq -i "(.tasks[] | select(.id == \"$task_id\")).attempts += 1" "$prd"
}

# Update task result (branch_name and pr_url)
update_task_result() {
    local prd="$1"
    local task_id="$2"
    local branch_name="$3"
    local pr_url="$4"

    if [[ -n "$branch_name" && "$branch_name" != "null" ]]; then
        yq -i "(.tasks[] | select(.id == \"$task_id\")).result.branch_name = \"$branch_name\"" "$prd"
    fi

    if [[ -n "$pr_url" && "$pr_url" != "null" ]]; then
        yq -i "(.tasks[] | select(.id == \"$task_id\")).result.pr_url = \"$pr_url\"" "$prd"
    fi
}

# Get task field value
get_task_field() {
    local prd="$1"
    local task_id="$2"
    local field="$3"

    yq -r ".tasks[] | select(.id == \"$task_id\") | .$field" "$prd"
}

# Get a hook command (task-specific or global)
get_hook() {
    local prd="$1"
    local task_id="$2"
    local hook_name="$3"

    # Try task-specific hook first
    local task_hook
    task_hook=$(yq -r ".tasks[] | select(.id == \"$task_id\") | .hooks.$hook_name // \"\"" "$prd" 2>/dev/null || echo "")

    if [[ -n "$task_hook" && "$task_hook" != "null" ]]; then
        echo "$task_hook"
        return
    fi

    # Fall back to global hook
    local global_hook
    global_hook=$(yq -r ".hooks.$hook_name // \"\"" "$prd" 2>/dev/null || echo "")

    if [[ -n "$global_hook" && "$global_hook" != "null" ]]; then
        echo "$global_hook"
    fi
}

# Run a hook with environment variables
run_hook() {
    local prd="$1"
    local task_id="$2"
    local hook_name="$3"
    local extra_env="${4:-}"

    local hook_cmd
    hook_cmd=$(get_hook "$prd" "$task_id" "$hook_name")

    if [[ -z "$hook_cmd" ]]; then
        return 0  # No hook to run
    fi

    log_info "Running $hook_name hook..."

    # Set up environment variables
    local prd_name
    prd_name=$(yq -r '.name // ""' "$prd")
    local git_workflow
    git_workflow=$(get_git_workflow "$prd")
    local branch_strategy
    branch_strategy=$(get_branch_strategy "$prd")
    local task_name=""
    local task_status=""
    local branch_name=""

    if [[ -n "$task_id" ]]; then
        task_name=$(get_task_field "$prd" "$task_id" "name")
        task_status=$(get_task_field "$prd" "$task_id" "status")
        branch_name=$(yq -r ".tasks[] | select(.id == \"$task_id\") | .result.branch_name // \"\"" "$prd")
    fi

    # Export environment and run hook
    (
        export TASK_ID="$task_id"
        export TASK_NAME="$task_name"
        export TASK_STATUS="$task_status"
        export BRANCH_NAME="$branch_name"
        export PRD_FILE="$prd"
        export PRD_NAME="$prd_name"
        export GIT_WORKFLOW="$git_workflow"
        export BRANCH_STRATEGY="$branch_strategy"

        # Run the hook command
        if bash -c "$hook_cmd"; then
            return 0
        else
            return 1
        fi
    )
}

# Evaluate a single exit condition
# On failure, outputs error details to stdout for capture
evaluate_condition() {
    local prd="$1"
    local task_id="$2"
    local condition_json="$3"

    local cond_type
    cond_type=$(echo "$condition_json" | yq -r '.type')

    case "$cond_type" in
        command)
            local run_cmd expect
            run_cmd=$(echo "$condition_json" | yq -r '.run')
            expect=$(echo "$condition_json" | yq -r '.expect // "success"')

            log_info "  Checking command: $run_cmd (expect: $expect)"

            local exit_code=0
            local cmd_output
            cmd_output=$(bash -c "$run_cmd" 2>&1) || exit_code=$?

            if [[ "$expect" == "success" && "$exit_code" -eq 0 ]]; then
                return 0
            elif [[ "$expect" == "failure" && "$exit_code" -ne 0 ]]; then
                return 0
            else
                log_warn "  Command condition failed (exit code: $exit_code, expected: $expect)"
                # Output error details for capture
                echo "Exit condition failed: command '$run_cmd' (exit code: $exit_code, expected: $expect)"
                if [[ -n "$cmd_output" ]]; then
                    log_error "  Command output:"
                    echo "$cmd_output" | head -50 | sed 's/^/    /'
                    echo ""
                    echo "Command output:"
                    echo "$cmd_output" | head -50
                fi
                return 1
            fi
            ;;

        file_exists)
            local path_pattern
            path_pattern=$(echo "$condition_json" | yq -r '.path')

            log_info "  Checking file exists: $path_pattern"

            # Use glob expansion
            local matches
            matches=$(compgen -G "$path_pattern" 2>/dev/null || echo "")

            if [[ -n "$matches" ]]; then
                return 0
            else
                log_warn "  File not found: $path_pattern"
                echo "Exit condition failed: file not found matching pattern '$path_pattern'"
                return 1
            fi
            ;;

        branch_pushed)
            log_info "  Checking branch is pushed..."

            local current_branch
            current_branch=$(git branch --show-current 2>/dev/null || echo "")

            if [[ -z "$current_branch" ]]; then
                log_warn "  Not on a branch"
                echo "Exit condition failed: not on a git branch"
                return 1
            fi

            # Check if remote tracking branch exists
            if git rev-parse --verify "origin/$current_branch" >/dev/null 2>&1; then
                # Check if local and remote are in sync
                local local_sha remote_sha
                local_sha=$(git rev-parse HEAD 2>/dev/null || echo "")
                remote_sha=$(git rev-parse "origin/$current_branch" 2>/dev/null || echo "")

                if [[ "$local_sha" == "$remote_sha" ]]; then
                    return 0
                else
                    log_warn "  Branch not fully pushed (local differs from remote)"
                    echo "Exit condition failed: branch '$current_branch' not fully pushed (local differs from remote)"
                    return 1
                fi
            else
                log_warn "  Branch not pushed to remote"
                echo "Exit condition failed: branch '$current_branch' not pushed to remote"
                return 1
            fi
            ;;

        branch_created)
            log_info "  Checking new branch exists..."

            local base_branch
            base_branch=$(yq -r '.base_branch // "main"' "$prd")
            local current_branch
            current_branch=$(git branch --show-current 2>/dev/null || echo "")

            if [[ -n "$current_branch" && "$current_branch" != "$base_branch" ]]; then
                return 0
            else
                log_warn "  Not on a new branch (current: $current_branch, base: $base_branch)"
                echo "Exit condition failed: not on a new branch (current: '$current_branch', base: '$base_branch')"
                return 1
            fi
            ;;

        tests_pass)
            local test_path
            test_path=$(echo "$condition_json" | yq -r '.path // ""')

            local test_cmd="dev test"
            if [[ -n "$test_path" && "$test_path" != "null" ]]; then
                test_cmd="dev test $test_path"
            fi

            log_info "  Running tests: $test_cmd"

            local test_output
            test_output=$($test_cmd 2>&1) || {
                log_warn "  Tests failed"
                echo "Exit condition failed: tests did not pass"
                echo ""
                echo "Test output:"
                echo "$test_output" | head -50
                return 1
            }
            return 0
            ;;

        *)
            log_warn "  Unknown condition type: $cond_type"
            echo "Exit condition failed: unknown condition type '$cond_type'"
            return 1
            ;;
    esac
}

# Evaluate all exit conditions for a task
# On failure, outputs error details to stdout for capture
evaluate_exit_conditions() {
    local prd="$1"
    local task_id="$2"

    # Get exit conditions as JSON array
    local conditions
    conditions=$(yq -r ".tasks[] | select(.id == \"$task_id\") | .exit_conditions // []" "$prd")

    # Check if conditions is empty array
    local count
    count=$(echo "$conditions" | yq 'length')

    if [[ "$count" -eq 0 || "$conditions" == "[]" || "$conditions" == "null" ]]; then
        log_info "No exit conditions defined - trusting Claude"
        return 0
    fi

    log_info "Evaluating $count exit condition(s)..."

    # Iterate through conditions
    local i=0
    while [[ $i -lt $count ]]; do
        local condition
        condition=$(yq -r ".tasks[] | select(.id == \"$task_id\") | .exit_conditions[$i]" "$prd")

        local error_output
        if ! error_output=$(evaluate_condition "$prd" "$task_id" "$condition"); then
            # Output the error details for capture by caller
            echo "$error_output"
            return 1
        fi

        i=$((i + 1))
    done

    log_info "All exit conditions passed"
    return 0
}

# Extract branch name from Claude output
extract_branch_name() {
    local output="$1"

    local branch=""

    # Look for gt create output
    branch=$(echo "$output" | grep -oE "Created branch[: ]+['\"]?([a-zA-Z0-9/_-]+)['\"]?" | tail -1 | sed 's/.*[: ]//' | tr -d "'" | tr -d '"')

    if [[ -z "$branch" ]]; then
        # Look for "On branch" from git status
        branch=$(echo "$output" | grep -oE "On branch ([a-zA-Z0-9/_-]+)" | tail -1 | sed 's/On branch //')
    fi

    if [[ -z "$branch" ]]; then
        # Look for git checkout -b or git switch -c
        branch=$(echo "$output" | grep -oE "(checkout -b|switch -c) ([a-zA-Z0-9/_-]+)" | tail -1 | sed 's/.* //')
    fi

    if [[ -z "$branch" ]]; then
        # Look for gt stack output showing current branch
        branch=$(echo "$output" | grep -oE "^\* ([a-zA-Z0-9/_-]+)" | tail -1 | sed 's/^\* //')
    fi

    echo "$branch"
}

# Extract PR URL from Claude output
extract_pr_url() {
    local output="$1"

    # Look for GitHub PR URL
    local pr_url=""
    pr_url=$(echo "$output" | grep -oE "https://github.com/[a-zA-Z0-9/_-]+/pull/[0-9]+" | tail -1)

    echo "$pr_url"
}

# Build prompt - let the PRD prompt control git behavior
build_prompt() {
    local prd="$1"
    local task_id="$2"

    local base_prompt
    base_prompt=$(get_task_field "$prd" "$task_id" "prompt")

    local last_error
    last_error=$(get_task_field "$prd" "$task_id" "last_error")

    local attempts
    attempts=$(get_task_field "$prd" "$task_id" "attempts")

    # Check if branch already exists from previous attempt
    local existing_branch
    existing_branch=$(yq -r ".tasks[] | select(.id == \"$task_id\") | .result.branch_name // \"\"" "$prd")

    # Build the full prompt
    local full_prompt=""

    # If retrying with an existing branch, tell Claude to continue on it
    if [[ -n "$existing_branch" && "$existing_branch" != "null" ]]; then
        full_prompt="CONTINUE ON EXISTING BRANCH: $existing_branch

A previous attempt created this branch but exit conditions were not satisfied.
First, checkout this branch:
\`\`\`bash
git checkout $existing_branch
\`\`\`

"
    fi

    # Add retry context if this is a retry with an error
    if [[ "$attempts" -gt 0 && "$last_error" != "null" && -n "$last_error" ]]; then
        full_prompt="${full_prompt}RETRY ATTEMPT $((attempts + 1)): Previous attempt failed.

Error details:
$last_error

Please fix the issues and try again.

---

"
    fi

    # Add the actual task prompt (user controls git workflow here)
    full_prompt="${full_prompt}TASK:
$base_prompt

---

COMPLETION REQUIREMENTS:
1. Implement the changes described above
2. Follow any git instructions in the task prompt
3. Ensure all work is committed"

    echo "$full_prompt"
}

# Run Claude Code for a task
# $3 = error_file (optional) - file to write error details to on failure
run_claude_task() {
    local prd="$1"
    local task_id="$2"
    local error_file="${3:-}"

    local prompt
    prompt=$(build_prompt "$prd" "$task_id")

    local task_name
    task_name=$(get_task_field "$prd" "$task_id" "name")

    local parent_branch
    parent_branch=$(get_parent_branch "$prd" "$task_id")

    local git_workflow
    git_workflow=$(get_git_workflow "$prd")

    local branch_strategy
    branch_strategy=$(get_branch_strategy "$prd")

    # Get task-specific working directory (cwd)
    local task_cwd
    task_cwd=$(get_task_field "$prd" "$task_id" "cwd")

    log_task "Running task: $task_id"
    log_info "  Name: $task_name"
    log_info "  Parent branch: $parent_branch"
    log_info "  Git workflow: $git_workflow"
    log_info "  Branch strategy: $branch_strategy"
    if [[ -n "$task_cwd" && "$task_cwd" != "null" ]]; then
        log_info "  Working directory: $task_cwd"
    fi

    # Validate working directory
    local run_in_dir="${task_cwd:-$(pwd)}"
    if [[ "$run_in_dir" != "null" && ! -d "$run_in_dir" ]]; then
        log_error "Task working directory does not exist: $run_in_dir"
        [[ -n "$error_file" ]] && echo "Working directory not found: $run_in_dir" > "$error_file"
        return 1
    fi
    if [[ "$run_in_dir" == "null" ]]; then
        run_in_dir="$(pwd)"
    fi

    # Run pre_task hook
    if ! run_hook "$prd" "$task_id" "pre_task"; then
        log_error "pre_task hook failed - skipping task"
        [[ -n "$error_file" ]] && echo "pre_task hook failed" > "$error_file"
        return 1
    fi

    # Create temp files
    local output_file
    output_file=$(mktemp)

    # Write prompt to temp file to avoid escaping issues
    local prompt_file
    prompt_file=$(mktemp)
    echo "$prompt" > "$prompt_file"

    log_info "  Running Claude Code..."
    echo ""

    # Run Claude in --print mode (exits cleanly when done)
    # Use tee to show output on terminal AND capture to file
    local exit_code=0
    pushd "$run_in_dir" > /dev/null
    claude --print --dangerously-skip-permissions "$(cat "$prompt_file")" 2>&1 | tee "$output_file" || exit_code=${PIPESTATUS[0]}
    popd > /dev/null

    echo ""

    # Cleanup prompt file
    rm -f "$prompt_file"

    if [[ "$exit_code" -eq 0 ]]; then
        log_info "Claude completed task $task_id"

        # Extract branch name and PR URL from output
        local output
        output=$(cat "$output_file")

        local branch_name
        branch_name=$(extract_branch_name "$output")

        local pr_url
        pr_url=$(extract_pr_url "$output")

        # If we couldn't extract branch, try to get current branch from the task's directory
        if [[ -z "$branch_name" ]]; then
            branch_name=$(cd "$run_in_dir" && git branch --show-current 2>/dev/null || echo "")
        fi

        log_info "  Branch: ${branch_name:-unknown}"
        if [[ -n "$pr_url" ]]; then
            log_info "  PR URL: $pr_url"
        fi

        # Update results in PRD (before exit condition check)
        update_task_result "$prd" "$task_id" "$branch_name" "$pr_url"

        rm -f "$output_file"

        # Evaluate exit conditions
        pushd "$run_in_dir" > /dev/null

        # Checkout the branch Claude created before evaluating exit conditions
        if [[ -n "$branch_name" ]]; then
            log_info "  Checking out branch: $branch_name"
            git checkout "$branch_name" 2>/dev/null || log_warn "  Could not checkout $branch_name"
        fi

        local exit_cond_error
        if ! exit_cond_error=$(evaluate_exit_conditions "$prd" "$task_id"); then
            popd > /dev/null
            log_warn "Exit conditions not satisfied for $task_id"
            # Write the captured error details to error_file
            [[ -n "$error_file" ]] && echo "$exit_cond_error" > "$error_file"
            return 1
        fi
        popd > /dev/null

        # Run post_task hook (failure doesn't fail the task)
        if ! run_hook "$prd" "$task_id" "post_task"; then
            log_warn "post_task hook failed (task still considered successful)"
        fi

        return 0
    else
        local error_output
        error_output=$(tail -100 "$output_file" | head -50)
        log_error "Task $task_id failed with exit code $exit_code"
        log_error "Output (last 50 lines):"
        echo "$error_output"
        rm -f "$output_file"
        # Write the error output to error_file
        [[ -n "$error_file" ]] && echo "$error_output" > "$error_file"
        return 1
    fi
}

# Show PRD status summary
show_status() {
    local prd="$1"

    echo ""
    log_info "=== PRD Status ==="

    local name
    name=$(yq -r '.name' "$prd")
    local base_branch
    base_branch=$(yq -r '.base_branch // "main"' "$prd")
    local git_workflow
    git_workflow=$(get_git_workflow "$prd")
    local branch_strategy
    branch_strategy=$(get_branch_strategy "$prd")

    echo "Project: $name"
    echo "Base branch: $base_branch"
    echo "Git workflow: $git_workflow"
    echo "Branch strategy: $branch_strategy"
    echo ""

    # Get task count
    local task_count
    task_count=$(yq '.tasks | length' "$prd")

    for ((i=0; i<task_count; i++)); do
        local id status task_name attempts max_retries branch_name pr_url
        id=$(yq -r ".tasks[$i].id" "$prd")
        status=$(yq -r ".tasks[$i].status" "$prd")
        task_name=$(yq -r ".tasks[$i].name" "$prd")
        attempts=$(yq -r ".tasks[$i].attempts" "$prd")
        max_retries=$(yq -r ".tasks[$i].max_retries" "$prd")
        branch_name=$(yq -r ".tasks[$i].result.branch_name // \"\"" "$prd")
        pr_url=$(yq -r ".tasks[$i].result.pr_url // \"\"" "$prd")

        local icon
        case "$status" in
            done) icon="✓" ;;
            failed) icon="✗" ;;
            in_progress) icon="→" ;;
            *) icon=" " ;;
        esac

        echo "  [$icon] $id - $task_name (attempts: $attempts/$max_retries)"

        # Show result info if task is done
        if [[ "$status" == "done" ]]; then
            if [[ -n "$branch_name" && "$branch_name" != "null" ]]; then
                echo "      Branch: $branch_name"
            fi
            if [[ -n "$pr_url" && "$pr_url" != "null" ]]; then
                echo "      PR: $pr_url"
            fi
        fi
    done

    echo ""
}

# Show the completed work visualization
show_stack() {
    local prd="$1"

    echo ""
    log_info "=== Completed Work ==="

    local base_branch
    base_branch=$(yq -r '.base_branch // "main"' "$prd")
    local branch_strategy
    branch_strategy=$(get_branch_strategy "$prd")

    # Get task count
    local task_count
    task_count=$(yq '.tasks | length' "$prd")

    local branches=()
    for ((i=0; i<task_count; i++)); do
        local status branch_name pr_url task_name
        status=$(yq -r ".tasks[$i].status" "$prd")
        branch_name=$(yq -r ".tasks[$i].result.branch_name // \"\"" "$prd")
        pr_url=$(yq -r ".tasks[$i].result.pr_url // \"\"" "$prd")
        task_name=$(yq -r ".tasks[$i].name" "$prd")

        if [[ "$status" == "done" && -n "$branch_name" && "$branch_name" != "null" ]]; then
            local pr_info=""
            if [[ -n "$pr_url" && "$pr_url" != "null" ]]; then
                local pr_num
                pr_num=$(echo "$pr_url" | grep -oE "[0-9]+$" || echo "")
                pr_info=" (PR #$pr_num)"
            fi
            branches+=("$branch_name$pr_info - $task_name")
        fi
    done

    if [[ "$branch_strategy" == "stacked" ]]; then
        echo "Stack (top to bottom):"
        for ((i=${#branches[@]}-1; i>=0; i--)); do
            echo "  ${branches[$i]}"
        done
        echo "  $base_branch (base)"
    else
        echo "Independent branches:"
        for branch in "${branches[@]}"; do
            echo "  $branch"
        done
        echo ""
        echo "Base: $base_branch"
    fi
    echo ""
}

# Submit the stack (only for graphite + stacked)
submit_stack() {
    local prd="$1"

    local git_workflow
    git_workflow=$(get_git_workflow "$prd")
    local branch_strategy
    branch_strategy=$(get_branch_strategy "$prd")

    if [[ "$git_workflow" != "graphite" ]]; then
        log_info "Vanilla git workflow - branches are pushed, create PRs manually or use 'gh pr create'"
        return 0
    fi

    if [[ "$branch_strategy" != "stacked" ]]; then
        log_info "Independent branch strategy - PRs should be created individually"
        return 0
    fi

    echo ""
    log_info "=== Submitting PR Stack ==="

    # Get the last task's branch (top of stack)
    local task_count
    task_count=$(yq '.tasks | length' "$prd")

    local top_branch=""
    for ((i=task_count-1; i>=0; i--)); do
        local status branch_name
        status=$(yq -r ".tasks[$i].status" "$prd")
        branch_name=$(yq -r ".tasks[$i].result.branch_name // \"\"" "$prd")

        if [[ "$status" == "done" && -n "$branch_name" && "$branch_name" != "null" ]]; then
            top_branch="$branch_name"
            break
        fi
    done

    if [[ -z "$top_branch" ]]; then
        log_warn "No branch found to submit"
        return 1
    fi

    log_info "Checking out top of stack: $top_branch"
    git checkout "$top_branch"

    log_info "Submitting stack with: gt submit --stack"
    if gt submit --stack; then
        log_info "Stack submitted successfully!"
    else
        log_error "Failed to submit stack"
        return 1
    fi
}

# Main loop
main() {
    check_dependencies
    validate_prd "$PRD_FILE"

    log_info "Starting Ralph Loop"
    log_info "PRD file: $PRD_FILE"

    show_status "$PRD_FILE"

    # Get user confirmation before proceeding (skip if --yes flag was passed)
    if [[ "${SKIP_CONFIRMATION:-false}" != "true" ]]; then
        confirm_execution
    fi

    local global_attempts=0

    while true; do
        # Check for infinite loop
        if [[ "$global_attempts" -ge "$MAX_GLOBAL_RETRIES" ]]; then
            log_error "Max global retries ($MAX_GLOBAL_RETRIES) exceeded. Stopping."
            show_status "$PRD_FILE"
            exit 1
        fi

        # Get next task (always sequential - one at a time)
        local next_task
        next_task=$(get_next_task "$PRD_FILE")

        if [[ -z "$next_task" ]]; then
            # Check if all done or if there are failed/blocked tasks
            local pending_count
            pending_count=$(yq '[.tasks[] | select(.status == "pending")] | length' "$PRD_FILE")

            local failed_count
            failed_count=$(yq '[.tasks[] | select(.status == "failed")] | length' "$PRD_FILE")

            if [[ "$pending_count" -eq 0 && "$failed_count" -eq 0 ]]; then
                log_info "All tasks completed successfully!"
                show_status "$PRD_FILE"
                show_stack "$PRD_FILE"

                # Run on_complete hook
                if ! run_hook "$PRD_FILE" "" "on_complete"; then
                    log_warn "on_complete hook failed"
                fi

                # Submit stack if using graphite + stacked (legacy behavior, can be replaced by hook)
                submit_stack "$PRD_FILE"
                exit 0
            else
                log_warn "No runnable tasks available"
                if [[ "$pending_count" -gt 0 ]]; then
                    log_warn "Pending tasks blocked by dependencies: $pending_count"
                fi
                if [[ "$failed_count" -gt 0 ]]; then
                    log_error "Failed tasks: $failed_count"
                fi
                show_status "$PRD_FILE"
                exit 1
            fi
        fi

        # Check max retries for this task
        local attempts
        attempts=$(get_task_field "$PRD_FILE" "$next_task" "attempts")
        local max_retries
        max_retries=$(get_task_field "$PRD_FILE" "$next_task" "max_retries")

        if [[ "$attempts" -ge "$max_retries" ]]; then
            log_error "Task $next_task exceeded max retries ($max_retries)"
            update_task_status "$PRD_FILE" "$next_task" "failed"

            # Run on_failure hook
            if ! run_hook "$PRD_FILE" "$next_task" "on_failure"; then
                log_warn "on_failure hook failed"
            fi

            global_attempts=$((global_attempts + 1))
            continue
        fi

        # Mark task as in progress and increment attempts
        yq -i "(.tasks[] | select(.id == \"$next_task\")).status = \"in_progress\"" "$PRD_FILE"
        increment_task_attempts "$PRD_FILE" "$next_task"

        # Run the task
        local error_file
        error_file=$(mktemp)
        if run_claude_task "$PRD_FILE" "$next_task" "$error_file"; then
            update_task_status "$PRD_FILE" "$next_task" "done"
            log_info "Task $next_task marked as done"
        else
            local error_output
            error_output=$(cat "$error_file" 2>/dev/null || echo "Task failed")
            log_warn "Task $next_task failed, will retry if attempts remain"
            update_task_status "$PRD_FILE" "$next_task" "pending" "$error_output"
        fi
        rm -f "$error_file"

        global_attempts=$((global_attempts + 1))

        # Show current status after each task
        show_status "$PRD_FILE"
    done
}

# Show help
show_help() {
    cat <<EOF
Ralph Loop - Automate Claude Code sessions for multi-step implementations

Usage: $0 [options] <prd-file.yaml>

Options:
  --help, -h      Show this help message
  --status, -s    Show status of PRD file without running tasks
  --stack         Show completed work visualization
  --yes, -y       Skip confirmation prompt (use with caution)

Environment variables:
  MAX_GLOBAL_RETRIES  Maximum total iterations (default: 10)

The PRD file should be a YAML file with the following structure:

  name: project-name
  description: Project description
  base_branch: main
  git_workflow: vanilla       # "vanilla" (default) or "graphite"
  branch_strategy: independent  # "independent" (default) or "stacked"

  # Global hooks (optional)
  hooks:
    pre_task: |           # Runs before each task
      git fetch origin
    post_task: |          # Runs after each successful task
      echo "Task completed"
    on_complete: |        # Runs when ALL tasks complete
      gt submit --stack
    on_failure: |         # Runs when a task fails after all retries
      echo "Task failed"

  tasks:
    - id: task-id
      name: Task name
      status: pending
      attempts: 0
      max_retries: 3
      cwd: /path/to/working/directory  # Optional
      prompt: |
        Task prompt for Claude Code...

      # Exit conditions - all must pass (optional)
      exit_conditions:
        - type: command
          run: "dev test test/models/"
          expect: success
        - type: file_exists
          path: "db/migrate/*.rb"
        - type: branch_pushed
        - type: branch_created
        - type: tests_pass
          path: "test/models/"  # optional

      depends_on:
        - previous-task-id    # For stacked strategy

      # Task-specific hooks (override global)
      hooks:
        pre_task: |
          echo "Custom setup"

      result:
        branch_name: null
        pr_url: null
      last_error: null

Git Workflows:
  vanilla   - Use standard git commands (default)
  graphite  - Use Graphite CLI (gt) for stacked PRs

Branch Strategies:
  independent - Each task branches from base_branch (default)
                Tasks execute sequentially but create independent branches
  stacked     - Each task branches from its dependency's branch
                Creates a chain of dependent PRs

Exit Condition Types:
  command       - Run a shell command (expect: success|failure)
  file_exists   - Check if file(s) matching pattern exist
  branch_pushed - Verify current branch is pushed to remote
  branch_created- Verify a new branch exists (not base)
  tests_pass    - Run tests (shorthand for command)

Hook Environment Variables:
  \$TASK_ID, \$TASK_NAME, \$TASK_STATUS, \$BRANCH_NAME
  \$PRD_FILE, \$PRD_NAME, \$GIT_WORKFLOW, \$BRANCH_STRATEGY

Note: Tasks ALWAYS execute sequentially (one at a time) to prevent
competing changes in the same codebase.

EOF
}

# Parse arguments
parse_args() {
    local prd_file=""
    local action="run"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --status|-s)
                action="status"
                shift
                ;;
            --stack)
                action="stack"
                shift
                ;;
            --yes|-y)
                SKIP_CONFIRMATION="true"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                prd_file="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$prd_file" ]]; then
        log_error "Missing required argument: <prd-file.yaml>"
        show_help
        exit 1
    fi

    # Export for use in functions
    PRD_FILE="$prd_file"

    case "$action" in
        status)
            validate_prd "$PRD_FILE"
            show_status "$PRD_FILE"
            exit 0
            ;;
        stack)
            validate_prd "$PRD_FILE"
            show_stack "$PRD_FILE"
            exit 0
            ;;
        run)
            main
            ;;
    esac
}

# Entry point
parse_args "$@"
