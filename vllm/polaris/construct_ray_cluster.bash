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

#export RAY_ADDRESS=$head_ip 

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
  - module use /soft/modulefiles/ && module load conda && conda activate $conda_env_path && ray stop --force
  - module use /soft/modulefiles/ && module load conda && conda activate $conda_env_path && ray start --head --port=6379 --object-manager-port=8076 --temp-dir=/tmp --autoscaling-config=~/ray_bootstrap_config.yaml

worker_start_ray_commands:
  - module use /soft/modulefiles/ && module load conda && conda activate $conda_env_path && ray stop --force
  - sleep 30 && module use /soft/modulefiles/ && module load conda && conda activate $conda_env_path && ray start --address=\$RAY_HEAD_IP:6379 --temp-dir=/tmp

EOF

# Start ray cluster
# Check if the current node is the head node
current_node=$(hostname -f) # or $(hostname -i) for IP address
echo "I am on host $current_node and head ip is $head_ip"
if [ "$current_node" = "$head_ip" ]; then
    # Start ray cluster
    ray up $yaml_file -y && sleep 60 && ray status
else
    echo "This script is not running on the head node. ray up should be executed on the head node."
fi

export HOST_IP="$head_ip"
export RAY_ADDRESS="$head_ip:6379"
export HF_DATASETS_CACHE="/eagle/argonne_tpc/model_weights/"
export HF_HOME="/eagle/argonne_tpc/model_weights/"
export RAY_TMPDIR="/tmp"
export HTTP_PROXY="http://proxy.alcf.anl.gov:3128"
export HTTPS_PROXY="http://proxy.alcf.anl.gov:3128"
export http_proxy="http://proxy.alcf.anl.gov:3128"
export https_proxy="http://proxy.alcf.anl.gov:3128"
