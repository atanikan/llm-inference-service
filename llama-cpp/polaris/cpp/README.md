# llama.cpp CPP API
The main goal of [llama.cpp](https://github.com/ggerganov/llama.cpp) and llama-cpp-python(https://github.com/abetlen/llama-cpp-python) is to enable LLM inference with minimal setup and state-of-the-art performance on a wide variety of hardware - locally and in the cloud.
* Plain C/C++ implementation without any dependencies
* CPU+GPU hybrid inference to partially accelerate models larger than the total VRAM capacity
* 1.5-bit, 2-bit, 3-bit, 4-bit, 5-bit, 6-bit, and 8-bit integer quantization for faster inference and reduced memory use


## Installation
To install llama.cpp on Polaris, run the following command:

```bash
module use /soft/modulefiles; module load conda
conda create -p /home/openinference_svc/envs/llama-cpp-cuda-env python==3.10.12 -y
conda activate /home/openinference_svc/envs/llama-cpp-cuda-env
module load cudatoolkit-standalone/12.2.2
conda install cmake -y
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
python3 -m pip install -r requirements.txt
pip install globus-compute-endpoint
pip install openai
cmake -B build -DCMAKE_CUDA_COMPILER=/soft/compilers/cudatoolkit/cuda-12.5.0/bin/nvcc -DLLAMA_CUDA=on
cmake --build build --config Release -t server
```


## Usage

### Use Globus Compute to run llamacpp remotely
Instructions in [llamacpp_inference.ipynb](llamacpp_inference.ipynb) notebook will guide you in triggering llamcpp inference runs remotely from your local machine using globus compute

### Use interactive mode on Polaris to run llama.cpp on compute node
To run llama.cpp server on Polaris, you can first setup the config file to load models similar to [here](./model.config) or directly run the model. 
To change any of the model weights or if you like llama.cpp to serve new models you can download the [gguf files](https://huggingface.co/TheBloke/CodeLlama-70B-Instruct-GPTQ) of that model from hugging face.

Subsequently start the server as follows on a compute node.

```bash
qsub -I -A datascience -q debug -l select=1 -l walltime=01:00:00 -l filesystems=home:eagle
module use /soft/modulefiles/
module load conda
conda activate /grand/datascience/atanikanti/envs/llama_cpp_python_env/
python3 -m llama_cpp.server --model /eagle/argonne_tpc/model_weights/gguf_files/llama-2-70b.Q5_M.gguf
```

> :Note: You need to replace `/eagle/argonne_tpc/model_weights/` with the path to the directory containing the model weights you have access to in the config file.

After starting the server you need to set no_proxy variables to connect to the Ollama server on a different shell or run the previous script in the background. You can do this by running the following command:

```bash
export hostname=$(hostname) && export no_proxy=$hostname && export NO_PROXY=$hostname
```

To interact with the running model you can use example scripts provided in the repository.

```bash
python3 openai_example.py 
```

Example and documentation can be found [here](https://llama-cpp-python.readthedocs.io/en/latest/server/)