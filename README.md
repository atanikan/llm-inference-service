# vllm_service
This repo hosts the different ways to run Llama 13B and Llama 70B model using vllm on ANL HPC systems. The target system in this example is Polaris. 

## Setup
* Load conda, create environment and install required packages

```
module load conda
conda activate base
conda create -p <path_to_create_environment> python==3.9
conda activate </lus/grand/projects/datascience/atanikanti/envs/vllm_conda_env> #change
pip install vllm
pip install gradio
pip install globus-compute-endpoint 
```

* To use Llama 13B and 70B, make sure to request access at https://huggingface.co/meta-llama/Llama-2-13b-hf and pass a token having permission to this repo either by logging in with `huggingface-cli login` or by passing `token=<your_token>`. Alternatively you can use the default facebook/opt-125m model.

## Running Llama 13B and 70B using vllm serve in interactive mode

* Submit interactive job on Polaris Login node and run the following. Change the `meta-llama/Llama-2-13b-hf` to `meta-llama/Llama-2-70b-hf` for 70b.

```
qsub -I -A <project> -q debug -l select=2 -l walltime=01:00:00 -l filesystems=home:grand
module load conda
conda activate /grand/datascience/atanikanti/envs/vllm_conda_env/
python -m vllm.entrypoints.api_server --model meta-llama/Llama-2-13b-hf --download-dir <save model path> # or the default python -m vllm.entrypoints.api_server
```

## Interacting with the served model from login node and local computer

* Now from a login node, clone this repository and run the [tunnel.sh](vllm_serve/tunnel.sh) to establish tunnel to the remote node followed by running the [vllm_client.py](vllm_serve/vllm_client.py) to query the running model. You can run `python3 vllm_client.py -h` to view available options

```
git clone git@github.com:atanikan/vllm_service.git
cd vllm_serve
bash tunnel.sh
python3 vllm_client.py # or to use curl `bash curl.sh`
```

* You can use gradio interface from your local machine to interact with the running model

