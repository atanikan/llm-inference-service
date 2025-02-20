# vLLM
[vLLM](https://vllm.readthedocs.io/en/latest/) is a fast and easy-to-use library for LLM inference and serving.
vLLM is fast with:
* State-of-the-art serving throughput
* Efficient management of attention key and value memory with PagedAttention
* Continuous batching of incoming requests
This README provides instructions on how to install and use vLLM version `0.5.1` on Sophia.




## Installation

```bash
qsub -I -A datascience -l walltime=03:00:00 -l filesystems=home:eagle -l select=16 -q workq -k doe -I
source /home/atanikanti/miniconda3/etc/profile.d/conda.sh
conda create -p ~/envs/vllm-sophia-env/ python==3.11 --y
conda activate  ~/envs/vllm-sophia-env/
pip install globus-compute-endpoint
pip install vllm
pip install ray[default]
#source /home/atanikanti/miniconda3/etc/profile.d/conda.sh && conda activate /grand/datascience/atanikanti/envs/vllm051-sophia-env && ray start --head --port=6379 --object-manager-port=8076 --temp-dir=/tmp --autoscaling-config=~/ray_bootstrap_config.yaml
#ssh sophia-gpu-04.lab.alcf.anl.gov
#source /home/atanikanti/miniconda3/etc/profile.d/conda.sh && conda activate /grand/datascience/atanikanti/envs/vllm051-sophia-env && ray stop --force && ray start --address='10.140.49.230:6379'
#exit
```

## Usage

On a single sophia node,

```bash
source /grand/datascience/atanikanti/miniconda3/etc/profile.d/conda.sh 
conda activate  /grand/datascience/atanikanti/envs/vllm-sophia-env/
export NCCL_DEBUG=INFO
export NCCL_NET_GDR_LEVEL=PHB
export NCCL_P2P_LEVEL=PXB
export NCCL_CROSS_NIC=1
export NCCL_COLLNET_ENABLE=1
export NCCL_SOCKET_IFNAME=infinibond0
export HF_DATASETS_CACHE="/eagle/argonne_tpc/model_weights/"
export HF_HOME="/eagle/argonne_tpc/model_weights/"
export RAY_TMPDIR="/tmp"
export HTTP_PROXY="http://proxy.alcf.anl.gov:3128"
export HTTPS_PROXY="http://proxy.alcf.anl.gov:3128"
export http_proxy="http://proxy.alcf.anl.gov:3128"
export https_proxy="http://proxy.alcf.anl.gov:3128"
python3 -m vllm.entrypoints.openai.api_server --model meta-llama/Meta-Llama-3-70B-Instruct --host 127.0.0.1 --tensor-parallel-size 8 --gpu-memory-utilization 0.95 --enforce-eager &
#FOR MULTINODE
#export NCCL_IB_DISABLE=1
#ray start --head --num-gpus 8 --num-cpus 128
#vllm serve meta-llama/Meta-Llama-3-70B-Instruct --host 127.0.0.1 --port 8000 --tensor-parallel-size 8 --pipeline-parallel-size 2 --enforce-eager
```


```bash
python3 openai_client.py
```

