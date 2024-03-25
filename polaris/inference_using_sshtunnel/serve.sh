#!/bin/bash
MODEL_NAME="$1"
MODEL_DIR="$2"
test -n "$MODEL_NAME"
MODEL_DIR="$MODEL_DIR/$MODEL_NAME"
test -d "$MODEL_DIR"
python -O -u -m vllm.entrypoints.api_server \
    --host=127.0.0.1 \
    --port=8000 \
    --model=$MODEL_DIR \
    --tokenizer=hf-internal-testing/llama-tokenizer
