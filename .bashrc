function tail_grid() {
    local env="$1"
    local pod_pattern="$2"
    
    # Check if both parameters are provided
    if [[ -z "$env" || -z "$pod_pattern" ]]; then
        echo "Usage: tail_grid <prod|np> <pod-name-pattern>"
        echo "Example: tail_grid np auth-service"
        return 1
    fi

    local cluster_urls=()

    # Determine which set of URLs to use based on the environment parameter
    case "$env" in
        prod)
            cluster_urls=(
                "https://prod-url1:6443"
                "https://prod-url2:6443"
                "https://prod-url3:6443"
                "https://prod-url4:6443"
            )
            ;;
        np)
            cluster_urls=(
                "https://np-url1:6443"
                "https://np-url2:6443"
                "https://np-url3:6443"
                "https://np-url4:6443"
            )
            ;;
        *)
            echo "Error: Invalid environment '$env'. Please specify 'prod' or 'np'."
            return 1
            ;;
    esac

    # Toggles between Vertical and Horizontal to tile the panes into a grid
    local split_dir="V"

    for url in "${cluster_urls[@]}"; do
        echo "========================================"
        echo "Logging into $env cluster: $url..."
        
        # Standard oc login
        oc login "$url"
        
        # Capture the new context name
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
            local cmd="kubectl --context=$current_ctx logs -f $pod; echo -e '\n[Stream ended. Press Enter to close]'; read"
            
            # Launch in a new ConEmu split.
            bash -c "$cmd" "-new_console:s${split_dir}"
            
            # Toggle the split direction to build the grid dynamically
            if [[ "$split_dir" == "V" ]]; then
                split_dir="H"
            else
                split_dir="V"
            fi
            
            # Brief sleep to ensure ConEmu processes the hook
            sleep 0.5
        done
    done
    
    echo "========================================"
    echo "Grid deployment complete for $env."
}
