# Microsoft Deepspeed
Microsoft intorduced MII, an open-source Python library designed by DeepSpeed to democratize powerful model inference with a focus on high-throughput, low latency, and cost-effectiveness.

MII features include blocked KV-caching, continuous batching, Dynamic SplitFuse, tensor parallelism, and high-performance CUDA kernels to support fast high throughput text-generation for LLMs such as Llama-2-70B, Mixtral (MoE) 8x7B, and Phi-2. 

## Installation
```bash
module use /soft/modulefiles; module load conda
module load cudatoolkit-standalone/12.5.0 
conda create -p /home/openinference_svc/envs/deepspeed-mii-env python==3.10.12 -y
conda install -y git cmake ninja
python3 -m pip install "pydantic==1.*" fastapi shortuuid fastchat openai globus-compute-endpoint
git clone git@github.com:microsoft/DeepSpeed-MII.git
export CC=gcc-12 CXX=g++-12
MPICC=$(which mpicc) MPICXX=$(which mpicxx) pip install -e .
pip install torch --force-reinstall #sometimes if gcc is not set properly, torch installation fails
```

## Usage
To use MII, you can do one of the following:

```bash
export HF_DATASETS_CACHE="/eagle/argonne_tpc/model_weights/"
export HF_HOME="/eagle/argonne_tpc/model_weights/"
python3 openai_client.py
```