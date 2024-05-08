from vllm import LLM, SamplingParams
from argparse import ArgumentParser
import time
from typing import List, Tuple
from huggingface_hub import login
login("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")


def measure_performance_and_generate_outputs(
    max_tokens: int,
    temperature: float,
    model_name: str,
    tokenizer: str,
    prompt: str,
    tensor_parallel_size: int
) -> dict:
    """
    Function to measure performance and generate outputs based on the parsed arguments.

    Argument
    --------
        max_tokens (int): Maximum number of tokens to generate
        temperature (float): Sampling temperature
        model_name (str): Name of the model
        tokenizer (str): Name of the tokenizer
        prompt (str): Prompt to generate
        tensor_parallel_size (int): Size of the tensor parallel
    """
    start_time = time.time()
    params: SamplingParams = SamplingParams(max_tokens=max_tokens, temperature=temperature)
    lm: LLM = LLM(
        model=model_name, tokenizer=tokenizer, tensor_parallel_size=tensor_parallel_size
    )
    outputs = lm.generate([prompt], params)

    output = outputs[0]
    generated_text = output.outputs[0].text
    output_token_ids = output.outputs[0].token_ids

    latency = time.time() - start_time
    tokens_per_second = len(output_token_ids) / latency

    stats = {
        # "first_token_time": first_token_time,
        "latency": f"{latency:.2f} sec",
        "tokens_per_second": f"{tokens_per_second:.2f} sec",
        "num_tokens": len(output_token_ids),
        "prompt": prompt,
        "generated_text": generated_text,
    }
    return stats




def main():
    """
    Set up argument parser and measure performance and generate outputs based on the parsed arguments.
    """
    start_time = time.time()
    parser = ArgumentParser()
    parser.add_argument("--model_name", type=str, default="meta-llama/Llama-2-70b-chat-hf")
    parser.add_argument("--tokenizer", type=str, default="hf-internal-testing/llama-tokenizer")
    parser.add_argument("--tensor_parallel_size", type=int, default=4)
    parser.add_argument("--prompt", type=str, default="The president of the United States is")
    parser.add_argument("--temperature", type=float, default=0.8)
    parser.add_argument("--max_tokens", type=int, default=1024)

    args = parser.parse_args()

    stats = measure_performance_and_generate_outputs(args.max_tokens, args.temperature, args.model_name, args.tokenizer, args.prompt, args.tensor_parallel_size)

    print(f"Stats: {stats}")
    print(f"Total time taken for generation: {time.time() - start_time:.2f} seconds")
    return stats

if __name__=="__main__":
    main()
