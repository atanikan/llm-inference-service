from vllm import LLM, SamplingParams

# Replace with your model path or Hugging Face model name
model_name = "google/gemma-3-27b-it"  # or 

# Initialize the model with the same options used in the CLI
llm = LLM(
    model=model_name,
    tensor_parallel_size=8,
    gpu_memory_utilization=0.95,
    trust_remote_code=True,
    enable_chunked_prefill=True
)

# Define sampling parameters (adjust as needed)
sampling_params = SamplingParams(
    temperature=0.7,
    top_p=0.9,
    max_tokens=512
)

# Run inference
prompt = "Explain the theory of relativity in simple terms."
outputs = llm.generate(prompt, sampling_params)

# Print output(s)
for output in outputs:
    print(output.outputs[0].text)
