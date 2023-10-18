# vllm_service
This repository hosts the various ways to run Llama 13B and Llama 70B model using [vllm](https://vllm.readthedocs.io/en/latest/) on ALCF systems. The target ALCF systems in this example are Polaris and Thetagpu

# Table of Contents

* [Initial Setup](#initial-setup)
* [Running models as an interactive job](#running-llama-70b-and-13b-as-an-interactive-job)
* [Query the served model using jupyter, python client and curl](#querying-models-using-jupyter-or-curl)

## Initial Setup

Clone the repo, load conda, create environment and install required packages from any of the login node preferably into your project folder in /grand

```bash
git clone git@github.com:atanikan/vllm_service.git
module load conda
conda activate base
conda create -p <path_to_conda_environment> python==3.9 #change
conda activate <path_to_conda_environment> #change
pip install vllm
pip install gradio
pip install pandas 
pip install ray
```

:bulb: **Note:**  To use Llama 13B and 70B, you will have to request access at https://huggingface.co/meta-llama/. Once access is granted you will generate a token [here](https://huggingface.co/settings/tokens). Pass this token by `huggingface-cli login`. Alternatively you can simply use the `facebook/opt-125m model` which is served by default by vllm.

## Running Llama 70B and 13B as an interactive job

### Thetagpu

Login to `theta` and ssh to thetagpusn1 `ssh thetagpusn1` to submit an interactive job using `qsub -I -A <projectname> -n 1 -t 60 -q full-node --attrs filesystems=home,grand,eagle:pubnet=true` and run the vllm api server as shown below on a compute node. Alternatively use `qsub-gpu`.

```bash
qsub -I -A <projectname> -n 1 -t 60 -q full-node --attrs filesystems=home,grand,eagle:pubnet=true
module load conda
conda activate <path_to_conda_environment> #change path
CUDA_VISIBLE_DEVICES=0,1,2,3 python3 -m vllm.entrypoints.api_server --model meta-llama/Llama-2-70b-chat-hf --tokenizer=hf-internal-testing/llama-tokenizer --download-dir=$PWD --host 0.0.0.0 --tensor-parallel-size 4 # for the default facebook/opt-125m model just run python -m vllm.entrypoints.api_server
```

:bulb: **Note:** Change the `meta-llama/Llama-2-70b-chat-hf` to `meta-llama/Llama-2-13b-chat-hf` for 13b.

### Polaris

Submit interactive job using `qsub -I -A <project> -q debug -l select=1 -l walltime=01:00:00 -l filesystems=home:grand` and run the vllm api server as shown below on a compute node.

```bash
qsub -I -A <project> -q debug -l select=1 -l walltime=01:00:00 -l filesystems=home:grand
module load conda
conda activate <path_to_conda_environment> #change path
CUDA_VISIBLE_DEVICES=0,1,2,3 python3 -m vllm.entrypoints.api_server --model meta-llama/Llama-2-70b-chat-hf --tokenizer=hf-internal-testing/llama-tokenizer --download-dir=$PWD --host 0.0.0.0 --tensor-parallel-size 4 # for the default facebook/opt-125m model just run python -m vllm.entrypoints.api_server
```

:bulb: **Note:** Change the `meta-llama/Llama-2-70b-hf` to `meta-llama/Llama-2-13b-hf` for 70b.

## Querying models using jupyter or curl

### Thetagpu

#### JupyterHub

After [running the model](#running-llama-70b-and-13b-as-an-interactive-job), from a thetagpu **compute node** head to https://jupyter.alcf.anl.gov/ and from a login node you can use the [vllm_example_client.ipynb](thetagpu/vllm_example_client.ipynb) to run a gradio webserver pointing to the Llama 70B on thetagpu. Ensure your kernel is pointing to the same conda environment you created earlier or just install `pandas` and `gradio`. You can change/install kernel by following the [ALCF Jupyter hub docs] (https://docs.alcf.anl.gov/services/jupyter-hub/)


#### Using curl or vllm_client python script
After [running the model](#running-llama-70b-and-13b-as-an-interactive-job), from a thetagpu **compute node** run [curl.sh](thetagpu/curl.sh) or [vllm_client.py](thetagpu/vllm_client.py)

:bulb: **Note:** This repository should be cloned and run from the same path as where the file is located in order for the scripts to pick the dependencies.

### Polaris

#### Jupyterhub 

After [running the model](#running-llama-70b-and-13b-as-an-interactive-job) on Polaris, you can use the gradio interface from your local browser to interact with the running model.

To achieve this, just copy the [local_tunnel.sh](polaris/local_tunnel.sh) to your local machine and point to the conda environment & directory in polaris where you cloned this repository along with username and remote host `bash local_tunnel.sh <username> <polaris.alcf.anl.gov> <path_to_conda_env> <path_to cloned_repo>` for e.g. 

```bash
bash local_tunnel.sh atanikanti polaris-login-01.alcf.anl.gov /grand/datascience/atanikanti/envs/vllm_conda_env /grand/datascience/atanikanti/vllm_service
```

#### Using curl or vllm_client python script
After [running the model](#running-llama-70b-and-13b-as-an-interactive-job) on Polaris, run the [tunnel.sh](polaris/tunnel.sh) to establish a ssh tunnel to the remote node followed by running the [vllm_client.py](polaris/vllm_client.py) to query the running model or [curl.sh](polaris/curl.sh).

```bash
bash tunnel.sh
python3 vllm_client.py # or use curl see `curl.sh`
```

:bulb: **Note:** You can run `python3 vllm_client.py -h` to view all available options

:bulb: **Note:** Ensure you `chmod +x` all the bash scripts. 

