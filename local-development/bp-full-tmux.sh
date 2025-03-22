#!/bin/bash
source ~/.bashrc

# Define service names and commands
service_names=(
    "identity" 
    "business-platform" 
    "billing" 
    "core" 
    "core-hedwig-enqueuer" 
    "core-hedwig-worker" 
    "admin-web"
    "monitor"
    "shell"
)

commands=(
    "dev cd identity && git pull && dev up && dev server"
    "dev cd business-platform && touch tmp/caching-dev.txt && git pull && PRE_CONTRACT=1 dev up && dev server"
    "dev cd world && cd areas/platforms/billing && dev up && dev server"
    "cd ~/ && clear && dev cd shopify && dev up && dev server"
    "dev cd shopify && dev hedwig enqueuer"
    "dev cd shopify && dev hedwig worker 2"
    "dev cd admin-web && dev up && LOCAL_IDENTITY=true dev server"
    "while sleep 15; do clear; dev ps --all-namespaces --procs; done"
    "echo 'All services have been initialized. You can run commands in this pane.'"
)

# URLs for health checks - set to empty string if no health check needed
urls=(
    "http://identity.root.shopify.dev.internal" # identity
    "http://business-platform.myshopify.io" # business-platform
    "http://billing.root.world.dev.internal" # billing
    "http://shopify.root.world.dev.internal" # core
    "" # core-hedwig-enqueuer (no health check)
    "" # core-hedwig-worker (no health check)
    "http://web.root.world.dev.internal" # admin-web
    "" # monitor (no health check)
    "" # shell (no health check)
)

# Wait for a service to be running
wait_until_server_is_running() {
    local url="$1"
    local service="$2"
    local response_code

    # If URL is empty, don't do health check
    if [ -z "$url" ]; then
        echo "No health check URL for $service, skipping check."
        return 0
    fi

    max_wait_time=1200
    elapsed_time=0
    check_interval=15

    echo "Checking health of $service at $url..."

    while true; do
        response_code=$(curl -L --write-out "%{http_code}" --silent --output /dev/null "$url")

        if [ "$response_code" -eq 200 ]; then
            echo "Service $service is running successfully!"
            break
        else
            response_code=$(curl -I -L --write-out "%{http_code}" --silent --output /dev/null "$url")
            if [ "$response_code" -eq 200 ]; then
                echo "Service $service is running successfully!"
                break
            fi

            echo "Waiting for $service to start... (Received response code: $response_code)"
            
            elapsed_time=$((elapsed_time + check_interval))
            
            if [ "$elapsed_time" -ge "$max_wait_time" ]; then
                echo "Timeout reached: Service $service did not start after 10 minutes. Try checking the logs for more information."
                return 1
            fi
            
            sleep $check_interval
        fi
    done
}

# Function to find the index of a service by name
index() {
    local service_name=$1
    for i in "${!service_names[@]}"; do
        if [[ "${service_names[i]}" == "$service_name" ]]; then
            echo "$i"
            return
        fi
    done
    echo "-1"
}

# Create a 3x3 grid in iTerm2 with equal-sized panes
create_3x3_grid() {
    # Create a new window
    osascript <<EOT
    tell application "iTerm2"
        create window with default profile
    end tell
EOT
    
    sleep 1
    
    # Create a new tmux session within the window
    osascript <<EOT
    tell application "iTerm2"
        tell current session of current window
            write text "tmux new-session -d -s services_grid"
            write text "tmux send-keys 'clear' C-m"
            write text "tmux attach-session -t services_grid"
        end tell
    end tell
EOT
    
    sleep 2
    
    # Create a perfectly equal 3x3 grid using a different approach
    tmux_commands=(
        # First split into three equal horizontal panes
        "split-window -v -p 66"
        "split-window -v -p 50"
        # Select the top pane and split into three equal vertical panes
        "select-pane -t 0"
        "split-window -h -p 66"
        "split-window -h -p 50"
        # Select the middle pane and split into three equal vertical panes
        "select-pane -t 3"
        "split-window -h -p 66"
        "split-window -h -p 50"
        # Select the bottom pane and split into three equal vertical panes
        "select-pane -t 6"
        "split-window -h -p 66"
        "split-window -h -p 50"
        # Select pane 0 to start
        "select-pane -t 0"
    )
    
    for cmd in "${tmux_commands[@]}"; do
        osascript <<EOT
        tell application "iTerm2"
            tell current session of current window
                write text "tmux $cmd"
            end tell
        end tell
EOT
        sleep 0.5
    done
    
    # Set pane layout to ensure equal sizes
    osascript <<EOT
    tell application "iTerm2"
        tell current session of current window
            write text "tmux select-layout tiled"
        end tell
    end tell
EOT
    
    sleep 1
    
    # Map panes in a logical order (top left to bottom right)
    # This ensures services start in the correct order in the correct positions
    pane_map=(0 1 2 3 4 5 6 7 8)
    
    # First, make sure all panes are completely clear
    for pane in {0..8}; do
        osascript <<EOT
        tell application "iTerm2"
            tell current session of current window
                write text "tmux select-pane -t $pane"
                write text "tmux send-keys 'clear' C-m"
            end tell
        end tell
EOT
        sleep 0.5
    done
    
    # Name each pane and print its position
    for i in {0..8}; do
        osascript <<EOT
        tell application "iTerm2"
            tell current session of current window
                write text "tmux select-pane -t ${pane_map[$i]}"
                write text "tmux send-keys 'echo \"${service_names[$i]} (Pane ${pane_map[$i]})\"' C-m"
            end tell
        end tell
EOT
        sleep 1
    done
}

# Run a command in a specific tmux pane
run_command_in_pane() {
    local i="$1"  # Service index
    local command="$2"
    local pane="${pane_map[$i]}"  # Get the corresponding pane number
    
    # Escape special characters in the command
    command="${command//\\/\\\\}"  # Escape backslashes
    command="${command//\'/\'\\\'\'}"  # Escape single quotes
    command="${command//\"/\\\"}"  # Escape double quotes
    
    echo "Starting ${service_names[$i]} in pane $pane..."
    
    # First ensure the pane is clear and ready
    osascript <<EOT
    tell application "iTerm2"
        tell current session of current window
            write text "tmux select-pane -t $pane"
            write text "tmux send-keys 'clear' C-m"
        end tell
    end tell
EOT
    
    sleep 2
    
    # Now run the actual command
    osascript <<EOT
    tell application "iTerm2"
        tell current session of current window
            write text "tmux select-pane -t $pane"
            write text "tmux send-keys '$command' C-m"
        end tell
    end tell
EOT
    
    # Longer wait to ensure command starts properly
    sleep 3
}

# Function to run seeding commands
run_seeding_commands() {
    osascript <<EOT
    tell application "iTerm2"
        create window with default profile
        tell current session of current window
            write text "dev cd shopify && for key in business-platform-dev-api-key development-shopify-flow-key plus-store-operations-key plus-business-key development-home-key; do bundle exec rails dev:create_apps API_KEY=\$key; done;"
        end tell
    end tell
EOT
}

# Define the pane mapping (service index to tmux pane number)
# This maps services to specific panes in the 3x3 grid
# The pane numbers are assigned by tmux based on the order of creation:
# 0 1 2
# 3 4 5
# 6 7 8
pane_map=(0 1 2 3 4 5 6 7 8)

if [ "$1" == "up" ]; then
    # Check for start_from parameter
    start_from=""
    for arg in "$@"; do
        if [[ "$arg" == start_from=* ]]; then
            start_from="${arg#*=}"
            break
        fi
    done
    
    echo "Setting up local development environment..."
    
    # Create the 3x3 grid
    create_3x3_grid
    
    # Wait for tmux to fully initialize
    sleep 2
    
    # Determine the starting service index
    if [[ -n "$start_from" ]]; then
        idx=$(index "$start_from")
        if [ "$idx" == "-1" ]; then
            echo "Invalid service name provided. Please provide a valid service name."
            exit 1
        fi
        start_idx=$idx
    else
        start_idx=0
    fi
    
    # Debug function to check pane status
    debug_panes() {
        echo "Checking pane status..."
        for i in {0..8}; do
            osascript <<EOT
            tell application "iTerm2"
                tell current session of current window
                    write text "tmux select-pane -t $i"
                    write text "tmux send-keys 'echo \"Pane $i check\"' C-m"
                end tell
            end tell
EOT
            sleep 0.5
        done
        sleep 1
    }
    
    # Run a quick debug check
    debug_panes
    
    # Start the services in order, with an additional delay between each one
    for ((i = start_idx; i < ${#service_names[@]} && i < 9; i++)); do
        echo "==============================================="
        echo "Preparing to start ${service_names[$i]} (service $i) in pane ${pane_map[$i]}..."
        echo "==============================================="
        
        # Make sure the pane is ready
        osascript <<EOT
        tell application "iTerm2"
            tell current session of current window
                write text "tmux select-pane -t ${pane_map[$i]}"
                write text "tmux send-keys 'clear && echo \"Starting ${service_names[$i]}...\"' C-m"
            end tell
        end tell
EOT
        sleep 2
        
        # Now run the command
        run_command_in_pane $i "${commands[$i]}"
        
        # Do health check if URL is provided
        if [ -n "${urls[$i]}" ]; then
            wait_until_server_is_running "${urls[$i]}" "${service_names[$i]}"
        fi
        
        echo "${service_names[$i]} started successfully."
        sleep 3  # Increased delay between services
    done
    
    echo "All services have been initialized."
    echo "To run seeding commands, use: $0 seed"
    
elif [ "$1" == "seed" ]; then
    run_seeding_commands
    echo "Seeding commands executed."
else
    echo "Invalid argument. Please provide 'up' to start the environment or 'seed' to run seeding commands."
    exit 1
fi
