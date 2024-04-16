#!/bin/bash


# Determine the path to the conda environment
conda_env_path=""
if [ $# -eq 1 ]; then
    # Use the provided argument as the conda environment path
    conda_env_path=$1
elif [ -n "$CONDA_PREFIX" ]; then
    # Use the currently active conda environment
    conda_env_path=$CONDA_PREFIX
else
    echo "No conda environment provided and no active environment found. Please activate a conda environment or provide one as an argument."
    exit 1
fi

# Read IPs from $PBS_NODEFILE
if [ -z "$PBS_NODEFILE" ] || [ ! -f "$PBS_NODEFILE" ]; then
    echo "PBS_NODEFILE is not set or does not point to a valid file."
    exit 1
fi

# Read head and worker nodes' IP addresses
head_ip=$(sed -n '1p' "$PBS_NODEFILE")
worker_ips=$(sed '1d;s/$/,/;H;$!d;x;s/\n//g;s/,$//' "$PBS_NODEFILE")

# Get current user
ssh_user=$(whoami)

# Number of workers
min_workers=$(grep -c . "$PBS_NODEFILE")
min_workers=$((min_workers - 1)) # Subtracting head node

# Current datetime for file naming
#current_datetime=$(date '+%Y%m%d_%H%M%S')

# New YAML file name
yaml_file="ray_cluster.yaml"

# Write to the new YAML file
cat << EOF > $yaml_file
# Auto-generated YAML file
cluster_name: ray_multi_node

provider:
    type: local
    head_ip: $head_ip
    worker_ips: [$worker_ips]

auth:
    ssh_user: $ssh_user

min_workers: $min_workers
upscaling_speed: 1.0
idle_timeout_minutes: 5

cluster_synced_files: []

setup_commands: []

head_setup_commands: []

worker_setup_commands: []

head_start_ray_commands:
  - module load conda && conda activate $conda_env_path && ray stop --force
  - module load conda && conda activate $conda_env_path && ray start --head --port=6379 --object-manager-port=8076 --temp-dir=/tmp --autoscaling-config=~/ray_bootstrap_config.yaml

worker_start_ray_commands:
  - module load conda && conda activate $conda_env_path && ray stop --force
  - sleep 30 && module load conda && conda activate $conda_env_path && ray start --address=\$RAY_HEAD_IP:6379 --temp-dir=/tmp
EOF
# Start ray cluster
ray up $yaml_file -y && sleep 60

# Set RAY_ADDRESS so that when the user runs vllm it will connect to this cluster and not start a new one
export RAY_ADDRESS="$head_ip:6379"
