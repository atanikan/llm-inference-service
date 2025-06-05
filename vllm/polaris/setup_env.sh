#!/bin/bash -l

# This script sets up the complete environment for running Ray and VLLM.
# It should be sourced by any script or command that needs this environment.
export VLLM_CONDA_PATH="/grand/datascience/atanikanti/envs/vllmv0.9.0.1"

# Proxy Configurations
export HTTP_PROXY="http://proxy.alcf.anl.gov:3128"
export HTTPS_PROXY="http://proxy.alcf.anl.gov:3128"
export http_proxy="http://proxy.alcf.anl.gov:3128"
export https_proxy="http://proxy.alcf.anl.gov:3128"
export ftp_proxy="http://proxy.alcf.anl.gov:3128"
export no_proxy="localhost,127.0.0.1"

# VLLM and HuggingFace Cache
export HF_DATASETS_CACHE='/eagle/argonne_tpc/model_weights/'
export HF_HOME='/eagle/argonne_tpc/model_weights/'
export HF_TOKEN= # TODO: replace with your token
# The HF_TOKEN should be exported in the main job submission script before this is sourced if needed.

# System and Performance
export RAY_TMPDIR='/tmp'
export TMPDIR='/tmp'
export OMP_NUM_THREADS=4
export PROMETHEUS_MULTIPROC_DIR="/tmp"
ulimit -c unlimited

# VLLM Specific
export VLLM_IMAGE_FETCH_TIMEOUT=60
export VLLM_RPC_BASE_PATH="/tmp"

# Module and Conda Setup
# Sourcing these system files is critical for ensuring that commands like `module`
# are available in non-interactive shells, such as those initiated by SSH.
[ -f /etc/profile.d/modules.sh ] && source /etc/profile.d/modules.sh
[ -f /etc/profile ] && source /etc/profile

module use /soft/modulefiles >/dev/null 2>&1
module load conda >/dev/null 2>&1
conda activate "$VLLM_CONDA_PATH"

