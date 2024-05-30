#!/bin/bash -l
#PBS -l select=1:system=polaris
#PBS -l place=scatter
#PBS -l walltime=00:60:00
#PBS -l filesystems=home:eagle
#PBS -q debug
#PBS -A datascience

echo Working directory is $PBS_O_WORKDIR
cd $PBS_O_WORKDIR

echo Jobid: $PBS_JOBID
echo Running on host `hostname`

# User Configuration
NNODES=$(wc -l < ${PBS_NODEFILE})
NGPU_PER_NODE=$(nvidia-smi -L | wc -l)
NGPUS=$((${NNODES}*${NGPU_PER_NODE}))
echo "NUM_OF_NODES= ${NNODES} TOTAL_NUM_GPUS= ${NGPUS} GPUS_PER_NODE= ${NGPU_PER_NODE}"

# Initialize environment
export TMPDIR=/tmp

module use /soft/modulefiles/
module load conda/2024-04-29 
conda activate /grand/datascience/atanikanti/envs/vllm_env 
#echo "Activated environment: $(conda info --envs | grep '*')"
pip list | grep ray
#echo "PATH: $PATH"


# execute the script
# run your script here

export HOST_IP=$(sed -n '1p' "$PBS_NODEFILE")
export HF_DATASETS_CACHE="/eagle/argonne_tpc/model_weights/"
export HF_HOME="/eagle/argonne_tpc/model_weights/"
export RAY_TMPDIR="/tmp"
python3 vllm_batch.py --tensor_parallel_size=4
#python -m vllm.entrypoints.api_server --model meta-llama/Llama-2-70b-chat-hf --trust-remote-code --tensor-parallel-size 4 --tokenizer hf-internal-testing/llama-tokenizer --host localhost --download-dir /grand/datascience/atanikanti/vllm_service
