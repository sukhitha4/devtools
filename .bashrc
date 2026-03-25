function tail_grid() {
    local pod_pattern="$1"
    
    if [[ -z "$pod_pattern" ]]; then
        echo "Usage: tail_grid <pod-name-pattern>"
        echo "Example: tail_grid auth-service"
        return 1
    fi

    # Define your 4 cluster URLs here
    local cluster_urls=(
        "https://url1:6443"
        "https://url2:6443"
        "https://url3:6443"
        "https://url4:6443"
    )

    # Toggles between Vertical and Horizontal to tile the panes into a grid
    local split_dir="V"

    for url in "${cluster_urls[@]}"; do
        echo "========================================"
        echo "Logging into $url..."
        
        # Standard oc login. Prompts will appear here if tokens/passwords are needed.
        oc login "$url"
        
        # Capture the new context name so the split panes don't lose connection 
        # when the loop moves to the next cluster.
        local current_ctx
        current_ctx=$(kubectl config current-context)

        # Fetch pods matching the input parameter
        local pods
        pods=$(kubectl get pods -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -i "$pod_pattern")

        if [[ -z "$pods" ]]; then
            echo "No pods matching '$pod_pattern' found in $current_ctx."
            continue
        fi

        for pod in $pods; do
            echo "Spawning log stream for: $pod"
            
            # The command to execute inside the new ConEmu pane. 
            # We append a read command so the pane doesn't instantly close if the pod crashes or restarts.
            local cmd="kubectl --context=$current_ctx logs -f $pod; echo -e '\n[Stream ended. Press Enter to close]'; read"
            
            # Launch in a new ConEmu split. ConEmu intercepts the -new_console flag.
            bash -c "$cmd" "-new_console:s${split_dir}"
            
            # Toggle the split direction to build the grid dynamically
            if [[ "$split_dir" == "V" ]]; then
                split_dir="H"
            else
                split_dir="V"
            fi
            
            # Brief sleep to ensure ConEmu processes the hook before the loop fires the next one
            sleep 0.5
        done
    done
    
    echo "========================================"
    echo "Grid deployment complete."
}
