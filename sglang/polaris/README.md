# SGLang
SGLang is a fast serving framework for large language models and vision language models. It makes your interaction with models faster and more controllable by co-designing the backend runtime and frontend language. The core features include:

Fast Backend Runtime: Provides efficient serving with RadixAttention for prefix caching, jump-forward constrained decoding, overhead-free CPU scheduler, continuous batching, token attention (paged attention), tensor parallelism, FlashInfer kernels, chunked prefill, and quantization (FP8/INT4/AWQ/GPTQ).

Flexible Frontend Language: Offers an intuitive interface for programming LLM applications, including chained generation calls, advanced prompting, control flow, multi-modal inputs, parallelism, and external interactions.

These instructions install version sglang-0.4.3.post2

# Prerequisites

Clone this repository on a sophia login node:
```bash
git clone git@github.com:atanikan/llm-inference-service.git
cd llm-inference-service/sglang/polaris
```


## Installation

Submit the job using:
```bash
qsub install_sglang.pbs
```

## Usage

To run on a single polaris node,

```bash
qsub run_sglang.pbs
```




