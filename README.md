# vllm_service
This repository hosts the various ways to run [vllm](https://vllm.readthedocs.io/en/latest/) version `0.2.1.post1` in order to serve LLM models on ALCF systems. The target ALCF systems in this example is Polaris

You can either use globus to serve LLM models for remote inference using vLLM or directly run it on Polaris. We have defined 3 ways to serve LLM on Polaris below

# Table of Contents

* [Remote Inference using Globus](#inference-using-globus)
* [Inference using submission script](#inference-using-submission-script)
* [Inference in interactive mode](#inference-in-interactive-mode)

# Remote inference using Globus

The [vLLM_Inference.ipynb](inference_using_globus/vLLM_Inference.ipynb) has instructions to trigger vllm inference runs remotely. This notebook can be run from anywhere.  The only requirement is a local environment, such as a conda environment or python, that has python 3.10 installed along with the Globus packages `globus_compute_sdk` and `globus_cli`.  For e.g.

```bash
python3.10 -m venv vllm-globus-env
source activate vllm-globus-env/bin/activate
pip install notebook globus_compute_sdk globus_cli
python -m ipykernel install --user --name vllm-env --display-name "Python3.10-vllm-env"
jupyter notebook
```
> **__Note:__** <br>
> Change the kernel to point to the vllm env in your notebook. <br/>
> The vllm environment on Polaris should also contain the same python version 3.10. It is therefore necessary for this environment on your local machine to have a python version close to this version.

Instructions to setup the globus endpoint and environment on Polaris are mentioned in the [notebook](inference_using_globus/vLLM_Inference.ipynb)

> **__Note:__** <br>
> Multi node runs using vllm and globus for large models is work in progress

# Inference using submission script

You can use the [job_submission.sh](inference_using_submissionscript/job_submission.sh) file to submit a batch job

```bash
qsub job_submission.sh
```

Ensure you point to the [construct_ray_cluster.bash](common_scripts/construct_ray_cluster.bash) file correctly in the job submission script. Also change the conda environment accordingly.


# Inference in interactive mode
* In order to directly run vllm on compute node, first login to Polaris and clone this repository. Subsequently run the following from any of the login nodes.

```bash
git clone git@github.com:atanikan/vllm_service.git
module load conda
conda activate base
conda create -p <path_to_conda_environment> python==3.10 --y #change
conda activate <path_to_conda_environment> #change
cd inference_using_sshtunnel
pip install -r requirements.txt
```

:bulb: **Note:**  To use Llama 13B and 70B, you will have to request access at https://huggingface.co/meta-llama/. Once access is granted you will generate a token [here](https://huggingface.co/settings/tokens). Pass this token by `huggingface-cli login`. Alternatively you can simply use the `facebook/opt-125m model` which is served by default by vllm.

## Option 1: Run on a single node

* Submit interactive job using `qsub -I -A <project> -q debug -l select=1 -l walltime=01:00:00 -l filesystems=home:grand` and run the vllm api server as shown below on a compute node.

```bash
qsub -I -A <project> -q debug -l select=1 -l walltime=01:00:00 -l filesystems=home:grand
module load conda
conda activate <path_to_conda_environment> #change path
CUDA_VISIBLE_DEVICES=0,1,2,3 python3 -m vllm.entrypoints.api_server --model meta-llama/Llama-2-70b-chat-hf --tokenizer=hf-internal-testing/llama-tokenizer --download-dir=$PWD --host 0.0.0.0 --tensor-parallel-size 4 # for the default facebook/opt-125m model just run python -m vllm.entrypoints.api_server
```

## Option 2: Run across multiple nodes

* For models that are too large to fit in one node. You will need a ray cluster. You can spin up a ray cluster using the [construct_ray_cluster.bash](common_scripts/construct_ray_cluster.bash) followed by vllm entrypoint server.

```bash
qsub -I -A <project> -q debug -l select=2 -l walltime=01:00:00 -l filesystems=home:grand
module load conda
conda activate <path_to_conda_environment> #change path
source ./common_scripts/construct_ray_cluster.bash # It's important that you source the script. This will set the RAY_ADDRESS variable in your session and let the next command connect to the multi-node cluster.
python3 -m vllm.entrypoints.api_server --model meta-llama/Llama-2-70b-chat-hf --tokenizer=hf-internal-testing/llama-tokenizer --download-dir=$PWD --tensor-parallel-size 8
```

## Query the running server

* After running the model on Polaris, you can use the gradio interface from your local browser to interact with the running model. To achieve this, just copy the [local_tunnel.sh](inference_using_sshtunnel/local_tunnel.sh) to your local machine and point to the conda environment & directory in polaris where you cloned this repository along with username and remote host `bash local_tunnel.sh <username> <polaris.alcf.anl.gov> <path_to_conda_env> <path_to cloned_repo>` for e.g. 

```bash
bash local_tunnel.sh atanikanti polaris-login-01.alcf.anl.gov /grand/datascience/atanikanti/envs/vllm_conda_env /grand/datascience/atanikanti/vllm_service
```

* Alternatively you can use python [vllm client](inference_using_sshtunnel/vllm_client.py). Just run [tunnel.sh](inference_using_sshtunnel/tunnel.sh) to establish a ssh tunnel to the remote node followed by running the [vllm_client.py](inference_using_sshtunnel/vllm_client.py) to query the running model. You can alternatively use [curl.sh](inference_using_sshtunnel/curl.sh).

```bash
bash tunnel.sh
python3 vllm_client.py # or use curl see `curl.sh`
```

:bulb: **Note:** You can run `python3 vllm_client.py -h` to view all available options

:bulb: **Note:** Ensure you `chmod +x` all the bash scripts.

### Thetagpu

Login to `theta` and ssh to thetagpusn1 `ssh thetagpusn1` to submit an interactive job using `qsub -I -A <projectname> -n 1 -t 60 -q full-node --attrs filesystems=home,grand,eagle:pubnet=true` and run the vllm api server as shown below on a compute node. Alternatively use `qsub-gpu`.

```bash
qsub -I -A <projectname> -n 1 -t 60 -q full-node --attrs filesystems=home,grand,eagle:pubnet=true
module load conda
conda activate <path_to_conda_environment> #change path
CUDA_VISIBLE_DEVICES=0,1,2,3 python3 -m vllm.entrypoints.api_server --model meta-llama/Llama-2-70b-chat-hf --tokenizer=hf-internal-testing/llama-tokenizer --download-dir=$PWD --host 0.0.0.0 --tensor-parallel-size 4 # for the default facebook/opt-125m model just run python -m vllm.entrypoints.api_server
```

:bulb: **Note:** Change the `meta-llama/Llama-2-70b-chat-hf` to `meta-llama/Llama-2-13b-chat-hf` for 13b.

#### JupyterHub

After [running the model](#running-llama-70b-and-13b-as-an-interactive-job), from a thetagpu **compute node** head to https://jupyter.alcf.anl.gov/ and from a login node you can use the [vllm_example_client.ipynb](thetagpu/vllm_example_client.ipynb) to run a gradio webserver pointing to the Llama 70B on thetagpu. Ensure your kernel is pointing to the same conda environment you created earlier or just install `pandas` and `gradio`. You can change/install kernel by following the [ALCF Jupyter hub docs] (https://docs.alcf.anl.gov/services/jupyter-hub/)


#### Using curl or vllm_client python script
After [running the model](#running-llama-70b-and-13b-as-an-interactive-job), from a thetagpu **compute node** run [curl.sh](thetagpu/curl.sh) or [vllm_client.py](thetagpu/vllm_client.py)

:bulb: **Note:** This repository should be cloned and run from the same path as where the file is located in order for the scripts to pick the dependencies.



