#!/bin/bash
##############################
# Environment Setup Function #
##############################
setup_environment() {
    echo "Setting up the environment..."

    # Set proxy configurations
    export HTTP_PROXY="http://proxy.alcf.anl.gov:3128"
    export HTTPS_PROXY="http://proxy.alcf.anl.gov:3128"
    export http_proxy="http://proxy.alcf.anl.gov:3128"
    export https_proxy="http://proxy.alcf.anl.gov:3128"
    export ftp_proxy="http://proxy.alcf.anl.gov:3128"

    # Load modules and activate the conda environment
    source /etc/profile.d/modules.sh
    source /etc/profile  # Initialize environment properly
    module use /soft/modulefiles
    module load conda

    # Source the Conda initialization script directly
    conda activate <replace>

    # Set environment variables
    export HF_DATASETS_CACHE='/eagle/argonne_tpc/model_weights/'
    export HF_HOME='/eagle/argonne_tpc/model_weights/'
    export RAY_TMPDIR='/tmp'
    export OMP_NUM_THREADS=4
    export VLLM_IMAGE_FETCH_TIMEOUT=60
    export PROMETHEUS_MULTIPROC_DIR="/tmp"
    export VLLM_RPC_BASE_PATH="/tmp"
    export HF_TOKEN= #replace with your token
    ulimit -c unlimited

    # Set path to common setup script
    export COMMON_SETUP_SCRIPT='setup_ray_and_vllm.sh' # <path to this script>

    echo "Environment setup complete."
}


################################
# Cleanup Python Processes     #
################################
cleanup_python_processes() {
    echo "Cleaning up existing Python processes..."

    # Define patterns to kill
    local patterns=("vllm serve" "multiprocessing.spawn" "multiprocessing.resource_tracker")

    for pattern in "${patterns[@]}"; do
        pids=$(pgrep -f "$pattern")
        for pid in $pids; do
            echo "Killing process $pid ($pattern)"
            kill -9 "$pid" 2>/dev/null || true
        done
    done

    # Kill all Python processes owned by the current user
    pids=$(pgrep -u "$USER" python)
    for pid in $pids; do
        echo "Killing Python process $pid"
        kill -9 "$pid" 2>/dev/null || true
    done

    sleep 5  # Give some time for processes to terminate

    # Force kill any remaining processes (second pass just in case)
    for pattern in "${patterns[@]}"; do
        pids=$(pgrep -f "$pattern")
        for pid in $pids; do
            echo "Force killing process $pid ($pattern)"
            kill -9 "$pid" 2>/dev/null || true
        done
    done

    pids=$(pgrep -u "$USER" python)
    for pid in $pids; do
        echo "Force killing Python process $pid"
        kill -9 "$pid" 2>/dev/null || true
    done

    echo "Cleanup complete."
}


################################
# Start Model Function          #
################################

################################
# Start Model Function          #
################################
start_model() {
    local model_name="$1"
    local command="$2"
    local log_file="$3"
    local -n attempt_counter_ref="$4"  # Pass by reference for attempt counter
    local max_attempts=2
    local timeout=3600  # Default timeout (can be parameterized)

    while [ "$attempt_counter_ref" -lt "$max_attempts" ]; do
        attempt_counter_ref=$((attempt_counter_ref + 1))
        echo "Starting $model_name (Attempt $attempt_counter_ref of $max_attempts)"

        # Start the model in the background
        log_dir="$(dirname "$log_file")"
        # Create the directory if it doesn’t exist
        mkdir -p "$log_dir"

        # Create an empty file if it doesn't already exist
        touch "$log_file"
        > "$log_file"

        nohup bash -c "$command" > "$log_file" 2>&1 &
        local pid=$!

        local start_time=$(date +%s)
        while true; do
            if [[ -f "$log_file" ]] && grep -q "INFO:     Application startup complete." "$log_file"; then
                echo "$model_name started successfully"
                return 0
            fi

            local current_time=$(date +%s)
            local elapsed_time=$((current_time - start_time))

            if [ "$elapsed_time" -ge "$timeout" ]; then
                echo "Timeout reached for $model_name. Killing process."
                kill -9 "$pid" 2>/dev/null || true
                break
            fi

            sleep 5
        done

        echo "Failed to start $model_name. Cleaning up and retrying..." | tee -a error_log.txt
        cleanup_python_processes
    done

    echo "Failed to start $model_name after $max_attempts attempts" | tee -a error_log.txt
    exit 1
}


################################
# Ray Management Functions     #
################################

# Function to stop Ray
stop_ray() {
    echo "Stopping Ray on $(hostname)"
    ray stop -f
}


# Function to start Ray head node
start_ray_head() {
    set -x  # Enable command echo for debugging

    current_node=$(hostname)
    ray_port=6379

    echo "Starting Ray head on $current_node"
    # Start Ray head node
    ray start --num-cpus=64 --num-gpus=4 --head --port=$ray_port
    # Wait for Ray head to be up
    echo "Waiting for Ray head to be up..."
    until ray status &>/dev/null; do
        sleep 5
        echo "Waiting for Ray head..."
    done
    echo "ray status: $(ray status)"
    echo "Ray head node is up."
}

# Function to start Ray worker node
start_ray_worker() {
    set -x  # Enable command echo for debugging

    current_node=$(hostname)
    ray_port=6379

    # Debug: Echo OMP_NUM_THREADS and hostname
    echo "OMP_NUM_THREADS on $current_node: $OMP_NUM_THREADS"

    echo "Starting Ray worker on $current_node, connecting to $RAY_HEAD_IP:$ray_port"
    # Start Ray worker node
    ray start --num-gpus=4 --num-cpus=64 --address=$RAY_HEAD_IP:$ray_port

    # Wait for Ray worker to be up
    echo "Waiting for Ray worker to be up..."
    until ray status &>/dev/null; do
        sleep 5
        echo "Waiting for Ray worker..."
    done

    echo "ray status: $(ray status)"
    echo "Ray worker node is up."
}



# Function to verify Ray cluster status
verify_ray_cluster() {
    local expected_nodes="$1"
    local attempts=0
    local max_retries=2

    while [ $attempts -le $max_retries ]; do
        echo "Verifying Ray cluster status (Attempt $((attempts + 1)))..."

        # Extract active nodes count from ray status
        actual_nodes=$(ray status | awk '
            /^Node status/ { in_active=0 }
            /^Active:/ { in_active=1; next }
            /^Pending:/ { in_active=0 }
            in_active && /^ *[0-9]+ node_/ { count++ }
            END { print count }
        ')

        if [ "$actual_nodes" -eq "$expected_nodes" ]; then
            echo "Ray cluster has the expected number of nodes: $actual_nodes"
            return 0
        else
            echo "Ray cluster has $actual_nodes active nodes, expected $expected_nodes."
            if [ $attempts -lt $max_retries ]; then
                echo "Attempting to restart Ray cluster..."

                # Stop Ray on all nodes
                echo "Stopping Ray on all nodes..."
                mpiexec -n "$expected_nodes" -hostfile "$PBS_NODEFILE" bash -c "source $COMMON_SETUP_SCRIPT; setup_environment; stop_ray"

                # Start Ray head node
                echo "Starting Ray head node..."
                mpiexec -n 1 -host "$head_node" bash -l -c "source $COMMON_SETUP_SCRIPT; setup_environment; start_ray_head"

                # Start Ray worker nodes
                echo "Starting Ray worker nodes..."
                for worker in "${worker_nodes[@]}"; do
                    echo "Starting Ray worker on $worker"
                    mpiexec -n 1 -host "$worker" bash -l -c "source $COMMON_SETUP_SCRIPT; setup_environment; start_ray_worker"
                done

                # Allow some time for Ray to initialize
                sleep 10
            fi
        fi
        attempts=$((attempts + 1))
    done

    echo "Ray cluster verification failed after $max_retries retries. Exiting."
    exit 1
}
