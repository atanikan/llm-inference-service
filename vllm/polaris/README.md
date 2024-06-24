# vLLM
[vLLM](https://vllm.readthedocs.io/en/latest/) is a fast and easy-to-use library for LLM inference and serving.
vLLM is fast with:
* State-of-the-art serving throughput
* Efficient management of attention key and value memory with PagedAttention
* Continuous batching of incoming requests
This README provides instructions on how to install and use vLLM version `0.4.2` on Polaris.

> **NOTE**: Current vLLM **does not** scale on more than one node (tensor-parallel-size>=4) on Polaris for models with large footprint like Llama70B. We are working on fixing this.

## Installation
To install vLLM on Polaris, run the following
```bash
module use /soft/modulefiles/
module load conda
conda create -p /grand/datascience/atanikanti/envs/vllm_v050_env python==3.10.12 -y
conda activate /grand/datascience/atanikanti/envs/vllm_v050_env
module use /soft/spack/base/0.7.1/install/modulefiles/Core
module load gcc/11.4.0
module load cudatoolkit-standalone
pip install vllm
```

## Usage
To use vLLM, you can do one of the following:

### Use Globus Compute to run vLLM remotely
Instructions in [vLLM_Inference.ipynb](vLLM_Inference.ipynb) notebook will guide you in triggering vllm inference runs remotely from your local machine using globus compute

### Use job submission scripts to run vLLM on Polaris
Use the [job_submission.sh](job_submission.sh) file to submit a batch job to run vllm on a compute node

```bash
qsub job_submission.sh
```

### Use interactive mode on Polaris to run vLLM on compute node
Run the following commands to run vllm interactively on a compute node
```bash
qsub -I -A <project> -q debug -l select=1 -l walltime=01:00:00 -l filesystems=home:grand
module use /soft/modulefiles
module load conda
conda activate <path_to_conda_environment> #change path
module use /soft/spack/base/0.7.1/install/modulefiles/Core
module load gcc/11.4.0
module load cudatoolkit-standalone
export HF_DATASETS_CACHE="/eagle/argonne_tpc/model_weights/"
export HF_HOME="/eagle/argonne_tpc/model_weights/"
export RAY_TMPDIR="/tmp"
export RAYON_NUM_THREADS=4
export RUST_BACKTRACE=1
export VLLM_WORKER_MULTIPROC_METHOD=fork
python3 -m vllm.entrypoints.openai.api_server --model meta-llama/Meta-Llama-3-70B-Instruct --host 0.0.0.0 --tensor-parallel-size 4 --gpu-memory-utilization 0.95 --enforce-eager # for the default facebook/opt-125m model just run python -m vllm.entrypoints.api_server
```

Just run [tunnel.sh](tunnel.sh) to establish a ssh tunnel to the remote node from a login node followed by running the [vllm_client.py](vllm_client.py) to query the running model. You can alternatively use [curl.sh](curl.sh).

```bash
bash tunnel.sh
python3 vllm_client.py # or use curl see `curl.sh`
```

:bulb: **Note:** You can run `python3 vllm_client.py -h` to view all available options
:bulb: **Note:** Ensure you `chmod +x` all the bash scripts.