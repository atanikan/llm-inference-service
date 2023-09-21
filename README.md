# vllm_service
This repo hosts the different ways to run Llama 13B and Llama 70B model using [vllm](https://vllm.readthedocs.io/en/latest/) on ALCF systems. The target system in this example is Polaris. 

# Table of Contents

* [Initial Setup](#initial-setup)
* [Running vllm models in interactive mode](#running-llama-13b-and-70b-using-vllm-serve-as-an-interactive-job)
* [Query the served model using client](#querying-vllm-models-from-login-node-using-client-api-and-curl)
* [Query the served model using gradio from browser](#querying-vllm-models-from-browser)

## Initial Setup

Clone the repo, load conda, create environment and install required packages
```bash
git clone git@github.com:atanikan/vllm_service.git
module load conda
conda activate base
conda create -p <path_to_create_environment> python==3.9
conda activate </lus/grand/projects/datascience/atanikanti/envs/vllm_conda_env> #change
pip install vllm
pip install gradio
pip install globus-compute-endpoint 
```

:bulb: **Note:**  To use Llama 13B and 70B, make sure to request access at https://huggingface.co/meta-llama/Llama-2-13b-hf and pass a token having permission to this repo either by logging in with `huggingface-cli login` or by passing `token=<your_token>`. Alternatively you can use the default facebook/opt-125m model.

## Running Llama 13B and 70B using vllm serve as an interactive job

Submit interactive job on Polaris Login node and run the following. 

```
qsub -I -A <project> -q debug -l select=2 -l walltime=01:00:00 -l filesystems=home:grand
module load conda
conda activate /grand/datascience/atanikanti/envs/vllm_conda_env/ #change path
python -m vllm.entrypoints.api_server --model meta-llama/Llama-2-13b-hf --download-dir <save model path> # or the default python -m vllm.entrypoints.api_server
```

:bulb: **Note:** Change the `meta-llama/Llama-2-13b-hf` to `meta-llama/Llama-2-70b-hf` for 70b.

## Querying vllm models from login node using client api or curl

After [running the model](#running-llama-13b-and-70b-using-vllm-serve-as-an-interactive-job), run the [tunnel.sh](vllm_serve/tunnel.sh) to establish a ssh tunnel to the remote node followed by running the [vllm_client.py](vllm_serve/vllm_client.py) to query the running model.

```
cd vllm_serve
bash tunnel.sh
python3 vllm_client.py # or to use curl `bash curl.sh`
```

:bulb: **Note:** You can run `python3 vllm_client.py -h` to view all available options

## Querying vllm models from browser

After [running the model](#running-llama-13b-and-70b-using-vllm-serve-as-an-interactive-job), you can alternatively use the gradio interface from your local browser to interact with the running model. Just copy the [local_tunnel.sh](vllm_serve/local_tunnel.sh) to your local machine and point to the directory in polaris where you cloned this repository along with username and remote host `bash local_tunnel.sh <username> <polaris.alcf.anl.gov> <path_to_conda_env> <path_to cloned_repo>` for e.g. `bash local_tunnel.sh atanikanti polaris-login-01.alcf.anl.gov /grand/datascience/atanikanti/envs/vllm_conda_env /grand/datascience/atanikanti/vllm_service`

:bulb: **Note:** Ensure you `chmod +x` all the bash scripts. 

