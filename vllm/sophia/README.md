# vLLM
[vLLM](https://vllm.readthedocs.io/en/latest/) is a fast and easy-to-use library for LLM inference and serving.
vLLM is fast with:
* State-of-the-art serving throughput
* Efficient management of attention key and value memory with PagedAttention
* Continuous batching of incoming requests
This README provides instructions on how to install and use vLLM version `0.7.2` on Sophia.


# Prerequisites

Clone this repository on a sophia login node:
```bash
git clone git@github.com:atanikan/llm-inference-service.git
cd llm-inference-service/vllm/sophia
```


## Installation

Submit the job using:
```bash
qsub install_vllm.pbs
```

## Usage

To run on a single sophia node,

```bash
qsub run_vllm.pbs
```


## Notes

* The `run_vllm.pbs` script will run the vLLM server on a single node with 4 GPUs.
* The `vllm_budget_forcing.py` script will run the vLLM server with budget forcing on a single node with 4 GPUs.
* Add your HF token to the `setup_environment.sh` script.
* Add your project name/allocation to the `install_vllm.pbs` and `run_vllm.pbs` scripts.




