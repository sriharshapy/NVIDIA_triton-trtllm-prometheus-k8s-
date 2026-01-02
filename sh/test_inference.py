#!/usr/bin/env python3
"""
Test script for Qwen 3 8B inference via Triton Inference Server.
"""

import requests
import json
import logging
import argparse
import time
from typing import List, Dict

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('inference_test.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def test_health(endpoint: str) -> bool:
    """Test if Triton server is healthy."""
    try:
        response = requests.get(f"{endpoint}/v2/health/ready", timeout=5)
        logger.info(f"Health check status: {response.status_code}")
        return response.status_code == 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return False


def test_model_ready(endpoint: str, model_name: str) -> bool:
    """Check if model is ready."""
    try:
        url = f"{endpoint}/v2/models/{model_name}/ready"
        response = requests.get(url, timeout=10)
        logger.info(f"Model ready check status: {response.status_code}")
        if response.status_code == 200:
            logger.info(f"Model '{model_name}' is ready")
            return True
        return False
    except Exception as e:
        logger.error(f"Model ready check failed: {e}")
        return False


def generate_text(
    endpoint: str,
    model_name: str,
    prompt: str,
    max_tokens: int = 100,
    temperature: float = 0.7,
    top_p: float = 0.9
) -> Dict:
    """Generate text using the model."""
    logger.info("=" * 80)
    logger.info("Generating text")
    logger.info("=" * 80)
    logger.info(f"Model: {model_name}")
    logger.info(f"Prompt: {prompt}")
    logger.info(f"Max tokens: {max_tokens}")
    logger.info(f"Temperature: {temperature}")
    logger.info(f"Top-p: {top_p}")
    
    url = f"{endpoint}/v2/models/{model_name}/generate"
    
    payload = {
        "text_input": prompt,
        "parameters": {
            "max_tokens": max_tokens,
            "temperature": temperature,
            "top_p": top_p,
            "stop": ["<|endoftext|>", "<|im_end|>"]
        }
    }
    
    logger.info(f"Sending request to: {url}")
    logger.info(f"Payload: {json.dumps(payload, indent=2)}")
    
    start_time = time.time()
    
    try:
        response = requests.post(
            url,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=300
        )
        
        elapsed_time = time.time() - start_time
        
        logger.info(f"Response status: {response.status_code}")
        logger.info(f"Response time: {elapsed_time:.2f} seconds")
        
        if response.status_code == 200:
            result = response.json()
            logger.info("=" * 80)
            logger.info("Generation successful!")
            logger.info("=" * 80)
            logger.info(f"Generated text: {result.get('text_output', 'N/A')}")
            return result
        else:
            logger.error(f"Request failed: {response.status_code}")
            logger.error(f"Response: {response.text}")
            return {"error": response.text}
            
    except Exception as e:
        logger.error(f"Request exception: {e}")
        return {"error": str(e)}


def main():
    parser = argparse.ArgumentParser(
        description="Test Qwen 3 8B inference via Triton"
    )
    parser.add_argument(
        "--endpoint",
        type=str,
        default="http://localhost:8000",
        help="Triton server endpoint"
    )
    parser.add_argument(
        "--model",
        type=str,
        default="qwen3_8b",
        help="Model name"
    )
    parser.add_argument(
        "--prompt",
        type=str,
        default="Hello, how are you?",
        help="Input prompt"
    )
    parser.add_argument(
        "--max-tokens",
        type=int,
        default=100,
        help="Maximum tokens to generate"
    )
    parser.add_argument(
        "--temperature",
        type=float,
        default=0.7,
        help="Sampling temperature"
    )
    parser.add_argument(
        "--top-p",
        type=float,
        default=0.9,
        help="Top-p sampling parameter"
    )
    
    args = parser.parse_args()
    
    logger.info("=" * 80)
    logger.info("Qwen 3 8B Inference Test")
    logger.info("=" * 80)
    
    # Health check
    logger.info("Step 1: Checking server health...")
    if not test_health(args.endpoint):
        logger.error("Server is not healthy. Exiting.")
        return
    
    # Model ready check
    logger.info(f"Step 2: Checking if model '{args.model}' is ready...")
    if not test_model_ready(args.endpoint, args.model):
        logger.error(f"Model '{args.model}' is not ready. Exiting.")
        return
    
    # Generate text
    logger.info("Step 3: Generating text...")
    result = generate_text(
        endpoint=args.endpoint,
        model_name=args.model,
        prompt=args.prompt,
        max_tokens=args.max_tokens,
        temperature=args.temperature,
        top_p=args.top_p
    )
    
    if "error" not in result:
        logger.info("=" * 80)
        logger.info("Test completed successfully!")
        logger.info("=" * 80)
    else:
        logger.error("Test failed!")
        logger.error(f"Error: {result.get('error')}")


if __name__ == "__main__":
    main()

