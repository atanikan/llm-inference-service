from llama_cpp import Llama

llm = Llama(
      model_path="Meta-Llama-3-8B-Instruct-Q8_0.gguf",
      logits_all=True,
      #n_gpu_layers=-1, # Uncomment to use GPU acceleration
      # seed=1337, # Uncomment to set a specific seed
      # n_ctx=2048, # Uncomment to increase the context window
)
output = llm(
      "Q: Name the planets in the solar system? A: ", # Prompt # Generate up to 32 tokens, set to None to generate up to the end of the context window
      stop=["Q:", "\n"], # Stop generating just before the model would generate a new question
      echo=True, # Echo the prompt back in the output
      logprobs=True
) # Generate a completion, can also call create_completion
print(output)
