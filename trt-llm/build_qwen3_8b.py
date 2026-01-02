#!/usr/bin/env python3
"""
Build Qwen 3 8B model with TRT-LLM using mixed precision (bf16/fp8).
This script converts the Qwen 3 8B model to TensorRT-LLM format.
"""

import os
import sys
import logging
import argparse
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('trt_llm_build.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


def build_qwen3_8b(
    model_path: str,
    output_dir: str,
    dtype: str = "bfloat16",
    use_fp8: bool = True,
    max_batch_size: int = 8,
    max_input_len: int = 2048,
    max_output_len: int = 2048
):
    """
    Build Qwen 3 8B model with TRT-LLM.
    
    Args:
        model_path: Path to the Qwen 3 8B model (HuggingFace format)
        output_dir: Output directory for the compiled model
        dtype: Base data type (bfloat16 or float16)
        use_fp8: Enable FP8 quantization for KV cache
        max_batch_size: Maximum batch size
        max_input_len: Maximum input sequence length
        max_output_len: Maximum output sequence length
    """
    logger.info("=" * 80)
    logger.info("Starting Qwen 3 8B TRT-LLM Build")
    logger.info("=" * 80)
    logger.info(f"Model path: {model_path}")
    logger.info(f"Output directory: {output_dir}")
    logger.info(f"Base dtype: {dtype}")
    logger.info(f"FP8 enabled: {use_fp8}")
    logger.info(f"Max batch size: {max_batch_size}")
    logger.info(f"Max input length: {max_input_len}")
    logger.info(f"Max output length: {max_output_len}")
    
    # Ensure output directory exists
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    logger.info(f"Created output directory: {output_path}")
    
    # Build command components
    cmd_parts = [
        "trtllm-build",
        "--checkpoint_dir", model_path,
        "--output_dir", str(output_path),
        "--gemm_plugin", dtype,
        "--gpt_attention_plugin", dtype,
        "--context_fmha", "enable",
        "--paged_kv_cache", "enable",
        "--max_batch_size", str(max_batch_size),
        "--max_input_len", str(max_input_len),
        "--max_output_len", str(max_output_len),
        "--max_beam_width", "1",
        "--builder_opt", "0",
    ]
    
    # Add FP8 quantization if enabled
    if use_fp8:
        logger.info("Enabling FP8 quantization for KV cache")
        cmd_parts.extend([
            "--enable_fp8",
            "--fp8_kv_cache",
        ])
    
    # Add model-specific parameters for Qwen
    cmd_parts.extend([
        "--remove_input_padding", "enable",
        "--enable_context_fmha_fp32_acc", "disable",
    ])
    
    # Construct final command
    cmd = " ".join(cmd_parts)
    logger.info(f"Build command: {cmd}")
    
    # Execute build
    logger.info("Executing TRT-LLM build...")
    logger.info("This may take 30-60 minutes depending on hardware...")
    
    exit_code = os.system(cmd)
    
    if exit_code != 0:
        logger.error(f"TRT-LLM build failed with exit code: {exit_code}")
        sys.exit(1)
    
    logger.info("=" * 80)
    logger.info("TRT-LLM build completed successfully!")
    logger.info(f"Model artifacts saved to: {output_path}")
    logger.info("=" * 80)
    
    # Verify output files
    expected_files = ["config.json", "engine"]
    for file in expected_files:
        file_path = output_path / file
        if file_path.exists():
            logger.info(f"✓ Found: {file_path}")
        else:
            logger.warning(f"✗ Missing: {file_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Build Qwen 3 8B model with TRT-LLM"
    )
    parser.add_argument(
        "--model_path",
        type=str,
        required=True,
        help="Path to Qwen 3 8B model (HuggingFace format)"
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        default="./qwen3_8b_trtllm",
        help="Output directory for compiled model"
    )
    parser.add_argument(
        "--dtype",
        type=str,
        default="bfloat16",
        choices=["bfloat16", "float16"],
        help="Base data type"
    )
    parser.add_argument(
        "--no-fp8",
        action="store_true",
        help="Disable FP8 quantization"
    )
    parser.add_argument(
        "--max_batch_size",
        type=int,
        default=8,
        help="Maximum batch size"
    )
    parser.add_argument(
        "--max_input_len",
        type=int,
        default=2048,
        help="Maximum input sequence length"
    )
    parser.add_argument(
        "--max_output_len",
        type=int,
        default=2048,
        help="Maximum output sequence length"
    )
    
    args = parser.parse_args()
    
    build_qwen3_8b(
        model_path=args.model_path,
        output_dir=args.output_dir,
        dtype=args.dtype,
        use_fp8=not args.no_fp8,
        max_batch_size=args.max_batch_size,
        max_input_len=args.max_input_len,
        max_output_len=args.max_output_len
    )


if __name__ == "__main__":
    main()

