#!/bin/bash -l
#PBS -l select=8:system=polaris
#PBS -l place=scatter
#PBS -l walltime=00:60:00
#PBS -l filesystems=home:eagle
#PBS -q debug
#PBS -A datascience

echo Working directory is $PBS_O_WORKDIR
cd $PBS_O_WORKDIR

echo Jobid: $PBS_JOBID
echo Running on host `hostname`

# Initialize environment
export TMPDIR=/tmp

# Source the common script
source setup_ray_and_vllm.sh

# Setup the environment
setup_environment

# Read nodes from PBS_NODEFILE
nodes=($(sort -u "$PBS_NODEFILE"))
num_nodes=${#nodes[@]}

# Get the current node's hostname (assumed to be the head node)
head_node=$(hostname | sed 's/.lab.alcf.anl.gov//')

echo "Nodes: ${nodes[@]}"
echo "Head node: $head_node"

# Get the IP address of the head node
RAY_HEAD_IP=$(getent hosts "$head_node" | awk '{ print $1 }')
echo "Ray head IP: $RAY_HEAD_IP"

# Export variables for use in functions
export head_node
export RAY_HEAD_IP
export HOST_IP="$RAY_HEAD_IP"
export RAY_ADDRESS="$RAY_HEAD_IP:6379"

# Define worker nodes (exclude head node)
worker_nodes=()
for node in "${nodes[@]}"; do
    short_node=$(echo "$node" | sed 's/.lab.alcf.anl.gov//')
    if [ "$short_node" != "$head_node" ]; then
        worker_nodes+=("$short_node")
    fi
done

echo "Worker nodes: ${worker_nodes[@]}"

# Stop Ray on all nodes using mpiexec
echo "Stopping any existing Ray processes on all nodes..."
mpiexec -n "$num_nodes" -hostfile "$PBS_NODEFILE" bash -c "source $COMMON_SETUP_SCRIPT; setup_environment; stop_ray; cleanup_python_processes;"

# Start Ray head node
echo "Starting Ray head node..."
mpiexec -n 1 -host "$head_node" bash -l -c "source $COMMON_SETUP_SCRIPT; export RAY_HEAD_IP=$RAY_HEAD_IP; setup_environment; start_ray_head"

echo "Starting Ray worker nodes..."
for worker in "${worker_nodes[@]}"; do
    echo "Starting Ray worker on $worker"
    mpiexec -n 1 -host "$worker" bash -l -c "source $COMMON_SETUP_SCRIPT; export RAY_HEAD_IP=$RAY_HEAD_IP; setup_environment; start_ray_worker"
done

# Verify Ray cluster status
echo "Verifying Ray cluster status..."
verify_ray_cluster "$num_nodes"

echo "Ray cluster setup complete."

# Define model parameters
model_name="meta-llama/Meta-Llama-3.1-405B-Instruct"
framework="vllm"
cluster="sophia"
model_command="vllm serve ${model_name} --host 127.0.0.1 --port 8000 \
--tensor-parallel-size 4 --pipeline-parallel-size 8  \
--disable-log-stats --enable-chunked-prefill --multi-step-stream-outputs False \
--trust-remote-code --gpu-memory-utilization 0.95 --disable-log-requests"
log_file="$PWD/logfile_sophia-vllm-${model_name}_$(hostname).log"

# Initialize retry counter for the model
retry_counter_model_1=0

# Start the model
while true; do
    echo "Starting models sequence..."
    if ! start_model "$model_name" "$model_command" "$log_file" retry_counter_model_1; then
        continue  # Restart from the beginning if this fails
    fi
    echo "All models started successfully."
    break
done


# Run your client script to interact with the running model

