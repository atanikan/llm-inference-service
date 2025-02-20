#! /bin/bash
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
conda activate vllm-sophia-env-072

# Set environment variables
export HF_DATASETS_CACHE='/eagle/argonne_tpc/model_weights/'
export HF_HOME='/eagle/argonne_tpc/model_weights/'
export RAY_TMPDIR='/tmp'
export TMPDIR='/tmp'
export NCCL_SOCKET_IFNAME='infinibond0'
export VLLM_IMAGE_FETCH_TIMEOUT=120
export HF_TOKEN='' # TODO: Add your HF token here

echo "Environment setup complete."