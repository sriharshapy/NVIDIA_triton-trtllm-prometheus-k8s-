FROM nvcr.io/nvidia/tritonserver:24.12-trtllm-python-py3

# Set working directory
WORKDIR /opt/tritonserver

# Create model directories
RUN mkdir -p /models/qwen3_8b_trtllm /models/qwen3_8b /opt/triton/logs

# Copy model repository configuration
COPY model_repository /models/

# Copy startup script
COPY triton_server.sh /opt/triton/

# Set permissions
RUN chmod +x /opt/triton/triton_server.sh

# Expose ports
EXPOSE 8000 8001 8002

# Default command
CMD ["/opt/triton/triton_server.sh"]

