#!/bin/bash -l

# Exit on error
set -e

# Function to print verbose messages
log_verbose() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to set up environment
setup_environment() {
    local conda_env="$1"
    log_verbose "Setting up environment with conda environment: $conda_env"

    # Load modules
    log_verbose "Loading modules..."
    if ! module use /soft/modulefiles 2>/dev/null; then
        log_verbose "Warning: Failed to use module path /soft/modulefiles, continuing..."
    fi
    if ! module load conda 2>/dev/null; then
        log_verbose "Error: Failed to load conda module"
        exit 1
    fi
    log_verbose "Conda module loaded"

    # Explicitly source conda initialization
    log_verbose "Sourcing conda initialization..."
    local conda_base="/soft/applications/conda/2024-04-29/mconda3"
    local conda_sh="$conda_base/etc/profile.d/conda.sh"
    if [ -f "$conda_sh" ]; then
        source "$conda_sh"
        log_verbose "Sourced conda.sh from $conda_sh"
    else
        log_verbose "Error: Failed to find conda.sh at $conda_sh"
        exit 1
    fi

    # Check if conda_env is a path; if so, use it directly, else treat as name
    local conda_env_name
    if [[ "$conda_env" == /* ]]; then
        if [ -d "$conda_env" ]; then
            conda_env_name="$conda_env"
            log_verbose "Using environment path: $conda_env_name"
        else
            conda_env_name=$(basename "$conda_env")
            log_verbose "Interpreting $conda_env as path, using environment name: $conda_env_name"
        fi
    else
        conda_env_name="$conda_env"
        log_verbose "Using environment name: $conda_env_name"
    fi

    # Verify environment exists
    if ! conda env list | grep -q "$conda_env_name"; then
        log_verbose "Error: Conda environment $conda_env_name not found in 'conda env list'"
        conda env list
        exit 1
    fi

    # Activate conda environment
    log_verbose "Activating conda environment: $conda_env_name"
    conda activate "$conda_env_name" || {
        log_verbose "Error: Failed to activate conda environment: $conda_env_name"
        exit 1
    }

    # Set environment variables
    log_verbose "Setting environment variables"
    export RAY_TMPDIR="/tmp"
    export PROMETHEUS_MULTIPROC_DIR="/tmp"
    export OMP_NUM_THREADS=64
    # Optional proxy settings (uncomment if needed)
    # export HTTP_PROXY="http://proxy.alcf.anl.gov:3128"
    # export HTTPS_PROXY="http://proxy.alcf.anl.gov:3128"
    # export http_proxy="http://proxy.alcf.anl.gov:3128"
    # export https_proxy="http://proxy.alcf.anl.gov:3128"
    # export ftp_proxy="http://proxy.alcf.anl.gov:3128"

    log_verbose "Environment setup complete"
}

# Function to stop Ray
stop_ray() {
    log_verbose "Stopping Ray on $(hostname)"
    ray stop -f 2>/dev/null || true
    log_verbose "Ray stopped on $(hostname)"
}

# Function to start Ray head node
start_ray_head() {
    local ray_port=6379
    local head_ip="$1"
    local log_dir="ray_logs"
    local log_file="$log_dir/ray_head_$(hostname).log"

    log_verbose "Starting Ray head on $(hostname) with IP $head_ip:$ray_port"
    mkdir -p "$log_dir"
    touch "$log_file"
    > "$log_file"

    ray start --head --port="$ray_port" --node-ip-address="$head_ip" --redis-password='ray' --num-cpus=64 --num-gpus=$(nvidia-smi -L | wc -l 2>/dev/null || echo 0) > "$log_file" 2>&1
    local pid=$!
    log_verbose "Ray head started with PID $pid. Logs at $log_file"

    # Wait briefly to ensure head node starts
    sleep 10
    log_verbose "Checking Ray head status..."
    if ray status &>/dev/null; then
        log_verbose "Ray head is up: $(ray status | head -n 5)"
    else
        log_verbose "Ray head failed to start. Check logs at $log_file"
        exit 1
    fi
}

# Function to start Ray worker node
start_ray_worker() {
    local head_ip="$1"
    local ray_port=6379
    local log_dir="ray_logs"
    local log_file="$log_dir/ray_worker_$(hostname).log"

    log_verbose "Starting Ray worker on $(hostname), connecting to $head_ip:$ray_port"
    mkdir -p "$log_dir"
    touch "$log_file"
    > "$log_file"

    # Get the IP address of hsn0 on the current (worker) node
    local worker_ip
    worker_ip=$(ip -4 addr show hsn0 | grep inet | awk '{print $2}' | cut -d'/' -f1)
    if [ -z "$worker_ip" ]; then
        log_verbose "Error: Could not determine IP address for hsn0 on worker node $(hostname)"
        exit 1
    fi
    log_verbose "Worker IP (hsn0) on $(hostname) is $worker_ip"

    # Test connectivity to head node first
    log_verbose "Testing connectivity to Ray head at $head_ip:$ray_port"
    if ! timeout 10 bash -c "echo >/dev/tcp/$head_ip/$ray_port" 2>/dev/null; then
        log_verbose "Warning: Cannot connect to Ray head at $head_ip:$ray_port"
    else
        log_verbose "Successfully connected to Ray head at $head_ip:$ray_port"
    fi

    # Start the worker with more verbose logging and proper CPU count
    log_verbose "Executing: ray start --address=$head_ip:$ray_port --redis-password=ray --node-ip-address=$worker_ip --num-cpus=64 --num-gpus=$(nvidia-smi -L | wc -l 2>/dev/null || echo 0)"
    ray start --address="$head_ip:$ray_port" --redis-password='ray' --node-ip-address="$worker_ip" --num-cpus=64 --num-gpus=$(nvidia-smi -L | wc -l 2>/dev/null || echo 0) --verbose > "$log_file" 2>&1
    local pid=$!
    log_verbose "Ray worker started with PID $pid. Logs at $log_file"

    # Wait longer for worker to connect and stabilize
    sleep 10

    # Set RAY_ADDRESS for this worker node to check status
    export RAY_ADDRESS="$head_ip:$ray_port"

    if ray status &>/dev/null; then
        log_verbose "Ray worker connection verified on $(hostname)"
    else
        log_verbose "Warning: Ray worker on $(hostname) may not have connected properly. Check logs at $log_file"
        # Print last few lines of log for debugging
        if [ -f "$log_file" ]; then
            log_verbose "Last 10 lines from $log_file:"
            tail -10 "$log_file" | while read line; do
                log_verbose "  $line"
            done
        fi
    fi
}

# Function to check Ray cluster status
check_ray_status() {
    log_verbose "Checking Ray cluster status..."

    # Get expected number of nodes and GPUs
    local num_nodes=$(sort -u "$PBS_NODEFILE" | wc -l)
    local expected_gpus=0

    # Calculate total expected CPUs and GPUs from all nodes
    log_verbose "Calculating expected CPU and GPU count from $num_nodes nodes..."
    local expected_cpus=0
    for node in $(sort -u "$PBS_NODEFILE"); do
        local short_node=$(echo "$node" | sed 's/\..*//')
        local node_gpus=$(mpiexec -n 1 -host "$short_node" bash -c "nvidia-smi -L | wc -l 2>/dev/null || echo 0")
        local node_cpus=64  # Hardcoded since we know Polaris nodes have 64 cores
        log_verbose "Node $short_node has $node_cpus CPUs, $node_gpus GPUs"
        expected_gpus=$((expected_gpus + node_gpus))
        expected_cpus=$((expected_cpus + node_cpus))
    done

    log_verbose "Expected total CPUs: $expected_cpus, GPUs: $expected_gpus from $num_nodes nodes"

    # Get actual Ray cluster status
    if ray status &>/dev/null; then
        local ray_status_output=$(ray status)
        log_verbose "Ray cluster status:"
        echo "$ray_status_output"

        # Extract CPU and GPU counts from ray status (handle both integer and decimal formats)
        local actual_cpus_raw=$(echo "$ray_status_output" | grep -E "^.*CPU$" | awk '{print $1}' | sed 's/.*\///')
        local actual_cpus=$(echo "$actual_cpus_raw" | cut -d'.' -f1)  # Convert to integer
        local actual_gpus_raw=$(echo "$ray_status_output" | grep -E "^.*GPU$" | awk '{print $1}' | sed 's/.*\///')
        local actual_gpus=$(echo "$actual_gpus_raw" | cut -d'.' -f1)  # Convert to integer
        local actual_nodes=$(echo "$ray_status_output" | grep -c "node_")

        log_verbose "Ray cluster shows: $actual_nodes nodes, $actual_cpus CPUs (raw: $actual_cpus_raw), $actual_gpus GPUs (raw: $actual_gpus_raw)"

        # Use integer comparison for all values
        if [ "$actual_gpus" -eq "$expected_gpus" ] && [ "$actual_nodes" -eq "$num_nodes" ] && [ "$actual_cpus" -eq "$expected_cpus" ]; then
            log_verbose "✓ Ray cluster status matches expected configuration"
            return 0
        else
            log_verbose "✗ Ray cluster mismatch - Expected: $num_nodes nodes/$expected_cpus CPUs/$expected_gpus GPUs, Got: $actual_nodes nodes/$actual_cpus CPUs/$actual_gpus GPUs"
            return 1
        fi
    else
        log_verbose "✗ Ray cluster is not accessible"
        return 1
    fi
}

# Main script
main() {
    # Check for check command
    if [ $# -eq 1 ] && [ "$1" == "check" ]; then
        log_verbose "Running Ray cluster status check..."
        if [ ! -f "$PBS_NODEFILE" ]; then
            log_verbose "Error: PBS_NODEFILE not found"
            exit 1
        fi
        check_ray_status
        exit $?
    fi

    # Check for conda environment argument
    if [ $# -ne 1 ]; then
        log_verbose "Error: Conda environment name or path must be provided"
        echo "Usage: $0 <conda_env_name_or_path>"
        echo "       $0 check  # Check Ray cluster status"
        exit 1
    fi
    local conda_env="$1"
    local script_path=$(realpath "$0")

    # Ensure PBS_NODEFILE exists
    if [ ! -f "$PBS_NODEFILE" ]; then
        log_verbose "Error: PBS_NODEFILE not found"
        exit 1
    fi

    # Get the number of nodes (unique hostnames in PBS_NODEFILE)
    local num_nodes=$(sort -u "$PBS_NODEFILE" | wc -l)
    log_verbose "Number of nodes allocated: $num_nodes"

    # Get the head node (first node in PBS_NODEFILE)
    local head_node=$(head -n 1 "$PBS_NODEFILE" | sed 's/\..*//')
    log_verbose "Head node: $head_node"

    # Get the IP address of hsn0 on the current node
    local head_ip=$(ip -4 addr show hsn0 | grep inet | awk '{print $2}' | cut -d'/' -f1)
    if [ -z "$head_ip" ]; then
        log_verbose "Error: Could not determine IP address for hsn0"
        exit 1
    fi
    log_verbose "Head node IP (hsn0): $head_ip"

    # Export variables for mpiexec
    export RAY_HEAD_IP="$head_ip"
    export RAY_ADDRESS="$head_ip:6379"

    # Set up environment
    setup_environment "$conda_env"

    # Stop any existing Ray processes
    log_verbose "Cleaning up existing Ray processes"
    stop_ray
    log_verbose "Stopping Ray on all nodes with mpiexec"
    local cmd="source '$script_path'; export CONDA_ENV='$conda_env'; export RAY_HEAD_IP='$head_ip'; setup_environment '$conda_env'; stop_ray"
    log_verbose "Executing mpiexec command: mpiexec -n $num_nodes -hostfile $PBS_NODEFILE bash -l -c \"$cmd\""
    mpiexec -n "$num_nodes" -hostfile "$PBS_NODEFILE" bash -l -c "$cmd" || {
        log_verbose "Warning: mpiexec for stopping Ray processes failed, continuing..."
    }

    # Start Ray head node on the current node if it's the head node
    if [ "$(hostname | sed 's/\..*//')" == "$head_node" ]; then
        start_ray_head "$head_ip"
    fi

    # Define worker nodes (exclude head node)
    local worker_nodes=()
    for node in $(tail -n +2 "$PBS_NODEFILE" | sort -u); do
        short_node=$(echo "$node" | sed 's/\..*//')
        worker_nodes+=("$short_node")
    done
    log_verbose "Worker nodes: ${worker_nodes[*]}"

    # Start Ray worker nodes with proper environment and keepalive
    log_verbose "Starting Ray worker nodes with mpiexec"
    for worker in "${worker_nodes[@]}"; do
        log_verbose "Starting Ray worker on $worker"
        local cmd="source '$script_path'; export CONDA_ENV='$conda_env'; export RAY_HEAD_IP='$head_ip'; export RAY_ADDRESS='$head_ip:6379'; setup_environment '$conda_env'; start_ray_worker '$head_ip'"
        log_verbose "Executing mpiexec command: mpiexec -n 1 -host $worker bash -l -c \"$cmd\""
        mpiexec -n 1 -host "$worker" bash -l -c "$cmd" || {
            log_verbose "Error: mpiexec for starting Ray worker on $worker failed. Check logs in ray_logs/"
            exit 1
        }
        sleep 8  # Increased delay to allow worker to connect properly
    done

    # Wait longer for all workers to connect and stabilize, then do multiple status checks
    sleep 20
    log_verbose "Checking final Ray cluster status (attempt 1/3)..."
    if ! check_ray_status; then
        log_verbose "First status check failed, waiting and retrying..."
        sleep 10
        log_verbose "Checking final Ray cluster status (attempt 2/3)..."
        if ! check_ray_status; then
            log_verbose "Second status check failed, final attempt..."
            sleep 10
            log_verbose "Checking final Ray cluster status (attempt 3/3)..."
            check_ray_status
        fi
    fi

    log_verbose "Ray cluster started in the background. Logs are in ray_logs/ directory."
    log_verbose "RAY_ADDRESS set to: $RAY_ADDRESS"
    log_verbose "To verify the cluster, run: ray status"
    log_verbose "To check cluster health, run: $0 check"
    log_verbose "To stop the cluster, run: mpiexec -n $num_nodes -hostfile \$PBS_NODEFILE bash -c 'ray stop'"
}

# Execute main function with all arguments only if script is not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi