# vllm_service
This repository hosts the various ways to run Llama 13B and Llama 70B model using [vllm](https://vllm.readthedocs.io/en/latest/) on ALCF systems. The target ALCF system in this example is Polaris. 

# Table of Contents

* [Initial Setup](#initial-setup)
* [Running models as an interactive job](#running-llama-13b-and-70b-as-an-interactive-job)
* [Query the served model using python client and curl](#querying-models-from-login-node-using-client-api-or-curl)
* [Query the served model using gradio from browser](#querying-models-from-browser-using-gradio-and-ssh-tunnels)

## Initial Setup

Clone the repo, load conda, create environment and install required packages from the Polaris login node

```bash
git clone git@github.com:atanikan/vllm_service.git
module load conda
conda activate base
conda create -p <path_to_conda_environment> python==3.9 #change
conda activate <path_to_conda_environment> #change
pip install vllm
pip install gradio
pip install globus-compute-endpoint 
```

:bulb: **Note:**  To use Llama 13B and 70B, you will have to request access at https://huggingface.co/meta-llama/Llama-2-13b-hf. Once access is granted you will generate a token [here](https://huggingface.co/settings/tokens). Pass this token either by `huggingface-cli login` or `token=<your_token>`. Alternatively you can simply use the `facebook/opt-125m model` which is served by default by vllm.

## Running Llama 13B and 70B as an interactive job

Submit interactive job using `qsub -I -A <project> -q debug -l select=2 -l walltime=01:00:00 -l filesystems=home:grand` and run the vllm api server as shown below on a compute node.

```bash
qsub -I -A <project> -q debug -l select=2 -l walltime=01:00:00 -l filesystems=home:grand
module load conda
conda activate <path_to_conda_environment> #change path
python -m vllm.entrypoints.api_server --model meta-llama/Llama-2-13b-hf --download-dir <save model path> # for the default facebook/opt-125m model just run python -m vllm.entrypoints.api_server
```

:bulb: **Note:** Change the `meta-llama/Llama-2-13b-hf` to `meta-llama/Llama-2-70b-hf` for 70b.

## Querying models from login node using client api or curl

After [running the model](#running-llama-13b-and-70b-as-an-interactive-job), from a polaris **login node** run the [tunnel.sh](vllm_serve/tunnel.sh) to establish a ssh tunnel to the remote node followed by running the [vllm_client.py](vllm_serve/vllm_client.py) to query the running model.

```bash
cd vllm_serve
bash tunnel.sh
python3 vllm_client.py # or use curl see `curl.sh`
```

:bulb: **Note:** You can run `python3 vllm_client.py -h` to view all available options

## Querying models from browser using gradio and ssh tunnels

After [running the model](#running-llama-13b-and-70b-as-an-interactive-job), you can use the gradio interface from your local browser to interact with the running model.To achieve this, just copy the [local_tunnel.sh](vllm_serve/local_tunnel.sh) to your local machine and point to the conda environment & directory in polaris where you cloned this repository along with username and remote host `bash local_tunnel.sh <username> <polaris.alcf.anl.gov> <path_to_conda_env> <path_to cloned_repo>` for e.g. `bash local_tunnel.sh atanikanti polaris-login-01.alcf.anl.gov /grand/datascience/atanikanti/envs/vllm_conda_env /grand/datascience/atanikanti/vllm_service`

:bulb: **Note:** Ensure you `chmod +x` all the bash scripts. 

