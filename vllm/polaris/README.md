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
conda create -n vllm_v071_env python==3.11.9 -y
conda activate vllm_v071_env
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
conda activate vllm_v071_env #change path
module use /soft/spack/base/0.8.1/install/modulefiles/Core
module load gcc
export HF_DATASETS_CACHE="/eagle/argonne_tpc/model_weights/"
export HF_HOME="/eagle/argonne_tpc/model_weights/"
export RAY_TMPDIR="/tmp"
export RAYON_NUM_THREADS=4
export RUST_BACKTRACE=1
export PROMETHEUS_MULTIPROC_DIR="/tmp"
export VLLM_RPC_BASE_PATH="/tmp"
export HF_TOKEN="" #Add your token
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


### Run multi node inference on models like Llama3.1-405B using vllm & ray. 
See [multi_node_inference_job_submission.sh](multi_node_inference_job_submission.sh) for running Llama3.1-405B on 8 Polaris nodes. Reduce context size etc to make it fit in memory with smaller number of nodes as needed. Modify the [setup_ray_and_vllm.sh](setup_ray_and_vllm.sh) file with appropriate values if needed. For e.g. `HF_TOKEN` with your hugging face token


### Use Globus Compute to run vLLM remotely
Instructions in [vLLM_Inference.ipynb](vLLM_Inference.ipynb) notebook will guide you in triggering vllm inference runs remotely from your local machine using globus compute

### Use job submission scripts to run vLLM on Polaris
Use the [job_submission.sh](job_submission.sh) file to submit a batch job to run vllm on a compute node

```bash
qsub job_submission.sh
```
