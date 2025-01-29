# vLLM
[vLLM](https://vllm.readthedocs.io/en/latest/) is a fast and easy-to-use library for LLM inference and serving.
vLLM is fast with:
* State-of-the-art serving throughput
* Efficient management of attention key and value memory with PagedAttention
* Continuous batching of incoming requests
This README provides instructions on how to install and use vLLM version `0.6.6` on Polaris.

## Request a Compute node
```bash
qsub -I -A <project> -q debug -l select=1 -l walltime=01:00:00 -l filesystems=home:eagle
```

## Installation
To install vLLM on Polaris on a compute node, run the following
```bash
module use /soft/modulefiles/
module load conda
conda create -p /grand/datascience/atanikanti/envs/vllm_v066_env python==3.10.12 -y
conda activate /grand/datascience/atanikanti/envs/vllm_v066_env
module use /soft/spack/base/0.8.1/install/modulefiles/Core
module load gcc
pip install vllm
```

## Usage
To use vLLM, you can do one of the following:

### Run on compute node and query the model

Run the following commands to run vllm on a compute node

```bash
module use /soft/modulefiles
module load conda
conda activate <path_to_conda_environment> #change path
module use /soft/spack/base/0.8.1/install/modulefiles/Core
module load gcc
export HF_DATASETS_CACHE="/eagle/argonne_tpc/model_weights/"
export HF_HOME="/eagle/argonne_tpc/model_weights/"
export RAY_TMPDIR="/tmp"
export RAYON_NUM_THREADS=4
export RUST_BACKTRACE=1
export VLLM_WORKER_MULTIPROC_METHOD=fork
export PROMETHEUS_MULTIPROC_DIR="/tmp"
export VLLM_RPC_BASE_PATH="/tmp"
export no_proxy="127.0.0.1,localhost"
vllm serve meta-llama/Meta-Llama-3-8B-Instruct --host 127.0.0.1 --tensor-parallel-size 4 --gpu-memory-utilization 0.98 --enforce-eager #For online serving
```

An alternative is to run vLLM in the background on the compute node. Check `nohup.out` for logs and ensure model is up and running
```bash
nohup vllm serve meta-llama/Meta-Llama-3-8B-Instruct --host 127.0.0.1 --tensor-parallel-size 4 --gpu-memory-utilization 0.98 --enforce-eager &
```
 
To now interact with the model run [openai_client.py](openai_client.py) or ssh tunnel from a login node as follows
```bash
bash tunnel.sh
python3 vllm_client.py # or use curl see `curl.sh`
```

:bulb: **Note:** You can run `python3 vllm_client.py -h` to view all available options
:bulb: **Note:** Ensure you `chmod +x` all the bash scripts.

### Use Globus Compute to run vLLM remotely
Instructions in [vLLM_Inference.ipynb](vLLM_Inference.ipynb) notebook will guide you in triggering vllm inference runs remotely from your local machine using globus compute

### Use job submission scripts to run vLLM on Polaris
Use the [job_submission.sh](job_submission.sh) file to submit a batch job to run vllm on a compute node

```bash
qsub job_submission.sh
```
