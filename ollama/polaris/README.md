# Ollama
[Ollama](https://ollama.com/) is an open-source framework that lets developers run large language models (LLMs) on their local machines. Ollama is designed to be easy to use and to work with any LLM that can be run in a Docker container. [Supported models](https://ollama.com/library) include llama3, llama2, mixtral and more. We use [Apptainer](https://docs.alcf.anl.gov/polaris/data-science-workflows/containers/containers/) to run Ollama on Polaris.

## Installation
To install Ollama on Polaris, run the following command on a compute node:

```bash
qsub -I -A datascience -q debug -l select=1 -l walltime=01:00:00 -l filesystems=home:eagle -l singularity_fakeroot=true # Request an interactive session
module use /soft/spack/gcc/0.6.1/install/modulefiles/Core
module load apptainer
apptainer build --fakeroot ollama.simg ollama.def
```

The [ollama.def](./ollama.def) file should contain the following:

```bash
Bootstrap: docker
From: ollama/ollama:latest
# ollama containers https://github.com/iportilla/ollama-lab

%post
    # install miniconda
    apt-get -y update && apt-get install -y wget bzip2
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
    bash ~/miniconda.sh -b -p /opt/conda
    rm ~/miniconda.sh
    export PATH="/opt/conda/bin:$PATH"
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc
    echo "conda activate" >> ~/.bashrc

    # install pip
    apt-get install -y python3-pip

    # configure conda
    conda config --add channels conda-forge

    # install ollama
    pip3 install ollama

    # install numpy, matplotlib, pandas, rich, jupyter
    conda install -c conda-forge numpy matplotlib pandas rich jupyterlab ipykernel

%environment
    export PATH="/opt/conda/bin:$PATH"
    . /opt/conda/etc/profile.d/conda.sh
    conda activate
```


## Usage
To run Ollama server on Polaris, you can use the following command:

```bash
apptainer instance run --env OLLAMA_MODELS="/eagle/argonne_tpc/model_weights/" -B /eagle/argonne_tpc/ -B $PWD --nv ollama.simg ollama
# apptainer instance list # Get the instance ID
# apptainer instance stop ollama # Stop the instance
```
> :Note: You need to replace `/eagle/argonne_tpc/model_weights/` with the path to the directory containing the model weights you have access to.

After starting the server you need to set no_proxy variables to connect to the Ollama server on a different shell or run the previous script in the background. You can do this by running the following command:

```bash
export hostname=$(hostname) && export no_proxy=$hostname && export NO_PROXY=$hostname
```

To pull models, you can use the following command:

```bash
apptainer exec instance://ollama ollama pull llama3:70b # Pull the llama3 model with 70 billion parameters
# apptainer exec instance://ollama ollama pull mixtral:8x22b # Pull the mixtral model with 8 layers and 22 billion parameters
```

To run inference on the models, you can use the following command:

Using curl:
```bash
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "llama3:70b",
  "prompt":"Why is the sky blue?"
 }'
```

Using python:
```bash
apptainer exec instance://ollama python3 run_inference.py 
```

For full list of commands to interact with the api, you can refer to the [Ollama Github documentation](https://github.com/ollama/ollama/blob/main/docs/api.md).