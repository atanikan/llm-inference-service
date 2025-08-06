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
conda activate vllm-sophia-env-latest

# Set environment variables
export HF_DATASETS_CACHE='/eagle/projects/argonne_tpc/model_weights/'
export HF_HOME='/eagle/projects/argonne_tpc/model_weights/'
export HF_HUB_CACHE='/eagle/argonne_tpc/model_weights/hub'
export RAY_TMPDIR='/tmp'
export TMPDIR='/tmp'
export HF_TOKEN='' # TODO: Add your HF token here
export RAY_TMPDIR='/tmp'
export NCCL_SOCKET_IFNAME='infinibond0'
export OMP_NUM_THREADS=4
export VLLM_IMAGE_FETCH_TIMEOUT=60
export USE_FASTSAFETENSOR='true'
ulimit -c unlimited

echo "Environment setup complete."
