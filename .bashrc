function tail_grid() {
    local env="$1"
    local pod_pattern="$2"
    
    if [[ -z "$env" || -z "$pod_pattern" ]]; then
        echo "Usage: tail_grid <prod|np> <pod-name-pattern>"
        return 1
    fi

    local cluster_urls=()
    case "$env" in
        prod)
            cluster_urls=("https://prod-1" "https://prod-2" "https://prod-3" "https://prod-4")
            ;;
        np)
            cluster_urls=("https://np-1" "https://np-2" "https://np-3" "https://np-4")
            ;;
        *)
            echo "Error: Use 'prod' or 'np'."
            return 1
            ;;
    esac

    for i in "${!cluster_urls[@]}"; do
        local url="${cluster_urls[$i]}"
        echo "----------------------------------------"
        echo "Logging into Cluster $((i+1)): $url"
        
        oc login "$url" --insecure-skip-tls-verify=true > /dev/null
        local current_ctx=$(kubectl config current-context)
        
        # Find up to 4 pods matching the pattern for this cluster
        local pods=$(kubectl get pods -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -i "$pod_pattern" | head -n 4)

        if [[ -z "$pods" ]]; then
            echo "No pods found in cluster $url"
            continue
        fi

        local p_idx=0
        for pod in $pods; do
            # Define the log command with context locking
            local cmd="kubectl --context=$current_ctx logs -f $pod; echo 'Stream ended'; read"
            
            if [[ $i -eq 0 && $p_idx -eq 0 ]]; then
                # The very first pod of the first cluster runs in the main pane
                echo "Starting first pod in main pane..."
                eval "$cmd" & 
            else
                # Logic for grid placement:
                # If it's the first pod of a NEW cluster, split Vertically (New Column)
                # If it's a subsequent pod in the SAME cluster, split Horizontally (New Row)
                local split_type="sH"
                if [[ $p_idx -eq 0 ]]; then
                    split_type="sV"
                fi

                echo "Spawning $split_type for $pod..."
                bash -c "$cmd" "-new_console:$split_type"
                sleep 0.8 # Essential for ConEmu to finish the UI render before the next split
            fi
            ((p_idx++))
        done
    done
    
    echo "----------------------------------------"
    echo "4x4 Grid Deployment Complete."
}
